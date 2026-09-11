//
//  OriWeatherDroplet.swift
//  OriWeather
//

import Combine
import DroppyKit
import SwiftUI

/// The class Droppy's loader instantiates, named in the bundle's
/// `NSPrincipalClass`. Keep it empty: it runs before the host is ready.
@objc(OriWeatherPrincipal)
public final class OriWeatherPrincipal: NSObject, DropletPrincipal {
    public override init() { super.init() }

    @MainActor public func makeDroplet() -> AnyObject { OriWeatherDroplet() }
}

/// What the surfaces draw: one reading, for one city, and how old it is.
struct Glance: Equatable {
    let reading: WeatherReading
    let isStale: Bool
    /// The last attempt, which is what an old reading's age is measured
    /// against.
    let now: Date
    let city: City
    let unit: TemperatureUnit

    var degrees: String { reading.degrees(in: unit) }
    var feelsLike: String { reading.feelsLike(in: unit) }
    var condition: String { reading.condition }
    /// The condition, or how old the reading is once it has stopped arriving.
    var detail: String { isStale ? Ago.words(reading.at, at: now) : reading.condition }
    /// How old the reading is, said on the shelf whether or not it is stale.
    var age: String {
        let words = Ago.words(reading.at, at: now)
        return words == "now" ? "Read just now" : "Read \(words)"
    }
}

/// OriNotch's weather, on Droppy's wing when nothing else wants it.
@MainActor
public final class OriWeatherDroplet: NSObject, ObservableObject, Droplet {
    /// Must equal `DroppyDropletID` in the bundle's Info.plist and `id` in
    /// droplet.json. The loader refuses the bundle if the three disagree.
    public nonisolated static let id: DropletID = "ori-weather"

    /// The seat's priority: OriNotch's `ambient`, the lowest honest number
    /// among droplets. Against Droppy's own activities it does not matter; a
    /// droplet holds the seat only when none of them want the notch (D5).
    static let priority = 10

    /// Everything the surfaces draw, or nothing while there is no city or no
    /// reading. A wing with nothing on it is the one thing the seat rules
    /// forbid, so no glance is no state.
    @Published private(set) var glance: Glance?

    let activitySubject = CurrentValueSubject<LiveActivityState?, Never>(nil)

    /// The room's city search, alive while the droplet is.
    @Published private(set) var search: CitySearch?

    private var host: DropletHost?
    private(set) var model: WeatherModel?
    private(set) var seat: DropletLiveActivitySeat = .none(.idle)
    /// Whether the widget is on a shelf, which keeps the clock running whether
    /// or not the activity is seated.
    private(set) var isShelved = false
    /// Whether the pin is on when nobody has said: off, except under the demo
    /// sky.
    private var pinnedByDefault = false
    private var subscriptions: Set<AnyCancellable> = []
    private let fetcherOverride: (any WeatherFetching)?
    private let geocoderOverride: (any Geocoding)?
    private var geocoder: (any Geocoding)?
    private var finding: Task<Void, Never>?
    /// This Mac's time zone, which the automatic city is found from. A
    /// closure so a test can travel.
    var timeZone: () -> String = { TimeZone.autoupdatingCurrent.identifier }

    public override init() {
        fetcherOverride = nil
        geocoderOverride = nil
        super.init()
    }

    /// For the tests: a fetcher and a geocoder that answer from memory. The
    /// geocoder knows nowhere unless a test gives it somewhere, so no test
    /// reaches the network by finding a city.
    init(fetcher: any WeatherFetching, geocoder: any Geocoding = NoGeocoder()) {
        fetcherOverride = fetcher
        geocoderOverride = geocoder
        super.init()
    }

    private var preferences: Preferences? { host.map { Preferences(service: $0.preferences) } }

    // MARK: Lifecycle

    public func activate(host: DropletHost) throws {
        self.host = host
        let preferences = Preferences(service: host.preferences)
        let demo = Demo.mode(isHarness: host.environment.isHarness)
        pinnedByDefault = demo != nil
        let model = WeatherModel(fetcher: fetcher(for: host, demo: demo),
                                 city: preferences.city ?? (demo == nil ? nil : Demo.city),
                                 every: TimeInterval(preferences.intervalMinutes * 60))
        if demo == .stale { model.every = 2 }
        let log = host.log
        model.log = { log.info($0) }
        self.model = model
        let geocoder = geocoder(for: host, demo: demo)
        self.geocoder = geocoder
        search = CitySearch(geocoder: geocoder, log: { log.info($0) })

        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.redraw() }
            .store(in: &subscriptions)
        host.preferences.didChange
            .sink { [weak self] key in self?.preferenceChanged(key) }
            .store(in: &subscriptions)
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.findCity(force: false) }
            .store(in: &subscriptions)
        host.installState.statePublisher
            .map { $0.activeWidgetIDs.contains(Self.widgetID) }
            .removeDuplicates()
            .sink { [weak self] shelved in self?.shelfChanged(shelved) }
            .store(in: &subscriptions)

        host.log.info("Ori Weather activated\(demo.map { " with the \($0) demo sky" } ?? "")")
        if host.isGranted(.globalShortcuts) {
            host.shortcuts.register(id: WingShortcut.id, title: WingShortcut.title,
                                    defaultShortcut: WingShortcut.suggestion) { [weak self] in
                self?.pinned.toggle()
            }
        }

        // One reading to have something to publish: the host seats nothing
        // until there is a state, and the clock runs only while seated.
        model.refresh(because: .launch)
        findCity(force: false)
    }

    public func deactivate() {
        // Everything activate() started is torn down here. Swift cannot unload
        // code, so anything left running keeps running until Droppy relaunches.
        model?.stop()
        model?.log = nil
        model = nil
        search?.cancel()
        search = nil
        finding?.cancel()
        finding = nil
        geocoder = nil
        if host?.isGranted(.globalShortcuts) == true {
            host?.shortcuts.unregister(id: WingShortcut.id)
        }
        subscriptions.removeAll()
        glance = nil
        activitySubject.send(nil)
        seat = .none(.idle)
        isShelved = false
        host = nil
    }

    private func fetcher(for host: DropletHost, demo: Demo.Mode?) -> any WeatherFetching {
        if let fetcherOverride { return fetcherOverride }
        if let demo { return DemoWeather(mode: demo) }
        guard host.isGranted(.networkClient) else {
            host.log.notice("network-client is not granted, so no weather is read")
            return Refused()
        }
        return OpenMeteo()
    }

    private func geocoder(for host: DropletHost, demo: Demo.Mode?) -> any Geocoding {
        if let geocoderOverride { return geocoderOverride }
        if demo != nil { return DemoGeocoder() }
        guard host.isGranted(.networkClient) else { return NoGeocoder() }
        return OpenMeteoGeocoder()
    }

    // MARK: The room's bindings

    /// The city the user chose, as stored; the demo sky's city is not one.
    var chosenCity: City? { preferences?.city }

    /// A city the user named, which ends finding one automatically.
    func choose(_ city: City) {
        preferences?.automatic = false
        preferences?.city = city
        search?.reset()
    }

    /// Turned on in the room, it finds the zone's city at once, over whatever
    /// was chosen.
    var automatic: Bool {
        get { preferences?.automatic ?? false }
        set {
            preferences?.automatic = newValue
            if newValue { findCity(force: true) }
        }
    }

    /// Whether the user granted the shortcut its capability; without it the
    /// room does not offer a shortcut it cannot honour.
    var canUseShortcut: Bool { host?.isGranted(.globalShortcuts) ?? false }

    /// The shortcut as the host has it bound, or nil when it is not.
    var shortcut: DropletKeyboardShortcut? {
        guard let host, host.isGranted(.globalShortcuts) else { return nil }
        return host.shortcuts.currentShortcut(id: WingShortcut.id)
    }

    /// Finds the city from the time zone, when the city is automatic: at
    /// activation and when the zone changes only if the stored city is not
    /// already in it, and at once when the user turns it on.
    func findCity(force: Bool) {
        guard let preferences, preferences.automatic, let geocoder else { return }
        let zone = timeZone()
        if !force, preferences.city?.timeZone == zone { return }
        guard let name = ZoneCity.name(of: zone) else {
            host?.log.notice("the time zone \(zone) names no city, so none was found")
            return
        }
        finding?.cancel()
        finding = Task { [weak self] in
            let found = (try? await geocoder.cities(named: name)) ?? []
            guard !Task.isCancelled, let self, let preferences = self.preferences,
                  preferences.automatic else { return }
            guard let city = ZoneCity.pick(found, in: zone) else {
                self.host?.log.notice("the geocoder knows no \(name), so no city was found")
                return
            }
            self.host?.log.info("found \(city.name) from the time zone \(zone)")
            // Written down, so the city stored next is known to be found and
            // not chosen.
            preferences.automatic = true
            preferences.city = city
        }
    }

    var unit: TemperatureUnit {
        get { preferences?.unit ?? .celsius }
        set { preferences?.unit = newValue }
    }

    var intervalMinutes: Int {
        get { preferences?.intervalMinutes ?? 30 }
        set { preferences?.intervalMinutes = newValue }
    }

    var pinned: Bool {
        get { preferences?.pinned(byDefault: pinnedByDefault) ?? false }
        set { preferences?.setPinned(newValue) }
    }

    // MARK: Changes

    private func preferenceChanged(_ key: String) {
        guard let model, let preferences else { return }
        switch key {
        case Preferences.Key.city:
            let city = preferences.city
            model.city = city
            if city == nil {
                // Nothing left to say, so the seat is given up now rather than
                // when the publisher catches up.
                host?.liveActivity.yield(reason: .idle)
            } else if !model.isRunning {
                model.refresh(because: .city)
            }
        case Preferences.Key.intervalMinutes:
            model.every = TimeInterval(preferences.intervalMinutes * 60)
        case Preferences.Key.pinned where !pinned:
            // Unpinned, the wing is given back now rather than when the
            // publisher's nil reaches the host.
            host?.liveActivity.yield(reason: .idle)
        default:
            break
        }
        objectWillChange.send()
        redraw()
    }

    /// The glance and the state, from the model and the preferences. The
    /// model's `objectWillChange` fires before its values move, so this runs
    /// on the next turn of the run loop, after they have.
    private func redraw() {
        guard let model, let city = model.city, let reading = model.reading else {
            if glance != nil { glance = nil }
            publish()
            return
        }
        let next = Glance(reading: reading, isStale: model.isStale, now: model.now, city: city,
                          unit: preferences?.unit ?? .celsius)
        if next != glance { glance = next }
        publish()
    }

    /// The wing is asked for only while the pin is on. The SDK's
    /// `joinsPersistentActivitySet` says the same thing to the host, but
    /// Droppy 15.3 (as the Playground stands in for it) seats a droplet's
    /// activity at rest whether or not it joins, so the droplet keeps its own
    /// pin: off, it publishes nothing and the weather lives on the shelf.
    private func publish() {
        guard let glance, pinned else {
            if activitySubject.value != nil { activitySubject.send(nil) }
            return
        }
        let state = LiveActivityState(
            priority: Self.priority,
            accessibilityTitle: "\(glance.degrees.dropLast()) degrees, \(glance.condition.lowercased()), \(glance.city.name)",
            isInteractive: false,
            joinsPersistentActivitySet: true,
            compactPresentation: nil,
            expandedWidgetID: "weather"
        )
        // The host diffs before it redraws, and so does this: a state equal
        // to the last one is not news.
        if activitySubject.value != state { activitySubject.send(state) }
    }

    /// The clock runs while somebody can see the weather: the activity is
    /// seated, or the widget is on a shelf. The two are or-ed here and nowhere
    /// else. Neither, no timer and no request, and the last reading stays.
    private func updateClock(because reason: WeatherModel.Reason) {
        guard let model else { return }
        if seat.isPresented || isShelved {
            model.start(because: reason)
        } else {
            model.stop()
        }
    }

    private func shelfChanged(_ shelved: Bool) {
        guard shelved != isShelved else { return }
        isShelved = shelved
        host?.log.info(shelved ? "on a shelf" : "off every shelf")
        updateClock(because: .shelf)
    }

    func seatChanged(_ seat: DropletLiveActivitySeat) {
        self.seat = seat
        host?.log.info("seat is now \(seat)")
        updateClock(because: .seat)
    }
}

/// What finds a city when `network-client` was not granted: nobody.
struct NoGeocoder: Geocoding {
    func cities(named name: String) async throws -> [City] { [] }
}

/// What reads the weather when `network-client` was not granted: nothing,
/// said out loud rather than attempted.
private struct Refused: WeatherFetching {
    func read(at place: Place) async throws -> WeatherReading {
        throw WeatherError.refused
    }
}

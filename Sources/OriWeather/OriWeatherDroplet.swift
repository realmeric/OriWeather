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

    var degrees: String { reading.degrees }
    var feelsLike: String { "\(Int(reading.feelsLike.rounded()))°" }
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

    private var host: DropletHost?
    private(set) var model: WeatherModel?
    private(set) var seat: DropletLiveActivitySeat = .none(.idle)
    /// Whether the widget is on a shelf, which keeps the clock running whether
    /// or not the activity is seated.
    private(set) var isShelved = false
    private var subscriptions: Set<AnyCancellable> = []
    private let fetcherOverride: (any WeatherFetching)?

    public override init() {
        fetcherOverride = nil
        super.init()
    }

    /// For the tests: a fetcher that answers from memory.
    init(fetcher: any WeatherFetching) {
        fetcherOverride = fetcher
        super.init()
    }

    private var preferences: Preferences? { host.map { Preferences(service: $0.preferences) } }

    // MARK: Lifecycle

    public func activate(host: DropletHost) throws {
        self.host = host
        let preferences = Preferences(service: host.preferences)
        let demo = Demo.mode(isHarness: host.environment.isHarness)
        let model = WeatherModel(fetcher: fetcher(for: host, demo: demo),
                                 city: preferences.city ?? (demo == nil ? nil : Demo.city),
                                 every: TimeInterval(preferences.intervalMinutes * 60))
        if demo == .stale { model.every = 2 }
        let log = host.log
        model.log = { log.info($0) }
        self.model = model

        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.redraw() }
            .store(in: &subscriptions)
        host.preferences.didChange
            .sink { [weak self] key in self?.preferenceChanged(key) }
            .store(in: &subscriptions)
        host.installState.statePublisher
            .map { $0.activeWidgetIDs.contains(Self.widgetID) }
            .removeDuplicates()
            .sink { [weak self] shelved in self?.shelfChanged(shelved) }
            .store(in: &subscriptions)

        host.log.info("Ori Weather activated\(demo.map { " with the \($0) demo sky" } ?? "")")
        // One reading to have something to publish: the host seats nothing
        // until there is a state, and the clock runs only while seated.
        model.refresh(because: .launch)
    }

    public func deactivate() {
        // Everything activate() started is torn down here. Swift cannot unload
        // code, so anything left running keeps running until Droppy relaunches.
        model?.stop()
        model?.log = nil
        model = nil
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
        default:
            break
        }
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
        let next = Glance(reading: reading, isStale: model.isStale, now: model.now, city: city)
        if next != glance { glance = next }
        publish()
    }

    private func publish() {
        guard let glance else {
            if activitySubject.value != nil { activitySubject.send(nil) }
            return
        }
        let state = LiveActivityState(
            priority: Self.priority,
            accessibilityTitle: "\(glance.degrees.dropLast()) degrees, \(glance.condition.lowercased()), \(glance.city.name)",
            isInteractive: false,
            joinsPersistentActivitySet: preferences?.pinned ?? false,
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

/// What reads the weather when `network-client` was not granted: nothing,
/// said out loud rather than attempted.
private struct Refused: WeatherFetching {
    func read(at place: Place) async throws -> WeatherReading {
        throw WeatherError.refused
    }
}

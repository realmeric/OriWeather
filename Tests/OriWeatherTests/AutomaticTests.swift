import DroppyKit
import XCTest
@testable import OriWeather

@MainActor
final class AutomaticTests: XCTestCase {
    private let paris = City(name: "Paris", region: "Île-de-France", country: "France",
                             place: Place(latitude: 48.85, longitude: 2.35), timeZone: "Europe/Paris")
    private let texas = City(name: "Paris", region: "Texas", country: "United States",
                             place: Place(latitude: 33.66, longitude: -95.56), timeZone: "America/Chicago")

    func testAZoneIsNamedAfterACity() {
        XCTAssertEqual(ZoneCity.name(of: "Europe/Istanbul"), "Istanbul")
        XCTAssertEqual(ZoneCity.name(of: "America/Argentina/Buenos_Aires"), "Buenos Aires")
        XCTAssertNil(ZoneCity.name(of: "UTC"))
        XCTAssertNil(ZoneCity.name(of: "Etc/GMT+3"))
    }

    /// Paris is the one in Europe/Paris, not the one in Texas.
    func testTheMatchInTheZoneWins() {
        XCTAssertEqual(ZoneCity.pick([texas, paris], in: "Europe/Paris"), paris)
        XCTAssertEqual(ZoneCity.pick([texas], in: "Europe/Paris"), texas)
        XCTAssertNil(ZoneCity.pick([], in: "Europe/Paris"))
    }

    /// Nobody has named a city, so it is found from the time zone, and the
    /// weather is read for it.
    func testWithNoCityTheTimeZoneFindsOne() async throws {
        let fetcher = FakeWeather(reading: Sky.reading())
        let droplet = OriWeatherDroplet(fetcher: fetcher, geocoder: FakeGeocoder(answer: [texas, paris]))
        droplet.timeZone = { "Europe/Paris" }
        let test = TestHost(city: nil)
        try droplet.activate(host: test.host)
        await settle()
        XCTAssertTrue(droplet.automatic)
        XCTAssertEqual(droplet.chosenCity, paris)
        XCTAssertEqual(droplet.glance?.city, paris)
        let read = await fetcher.counter.count
        XCTAssertEqual(read, 1)
        droplet.deactivate()
    }

    /// A city somebody chose is never overridden by a time zone.
    func testAChosenCityIsNotFoundAutomatically() async throws {
        let geocoder = FakeGeocoder(answer: [paris])
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()), geocoder: geocoder)
        droplet.timeZone = { "Europe/Paris" }
        try droplet.activate(host: TestHost(city: Sky.istanbul).host)
        await settle()
        XCTAssertFalse(droplet.automatic)
        XCTAssertEqual(droplet.chosenCity, Sky.istanbul)
        droplet.findCity(force: false)
        await settle()
        let asked = await geocoder.counter.count
        XCTAssertEqual(asked, 0)
        droplet.deactivate()
    }

    /// Travelling to another zone finds its city; staying in one asks nothing.
    func testTravellingFindsTheNewZonesCity() async throws {
        let geocoder = AtlasGeocoder(atlas: ["Istanbul": [Sky.istanbul], "Paris": [texas, paris]])
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()), geocoder: geocoder)
        droplet.timeZone = { "Europe/Istanbul" }
        try droplet.activate(host: TestHost(city: nil).host)
        await settle()
        XCTAssertEqual(droplet.chosenCity, Sky.istanbul)

        droplet.findCity(force: false)
        await settle()
        var asked = await geocoder.counter.count
        XCTAssertEqual(asked, 1, "still in Istanbul's zone, so nothing is asked")

        droplet.timeZone = { "Europe/Paris" }
        droplet.findCity(force: false)
        await settle()
        asked = await geocoder.counter.count
        XCTAssertEqual(asked, 2)
        XCTAssertEqual(droplet.chosenCity, paris)
        XCTAssertEqual(droplet.glance?.city, paris)
        droplet.deactivate()
    }

    /// Turning it back on finds the zone's city over the chosen one.
    func testTurningItOnFindsTheCityAtOnce() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()),
                                        geocoder: FakeGeocoder(answer: [paris]))
        droplet.timeZone = { "Europe/Paris" }
        try droplet.activate(host: TestHost(city: Sky.istanbul).host)
        await settle()
        droplet.automatic = true
        await settle()
        XCTAssertEqual(droplet.chosenCity, paris)
        droplet.deactivate()
    }
}

@MainActor
final class ShortcutTests: XCTestCase {
    func testTheSuggestionReadsTheWayMacOSWritesIt() {
        XCTAssertEqual(WingShortcut.words(WingShortcut.suggestion), "⌃⌥W")
        XCTAssertEqual(WingShortcut.words(DropletKeyboardShortcut(keyCode: 1, modifiers: 1 << 8 | 1 << 9)), "⇧⌘S")
    }

    /// Registered at activation, pressing it flips the wings, and deactivate
    /// takes it away.
    func testTheShortcutPutsTheWeatherOnTheWingsAndTakesItOff() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        let test = TestHost(pinned: nil, granted: [.networkClient, .globalShortcuts])
        try droplet.activate(host: test.host)
        await settle()
        let shortcut = try XCTUnwrap(test.recorder.shortcuts.first { $0.id == WingShortcut.id })
        XCTAssertEqual(shortcut.shortcut, WingShortcut.suggestion)
        XCTAssertNil(droplet.activitySubject.value)

        shortcut.handler()
        await settle()
        XCTAssertNotNil(droplet.activitySubject.value)
        shortcut.handler()
        await settle()
        XCTAssertNil(droplet.activitySubject.value)

        droplet.deactivate()
        XCTAssertTrue(test.recorder.shortcuts.isEmpty)
    }

    func testWithoutTheCapabilityNothingIsRegistered() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        let test = TestHost()
        try droplet.activate(host: test.host)
        XCTAssertTrue(test.recorder.effects.filter { $0.service == "shortcuts" }.isEmpty)
        XCTAssertFalse(droplet.canUseShortcut)
        droplet.deactivate()
    }
}

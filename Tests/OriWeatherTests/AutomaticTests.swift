import AppKit
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

    /// A new zone is news: seated, the city is found again for it.
    func testANewZoneFindsItsCity() async throws {
        let geocoder = AtlasGeocoder(atlas: ["Istanbul": [Sky.istanbul], "Paris": [texas, paris]])
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()), geocoder: geocoder)
        droplet.timeZone = { "Europe/Istanbul" }
        try droplet.activate(host: TestHost(city: nil).host)
        await settle()
        XCTAssertEqual(droplet.chosenCity, Sky.istanbul)
        droplet.liveActivitySeatDidChange(.compact)
        await settle()
        var asked = await geocoder.counter.count
        XCTAssertEqual(asked, 1, "seated a moment after the city was found, nothing more is asked")

        droplet.timeZone = { "Europe/Paris" }
        droplet.whereaboutsChanged(zoneChanged: true)
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
final class WhereaboutsTests: XCTestCase {
    private let ankara = City(name: "Ankara", region: "Ankara", country: "Türkiye",
                              place: Place(latitude: 39.92, longitude: 32.85), timeZone: "Europe/Istanbul")
    private let frankfurt = City(name: "Frankfurt am Main", region: "Hesse", country: "Germany",
                                 place: Place(latitude: 50.11, longitude: 8.68), timeZone: "Europe/Berlin")

    /// GeoJS's answer, with a documentation address in it rather than a real
    /// one: the reader keeps the town and drops the address and the network.
    func testTheAnswerKeepsTheTownAndDropsTheAddress() throws {
        let body = Data("""
            {"accuracy":10,"asn":64500,"city":"Ankara","continent_code":"AS","country":"Türkiye",
             "country_code":"TR","ip":"203.0.113.7","latitude":"39.9199","longitude":"32.8543",
             "organization":"AS64500 Example","region":"Ankara","timezone":"Europe/Istanbul"}
            """.utf8)
        let city = try GeoJS.city(from: body)
        XCTAssertEqual(city, ankara)
        XCTAssertEqual(GeoJS.url.host, "get.geojs.io")
    }

    func testAnAnswerWithNoTownIsNowhere() {
        XCTAssertThrowsError(try GeoJS.city(from: Data(#"{"ip":"203.0.113.7","country_code":"TR"}"#.utf8)))
    }

    /// Ankara is not Istanbul, though they share a zone: the address tells
    /// them apart, and the geocoder is not asked.
    func testTheAddressFindsTheCityTheZoneCannot() async throws {
        let geocoder = AtlasGeocoder(atlas: ["Istanbul": [Sky.istanbul]])
        let locator = FakeLocator(answer: ankara)
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()),
                                        geocoder: geocoder, locator: locator)
        droplet.timeZone = { "Europe/Istanbul" }
        try droplet.activate(host: TestHost(city: nil).host)
        await settle()
        XCTAssertEqual(droplet.chosenCity, ankara)
        let asked = await geocoder.counter.count
        XCTAssertEqual(asked, 0)
        droplet.deactivate()
    }

    /// A VPN in Frankfurt puts the address in another zone; the zone wins.
    func testAnAddressInAnotherZoneIsAVPNAndTheZoneWins() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()),
                                        geocoder: AtlasGeocoder(atlas: ["Istanbul": [Sky.istanbul]]),
                                        locator: FakeLocator(answer: frankfurt))
        droplet.timeZone = { "Europe/Istanbul" }
        try droplet.activate(host: TestHost(city: nil).host)
        await settle()
        XCTAssertEqual(droplet.chosenCity, Sky.istanbul)
        droplet.deactivate()
    }

    /// Unseen, a new network asks nobody; seated, it does, once in ten minutes.
    func testAMoveIsLookedUpOnlyWhileTheWeatherIsSeen() async throws {
        let locator = FakeLocator(answer: ankara)
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()),
                                        geocoder: NoGeocoder(), locator: locator)
        var now = Sky.now
        droplet.clock = { now }
        droplet.timeZone = { "Europe/Istanbul" }
        let test = TestHost(city: Sky.istanbul)
        Preferences(service: test.preferences).automatic = true
        try droplet.activate(host: test.host)
        await settle()
        var asked = await locator.counter.count
        XCTAssertEqual(asked, 0, "a city is stored and nobody can see the weather")

        droplet.whereaboutsChanged(zoneChanged: false)
        await settle()
        asked = await locator.counter.count
        XCTAssertEqual(asked, 0, "a new network, unseen, asks nobody")

        droplet.liveActivitySeatDidChange(.compact)
        await settle()
        asked = await locator.counter.count
        XCTAssertEqual(asked, 1, "seen, the stale whereabouts are looked up")
        XCTAssertEqual(droplet.chosenCity, ankara)

        now += 5 * 60
        droplet.whereaboutsChanged(zoneChanged: false)
        await settle()
        asked = await locator.counter.count
        XCTAssertEqual(asked, 1, "five minutes later a flapping network is the same place")

        now += 6 * 60
        droplet.whereaboutsChanged(zoneChanged: false)
        await settle()
        asked = await locator.counter.count
        XCTAssertEqual(asked, 2)
        droplet.deactivate()
    }

    /// The same town again writes nothing, so the weather is not read again
    /// for a place the Mac never left.
    func testTheSameTownAgainReadsNoWeather() async throws {
        let fetcher = FakeWeather(reading: Sky.reading())
        let nearby = City(name: "Ankara", region: "Ankara", country: "Türkiye",
                          place: Place(latitude: 39.93, longitude: 32.86), timeZone: "Europe/Istanbul")
        let droplet = OriWeatherDroplet(fetcher: fetcher, geocoder: NoGeocoder(),
                                        locator: FakeLocator(answer: nearby))
        droplet.timeZone = { "Europe/Istanbul" }
        let test = TestHost(city: ankara)
        Preferences(service: test.preferences).automatic = true
        try droplet.activate(host: test.host)
        droplet.liveActivitySeatDidChange(.compact)
        await settle()
        XCTAssertEqual(droplet.chosenCity, ankara, "the stored coordinate stays")
        let read = await fetcher.counter.count
        XCTAssertEqual(read, 1, "the launch read, and nothing for the same town")
        droplet.deactivate()
    }
}

@MainActor
final class ShortcutTests: XCTestCase {
    func testTheSuggestionReadsTheWayMacOSWritesIt() {
        XCTAssertEqual(WingShortcut.words(WingShortcut.suggestion), "⌃⌥⌘W")
        let shiftCommandS = DropletKeyboardShortcut(keyCode: 1, modifiers: NSEvent.ModifierFlags([.shift, .command]).rawValue)
        XCTAssertEqual(WingShortcut.words(shiftCommandS), "⇧⌘S")
    }

    /// The suggestion's modifiers are AppKit's control, option and command
    /// bits, not Carbon's, which the host read as nothing and bound a bare W.
    func testTheSuggestionCarriesAppKitsModifiers() {
        XCTAssertEqual(WingShortcut.suggestion.modifiers, NSEvent.ModifierFlags([.control, .option, .command]).rawValue)
        XCTAssertEqual(WingShortcut.suggestion.modifiers & 0xFFFF, 0, "no Carbon bits")
    }

    /// A bare W never flips the pin, whatever the host bound.
    func testOnlyAPressWithTheModifiersHeldCounts() {
        XCTAssertTrue(WingShortcut.isGenuine(WingShortcut.suggestion, held: [.control, .option, .command]))
        XCTAssertTrue(WingShortcut.isGenuine(WingShortcut.suggestion, held: [.control, .option, .command, .capsLock]))
        XCTAssertFalse(WingShortcut.isGenuine(WingShortcut.suggestion, held: [.control, .option]), "the old two are not enough")
        XCTAssertFalse(WingShortcut.isGenuine(WingShortcut.suggestion, held: []))
        XCTAssertFalse(WingShortcut.isGenuine(WingShortcut.suggestion, held: [.control]))
        let bare = DropletKeyboardShortcut(keyCode: 13, modifiers: 0)
        XCTAssertFalse(WingShortcut.isGenuine(bare, held: []))
        let carbon = DropletKeyboardShortcut(keyCode: 13, modifiers: 1 << 12 | 1 << 11)
        XCTAssertFalse(WingShortcut.isGenuine(carbon, held: []), "the mask that bit the host")
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

        // The harness calls the handler without a key, so the press is made
        // here with and without its modifiers held.
        droplet.shortcutPressed(held: [])
        await settle()
        XCTAssertNil(droplet.activitySubject.value, "a bare W flips nothing")
        droplet.shortcutPressed(held: [.control, .option, .command])
        await settle()
        XCTAssertNotNil(droplet.activitySubject.value)
        droplet.shortcutPressed(held: [.control, .option, .command])
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

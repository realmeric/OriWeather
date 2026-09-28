import DroppyKit
import XCTest
@testable import OriWeather

@MainActor
final class RoomTests: XCTestCase {
    func testTheSearchFindsThePin() {
        let titles = OriWeatherDroplet().settingsSearchEntries.map(\.title)
        XCTAssertTrue(titles.contains("Keep on the notch"))
        XCTAssertEqual(titles, ["City", "Find the city automatically", "Unit", "Refresh every",
                                "Keep on the notch", "Shortcut"])
    }

    /// A name typed in one go is one request, and choosing a match is none.
    func testOneGeocoderRequestPerPauseNonePerKeystroke() async throws {
        let geocoder = FakeGeocoder(answer: [Sky.istanbul])
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()), geocoder: geocoder)
        droplet.timeZone = { "UTC" }
        let test = TestHost(city: nil, pinned: nil)
        try droplet.activate(host: test.host)
        let search = try XCTUnwrap(droplet.search)
        for typed in ["I", "Is", "Ist", "Ista", "Istan", "Istanb", "Istanbu", "Istanbul"] {
            search.query = typed
            try await Task.sleep(for: .milliseconds(30))
        }
        try await Task.sleep(for: .milliseconds(600))
        var asked = await geocoder.counter.count
        XCTAssertEqual(asked, 1)
        XCTAssertEqual(search.matches, [Sky.istanbul])

        droplet.choose(Sky.istanbul)
        await settle()
        asked = await geocoder.counter.count
        XCTAssertEqual(asked, 1, "a match carries its coordinate")
        XCTAssertEqual(search.query, "")
        XCTAssertEqual(test.preferences.storedKeys, ["automatic", "city"],
                       "choosing a city writes the city, and that it was chosen")
        XCTAssertFalse(droplet.automatic)
        XCTAssertEqual(droplet.glance?.city, Sky.istanbul, "and the wing reads it at once")
        droplet.deactivate()
    }

    func testTheRoomWritesFiveKeysAndNothingElse() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()),
                                        geocoder: FakeGeocoder(answer: []))
        let test = TestHost(city: nil, pinned: nil)
        try droplet.activate(host: test.host)
        droplet.choose(Sky.istanbul)
        droplet.unit = .fahrenheit
        droplet.intervalMinutes = 60
        droplet.pinned = true
        await settle()
        XCTAssertEqual(test.preferences.storedKeys, ["automatic", "city", "intervalMinutes", "pinned", "unit"])
        XCTAssertEqual(test.preferences.namespacedKey("pinned"), "droplet.ori-weather.pinned")
        droplet.deactivate()
    }

    /// A name asked about with nothing back says so, whether the geocoder
    /// knew no town by it or the network did not answer; a name too short to
    /// ask about, or one that found something, does not.
    func testNothingFoundIsSaidOnlyForANameThatWasAskedAbout() {
        XCTAssertTrue(CitySection.foundNothing(query: "Xqzv", matches: []))
        XCTAssertFalse(CitySection.foundNothing(query: "X", matches: []))
        XCTAssertFalse(CitySection.foundNothing(query: "  ", matches: []))
        XCTAssertFalse(CitySection.foundNothing(query: "Istanbul", matches: [Sky.istanbul]))
    }
}

import DroppyKit
import XCTest
@testable import OriWeather

@MainActor
final class RoomTests: XCTestCase {
    func testTheSearchFindsThePin() {
        let titles = OriWeatherDroplet().settingsSearchEntries.map(\.title)
        XCTAssertTrue(titles.contains("Keep on the notch"))
        XCTAssertEqual(titles, ["City", "Unit", "Refresh every", "Keep on the notch"])
    }

    /// A name typed in one go is one request, and choosing a match is none.
    func testOneGeocoderRequestPerPauseNonePerKeystroke() async throws {
        let geocoder = FakeGeocoder(answer: [Sky.istanbul])
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()), geocoder: geocoder)
        let test = TestHost(city: nil)
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
        XCTAssertEqual(test.preferences.storedKeys, ["city"], "choosing a city writes the city and nothing else")
        XCTAssertEqual(droplet.glance?.city, Sky.istanbul, "and the wing reads it at once")
        droplet.deactivate()
    }

    func testTheRoomWritesFourKeysAndNothingElse() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()),
                                        geocoder: FakeGeocoder(answer: []))
        let test = TestHost(city: nil)
        try droplet.activate(host: test.host)
        droplet.choose(Sky.istanbul)
        droplet.unit = .fahrenheit
        droplet.intervalMinutes = 60
        droplet.pinned = true
        await settle()
        XCTAssertEqual(test.preferences.storedKeys, ["city", "intervalMinutes", "pinned", "unit"])
        XCTAssertEqual(test.preferences.namespacedKey("pinned"), "droplet.ori-weather.pinned")
        droplet.deactivate()
    }
}

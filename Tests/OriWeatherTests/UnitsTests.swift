import XCTest
@testable import OriWeather

final class UnitsTests: XCTestCase {
    private func reading(_ celsius: Double) -> WeatherReading {
        WeatherReading(temperature: celsius, feelsLike: celsius, code: 0, isDay: true, at: Sky.now)
    }

    /// Rounded after converting: 25.5 °C is 77.9 °F, which is 78°, not the 79°
    /// that rounding to 26° first would give.
    func testTwentyFiveAndAHalfIsTwentySixAndSeventyEight() {
        XCTAssertEqual(reading(25.5).degrees(in: .celsius), "26°")
        XCTAssertEqual(reading(25.5).degrees(in: .fahrenheit), "78°")
        XCTAssertEqual(reading(25.5).feelsLike(in: .fahrenheit), "78°")
    }

    /// A figure that rounds to zero from below is "0°" in either unit: -0.4 °C,
    /// and -18 °C, which is -0.4 °F.
    func testNothingReadsMinusZero() {
        XCTAssertEqual(reading(-0.4).degrees(in: .celsius), "0°")
        XCTAssertEqual(reading(-18).degrees(in: .fahrenheit), "0°")
        XCTAssertEqual(reading(-12).degrees(in: .celsius), "-12°")
    }

    /// Flipping the unit redraws the wing from the reading it has.
    @MainActor
    func testFlippingTheUnitRedrawsWithoutAFetch() async throws {
        let fetcher = FakeWeather(reading: Sky.reading())
        let droplet = OriWeatherDroplet(fetcher: fetcher)
        let test = TestHost()
        try droplet.activate(host: test.host)
        droplet.liveActivitySeatDidChange(.compact)
        await settle()
        XCTAssertEqual(droplet.glance?.degrees, "26°")
        let before = await fetcher.counter.count

        droplet.unit = .fahrenheit
        await settle()
        XCTAssertEqual(droplet.glance?.degrees, "78°")
        XCTAssertEqual(droplet.glance?.feelsLike, "76°")
        XCTAssertEqual(droplet.activitySubject.value?.accessibilityTitle, "78 degrees, partly cloudy, Istanbul")
        let after = await fetcher.counter.count
        XCTAssertEqual(after, before)
        droplet.deactivate()
    }
}

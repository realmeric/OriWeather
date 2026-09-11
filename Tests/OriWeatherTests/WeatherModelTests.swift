import XCTest
@testable import OriWeather

@MainActor
final class WeatherModelTests: XCTestCase {
    private let now = Sky.now

    func testItReadsAndPutsATemperatureUp() async {
        let fetcher = FakeWeather(reading: Sky.reading())
        let model = WeatherModel(fetcher: fetcher, city: Sky.istanbul, clock: { self.now })
        model.start()
        await settle()
        XCTAssertEqual(model.reading?.temperature, 25.5)
        XCTAssertFalse(model.isStale)
        let count = await fetcher.counter.count
        XCTAssertEqual(count, 1)
        model.stop()
    }

    /// An aeroplane: the last reading stays, and it says how old it is.
    func testARefusedReadLeavesTheLastOneUpAndDimmed() async {
        let fetcher = SwitchableWeather(Sky.reading())
        let model = WeatherModel(fetcher: fetcher, city: Sky.istanbul, clock: { self.now })
        model.start()
        await settle()
        XCTAssertNotNil(model.reading)

        fetcher.answer(nil)
        model.refresh(at: now + 31 * 60, because: .clock)
        await settle()
        XCTAssertTrue(model.isStale)
        XCTAssertEqual(model.reading?.temperature, 25.5)
        XCTAssertEqual(model.now, now + 31 * 60, "the age is measured against the attempt")
        model.stop()

        let never = WeatherModel(fetcher: FakeWeather(reading: nil), city: Sky.istanbul,
                                 clock: { self.now })
        never.start()
        await settle()
        XCTAssertFalse(never.isStale)
        XCTAssertNil(never.reading, "nothing was ever read here, so there is nothing to keep")
        never.stop()
    }

    /// Built and never started: no clock, nothing fetched (D6).
    func testOffCostsNothing() async {
        let fetcher = FakeWeather(reading: Sky.reading())
        let model = WeatherModel(fetcher: fetcher, city: Sky.istanbul, clock: { self.now })
        await settle()
        XCTAssertFalse(model.isRunning)
        let count = await fetcher.counter.count
        XCTAssertEqual(count, 0)
    }

    func testTheClockLivesAsLongAsTheFeatureDoes() {
        let model = WeatherModel(fetcher: FakeWeather(reading: Sky.reading()),
                                 city: Sky.istanbul, clock: { self.now })
        XCTAssertFalse(model.isRunning)
        model.start()
        XCTAssertTrue(model.isRunning)
        model.stop()
        XCTAssertFalse(model.isRunning)
    }

    /// Nowhere to ask about is not a reason to ask the network anyway.
    func testWithNoCityNothingIsFetched() async {
        let fetcher = FakeWeather(reading: Sky.reading())
        let model = WeatherModel(fetcher: fetcher, city: nil, clock: { self.now })
        model.start()
        model.refresh(at: now + 3600, because: .clock)
        await settle()
        let count = await fetcher.counter.count
        XCTAssertEqual(count, 0)
        XCTAssertNil(model.reading)
        model.stop()
    }

    /// A seat or a shelf asking inside the interval of the last reading costs
    /// nothing; past it, one request.
    func testARefreshInsideTheIntervalIsANoOp() async {
        let fetcher = FakeWeather(reading: Sky.reading())
        let model = WeatherModel(fetcher: fetcher, city: Sky.istanbul, every: 30 * 60,
                                 clock: { self.now })
        model.refresh(at: now, because: .seat)
        await settle()
        model.refresh(at: now + 29 * 60, because: .seat)
        model.refresh(at: now + 29 * 60, because: .shelf)
        await settle()
        var count = await fetcher.counter.count
        XCTAssertEqual(count, 1)
        XCTAssertEqual(model.now, now, "a refresh that did nothing moves nothing")

        model.refresh(at: now + 30 * 60, because: .seat)
        await settle()
        count = await fetcher.counter.count
        XCTAssertEqual(count, 2)
    }

    func testANewCityDropsTheOldSkyAndReadsAtOnce() async {
        let fetcher = FakeWeather(reading: Sky.reading())
        let model = WeatherModel(fetcher: fetcher, city: Sky.istanbul, clock: { self.now })
        model.start()
        await settle()
        let ankara = City(name: "Ankara", region: "Ankara", country: "Republic of Türkiye",
                          place: Place(latitude: 39.92, longitude: 32.85), timeZone: "Europe/Istanbul")
        model.city = ankara
        await settle()
        let count = await fetcher.counter.count
        XCTAssertEqual(count, 2)
        XCTAssertNotNil(model.reading)
        model.stop()
    }
}

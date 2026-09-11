import DroppyKit
import XCTest
@testable import OriWeather

/// What ORI-36 and ORI-61 settled in OriNotch, made true under a host that
/// seats and unseats: the interval is the only clock.
@MainActor
final class StaleTests: XCTestCase {
    /// 14:00 in Istanbul.
    private let two = Date(timeIntervalSince1970: 1_788_000_000)
    private var clock: Date = .distantPast

    private func at(minutes: Double) -> Date { two + minutes * 60 }

    func testLosingTheSeatKeepsTheReadingAndRegainingItReadsOnlyWhenItIsOld() async {
        let fetcher = FakeWeather(reading: Sky.reading(two))
        clock = two
        let model = WeatherModel(fetcher: fetcher, city: Sky.istanbul, every: 30 * 60,
                                 clock: { [unowned self] in self.clock })
        model.start()
        await settle()
        var count = await fetcher.counter.count
        XCTAssertEqual(count, 1)

        model.stop()                         // seat lost at 14:00
        XCTAssertNotNil(model.reading, "the reading stays")

        clock = at(minutes: 10)              // regained at 14:10
        model.start()
        await settle()
        count = await fetcher.counter.count
        XCTAssertEqual(count, 1, "ten minutes old is not old")
        model.stop()

        clock = at(minutes: 45)              // regained at 14:45
        model.start()
        await settle()
        count = await fetcher.counter.count
        XCTAssertEqual(count, 2)
        model.stop()
    }

    /// Ten display wakes in a minute are one request at most.
    func testAWakeStormIsOneRequestAtMost() async {
        let fetcher = FakeWeather(reading: Sky.reading(two))
        let model = WeatherModel(fetcher: fetcher, city: Sky.istanbul, every: 30 * 60,
                                 clock: { self.two })
        for wake in 0 ..< 10 {
            model.refresh(at: two + Double(wake) * 6, because: .seat)
        }
        await settle()
        for wake in 0 ..< 10 {
            model.refresh(at: two + Double(wake) * 6, because: .shelf)
        }
        await settle()
        let count = await fetcher.counter.count
        XCTAssertEqual(count, 1)
    }

    /// A refused refresh dims and dates rather than clears, and the age is
    /// measured against the attempt, not a ticking clock.
    func testARefusedRefreshDatesTheReadingItKeeps() async throws {
        let fetcher = SwitchableWeather(Sky.reading(two))
        let droplet = OriWeatherDroplet(fetcher: fetcher)
        try droplet.activate(host: TestHost().host)
        await settle()
        fetcher.answer(nil)
        droplet.model?.refresh(at: at(minutes: 45), because: .clock)
        await settle()
        let glance = try XCTUnwrap(droplet.glance)
        XCTAssertTrue(glance.isStale)
        XCTAssertEqual(glance.degrees, "26°")
        XCTAssertEqual(glance.detail, "45 min ago")
        droplet.deactivate()
    }

    /// Clearing the city gives the seat up at once, exactly once.
    func testClearingTheCityYieldsTheSeatOnce() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading(two)))
        let test = TestHost()
        try droplet.activate(host: test.host)
        await settle()
        XCTAssertNotNil(droplet.activitySubject.value)

        Preferences(service: test.preferences).city = nil
        await settle()
        let yields = test.recorder.effects.filter { $0.service == "liveActivity" && $0.detail == "yield idle" }
        XCTAssertEqual(yields.count, 1)
        XCTAssertNil(droplet.activitySubject.value)
        XCTAssertNil(droplet.glance)
        droplet.deactivate()
    }
}

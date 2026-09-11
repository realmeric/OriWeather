import DroppyKit
import XCTest
@testable import OriWeather

@MainActor
final class LockScreenTests: XCTestCase {
    private func glance(code: Int = 2, isDay: Bool = true, stale: Bool = false) -> Glance {
        let reading = WeatherReading(temperature: 25.5, feelsLike: 24.2, code: code, isDay: isDay, at: Sky.now)
        return Glance(reading: reading, isStale: stale, now: Sky.now + 45 * 60, city: Sky.istanbul, unit: .celsius)
    }

    /// Both styles are filled, because the user picks the style in Droppy.
    func testTheEntryFillsBothStyles() {
        let entry = LockScreenRow.entry(glance())
        XCTAssertEqual(entry.systemImage, "cloud.sun.fill")
        XCTAssertEqual(entry.text, "26°")
        XCTAssertEqual(entry.detail, "Partly cloudy")
        XCTAssertEqual(entry.roundedCenterText, "26°")
        XCTAssertEqual(entry.roundedBottomText, "Some sun")
        XCTAssertNil(entry.progress)
        XCTAssertFalse(entry.ticksEverySecond, "a temperature has nothing to say every second")
    }

    func testByNightTheSymbolsAreTheMoons() {
        XCTAssertEqual(LockScreenRow.entry(glance(code: 0, isDay: false)).systemImage, "moon.fill")
        XCTAssertEqual(LockScreenRow.entry(glance(code: 2, isDay: false)).systemImage, "cloud.moon.fill")
    }

    /// An old reading says how old it is in both styles, as the card does.
    func testAStaleReadingSaysItsAge() {
        let entry = LockScreenRow.entry(glance(stale: true))
        XCTAssertEqual(entry.detail, "45 min ago")
        XCTAssertEqual(entry.roundedBottomText, "45 min ago")
    }

    /// Every mark has a symbol and every code a caption short enough for the
    /// space under a ring.
    func testEveryCodeHasASymbolAndAShortCaption() {
        for mark in WeatherCode.Mark.allCases {
            XCTAssertFalse(LockScreenRow.symbol(mark, isDay: true).isEmpty)
            XCTAssertFalse(LockScreenRow.symbol(mark, isDay: false).isEmpty)
        }
        for code in [0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77,
                     80, 81, 82, 85, 86, 95, 96, 99] {
            XCTAssertLessThanOrEqual(LockScreenRow.short(code).count, 8, "code \(code)")
        }
    }

    /// The row does not wait for the pin, and says nothing without a reading.
    func testTheRowIsPublishedWithAReadingWhetherOrNotPinned() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        try droplet.activate(host: TestHost(pinned: nil).host)
        await settle()
        XCTAssertNil(droplet.activitySubject.value, "unpinned, no wing")
        XCTAssertEqual(droplet.lockScreenSubject.value?.text, "26°")
        droplet.deactivate()
        XCTAssertNil(droplet.lockScreenSubject.value)

        let empty = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        try empty.activate(host: TestHost(city: nil).host)
        await settle()
        XCTAssertNil(empty.lockScreenSubject.value)
        empty.deactivate()
    }

    /// Locked with the screen awake, the row is seen, so the clock runs;
    /// asleep or unlocked, it stops unless something else is seen.
    func testTheLockedScreenIsWhereTheClockAlsoLives() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        try droplet.activate(host: TestHost(granted: [.networkClient, .lockScreen]).host)
        await settle()
        let model = try XCTUnwrap(droplet.model)
        droplet.liveActivitySeatDidChange(.none(.surfaceSuppressed))
        XCTAssertFalse(model.isRunning)

        droplet.lockChanged(locked: true)
        XCTAssertTrue(model.isRunning, "locked and awake: the row is seen")
        droplet.displayChanged(awake: false)
        XCTAssertFalse(model.isRunning, "the display asleep: nobody sees it")
        droplet.displayChanged(awake: true)
        XCTAssertTrue(model.isRunning)
        droplet.lockChanged(locked: false)
        XCTAssertFalse(model.isRunning, "unlocked and unseated")
        droplet.deactivate()
    }

    func testWithoutTheLockScreenGrantLockingRunsNothing() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        try droplet.activate(host: TestHost().host)
        await settle()
        let model = try XCTUnwrap(droplet.model)
        droplet.lockChanged(locked: true)
        XCTAssertFalse(model.isRunning)
        droplet.deactivate()
    }
}

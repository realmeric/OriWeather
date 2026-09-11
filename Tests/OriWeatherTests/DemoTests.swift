import DroppyKit
import DroppyKitHarness
import XCTest
@testable import OriWeather

final class DemoTests: XCTestCase {
    func testTheVariableIsReadTheWayTheCardSays() {
        XCTAssertEqual(Demo.mode(environment: [:], isHarness: true), .fixed)
        XCTAssertNil(Demo.mode(environment: [:], isHarness: false))
        XCTAssertEqual(Demo.mode(environment: ["OW_DEMO": "1"], isHarness: false), .fixed)
        XCTAssertEqual(Demo.mode(environment: ["OW_DEMO": "stale"], isHarness: false), .stale)
        XCTAssertEqual(Demo.mode(environment: ["OW_DEMO": "stale"], isHarness: true), .stale)
    }

    func testTheFixedSkyIsTwentySixAndPartlyCloudyEveryTime() async throws {
        let demo = DemoWeather(mode: .fixed)
        for _ in 0 ..< 3 {
            let reading = try await demo.read(at: Demo.city.place)
            XCTAssertEqual(reading.degrees, "26°")
            XCTAssertEqual(reading.feelsLike(in: .celsius), "24°")
            XCTAssertEqual(reading.condition, "Partly cloudy")
            XCTAssertTrue(reading.isDay)
        }
    }

    /// An aeroplane: one good read, then refused, and the model keeps the
    /// reading up and says it is stale.
    @MainActor
    func testTheStaleSkyRefusesItsSecondReadAndTheReadingStaysUp() async throws {
        let demo = DemoWeather(mode: .stale)
        _ = try await demo.read(at: Demo.city.place)
        do {
            _ = try await demo.read(at: Demo.city.place)
            XCTFail("the second read should be refused")
        } catch {
            XCTAssertEqual(error as? WeatherError, .refused)
        }

        let model = WeatherModel(fetcher: DemoWeather(mode: .stale), city: Demo.city)
        model.refresh(because: .launch)
        await settle()
        XCTAssertFalse(model.isStale)
        model.refresh(because: .clock)
        await settle()
        XCTAssertTrue(model.isStale)
        XCTAssertEqual(model.reading?.degrees, "26°")
        let age = try XCTUnwrap(model.reading.map { Ago.words($0.at, at: model.now) })
        XCTAssertEqual(age, "2 h ago")
    }
}

@MainActor
final class DemoPreferencesTests: XCTestCase {
    /// The harness is a demo sky; finding a city there would write the demo's
    /// city into preferences, and in the Playground those are the user's own.
    func testTheDemoSkyWritesNoCity() async throws {
        let droplet = OriWeatherDroplet()
        let test = TestHost(city: nil)
        let harness = DropletHost(
            grantedCapabilities: [.networkClient],
            preferences: test.preferences,
            environment: HarnessEnvironmentService(appVersion: "15.3.0", dropletID: OriWeatherDroplet.id),
            log: HarnessLogService(recorder: test.recorder),
            installState: test.installState,
            hud: HarnessHUDService(recorder: test.recorder),
            shelf: HarnessShelfService(recorder: test.recorder),
            liveActivity: test.liveActivity,
            notchSurface: HarnessNotchSurfaceService(recorder: test.recorder, dropletID: OriWeatherDroplet.id),
            shortcuts: HarnessShortcutsService(recorder: test.recorder),
            workspace: HarnessWorkspaceService(recorder: test.recorder),
            feedback: HarnessFeedbackService(recorder: test.recorder),
            permissions: HarnessPermissionsService(recorder: test.recorder))
        try droplet.activate(host: harness)
        await settle()
        XCTAssertEqual(droplet.glance?.city, Demo.city, "the demo sky shows its own city")
        XCTAssertFalse(test.preferences.hasValue(forKey: Preferences.Key.city), "and stores none")
        droplet.deactivate()
    }
}

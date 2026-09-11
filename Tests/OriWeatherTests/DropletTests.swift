import Combine
import DroppyKit
import DroppyKitHarness
import SwiftUI
import XCTest
@testable import OriWeather

/// The harness's environment says it is the harness, which turns the demo sky
/// on; these tests want the droplet as it runs in Droppy.
@MainActor
final class DroppyEnvironment: DropletEnvironmentService {
    let appVersion = "15.3.0"
    let isHarness = false
    let notchGeometry = DropletNotchGeometry(closedWidth: 200, closedHeight: 32, cornerRadius: 12,
                                             isHardwareNotch: true, displayID: 1)
    let surfaceAppearance = DropletSurfaceAppearance.dark
    let containerDirectory = FileManager.default.temporaryDirectory
    var didChange: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
}

/// A host built from the harness's public services, which are this
/// repository's fakes.
@MainActor
struct TestHost {
    let recorder = HarnessRecorder()
    let preferences: HarnessPreferencesService
    let liveActivity: HarnessLiveActivityService
    let installState = HarnessInstallStateService()
    let host: DropletHost

    init(city: City? = Sky.istanbul, granted: Set<DropletPermission> = [.networkClient]) {
        recorder.grantedCapabilities = granted
        preferences = HarnessPreferencesService(dropletID: OriWeatherDroplet.id, recorder: recorder)
        liveActivity = HarnessLiveActivityService(recorder: recorder)
        if let city { Preferences(service: preferences).city = city }
        host = DropletHost(
            grantedCapabilities: granted,
            preferences: preferences,
            environment: DroppyEnvironment(),
            log: HarnessLogService(recorder: recorder),
            installState: installState,
            hud: HarnessHUDService(recorder: recorder),
            shelf: HarnessShelfService(recorder: recorder),
            liveActivity: liveActivity,
            notchSurface: HarnessNotchSurfaceService(recorder: recorder, dropletID: OriWeatherDroplet.id),
            shortcuts: HarnessShortcutsService(recorder: recorder),
            workspace: HarnessWorkspaceService(recorder: recorder),
            feedback: HarnessFeedbackService(recorder: recorder),
            permissions: HarnessPermissionsService(recorder: recorder)
        )
    }
}

@MainActor
final class DropletTests: XCTestCase {
    /// The id is the folder the loader looks in, the key prefix preferences
    /// are stored under and the manifest's first line; the three must agree.
    func testTheIdIsTheOneTheManifestNames() {
        XCTAssertEqual(OriWeatherDroplet.id, "ori-weather")
    }

    func testWithACityAndAReadingItAsksForTheSeatAtTheAmbientPriority() async throws {
        let fetcher = FakeWeather(reading: Sky.reading())
        let droplet = OriWeatherDroplet(fetcher: fetcher)
        let test = TestHost()
        try droplet.activate(host: test.host)
        await settle()
        let state = try XCTUnwrap(droplet.activitySubject.value)
        XCTAssertEqual(state.priority, 10)
        XCTAssertEqual(state.accessibilityTitle, "26 degrees, partly cloudy, Istanbul")
        XCTAssertFalse(state.isInteractive)
        XCTAssertFalse(state.joinsPersistentActivitySet, "pinning is off until the user turns it on")
        XCTAssertEqual(state.expandedWidgetID, "weather")
        droplet.deactivate()
    }

    func testWithNoCityItAsksForNothing() async throws {
        let fetcher = FakeWeather(reading: Sky.reading())
        let droplet = OriWeatherDroplet(fetcher: fetcher)
        try droplet.activate(host: TestHost(city: nil).host)
        await settle()
        XCTAssertNil(droplet.activitySubject.value)
        let count = await fetcher.counter.count
        XCTAssertEqual(count, 0)
        droplet.deactivate()
    }

    func testTheSeatIsWhereTheClockLives() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        try droplet.activate(host: TestHost().host)
        await settle()
        let model = try XCTUnwrap(droplet.model)
        droplet.liveActivitySeatDidChange(.none(.outranked))
        XCTAssertFalse(model.isRunning)
        droplet.liveActivitySeatDidChange(.compact)
        XCTAssertTrue(model.isRunning)
        droplet.liveActivitySeatDidChange(.none(.surfaceSuppressed))
        XCTAssertFalse(model.isRunning)
        XCTAssertNotNil(droplet.glance, "losing the seat keeps the reading")
        droplet.deactivate()
    }

    func testAPinFlippedInThePreferencesIsRepublished() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        let test = TestHost()
        try droplet.activate(host: test.host)
        await settle()
        Preferences(service: test.preferences).pinned = true
        await settle()
        XCTAssertEqual(droplet.activitySubject.value?.joinsPersistentActivitySet, true)
        droplet.deactivate()
    }

    /// Off means off: after deactivate there is no state, no clock, and
    /// nothing is fetched however long anybody waits.
    func testDeactivateLeavesNothingRunning() async throws {
        let fetcher = FakeWeather(reading: Sky.reading())
        let droplet = OriWeatherDroplet(fetcher: fetcher)
        let test = TestHost()
        try droplet.activate(host: test.host)
        await settle()
        droplet.liveActivitySeatDidChange(.compact)
        let model = try XCTUnwrap(droplet.model)
        XCTAssertTrue(model.isRunning)

        droplet.deactivate()
        XCTAssertNil(droplet.activitySubject.value)
        XCTAssertFalse(model.isRunning)
        let before = await fetcher.counter.count
        Preferences(service: test.preferences).city = City(
            name: "Ankara", region: nil, country: nil,
            place: Place(latitude: 39.92, longitude: 32.85), timeZone: nil)
        droplet.liveActivitySeatDidChange(.compact)
        await settle()
        let after = await fetcher.counter.count
        XCTAssertEqual(after, before, "a new city and a seat after deactivate fetch nothing")
        XCTAssertFalse(model.isRunning)
        XCTAssertNil(droplet.model)
    }

    /// The coldest figure the wing is likely to carry fits the trailing wing
    /// on a notch, inside the host's inset.
    func testMinusTwelveFitsTheTrailingWing() throws {
        let hosting = NSHostingView(rootView: WingFigure(text: "-12°"))
        let width = hosting.fittingSize.width
        let room = DroppyLiveActivityMetrics.compactNotchWingWidth
            - DroppyLiveActivityMetrics.symmetricPadding(iconSize: DroppyLiveActivityMetrics.iconSize,
                                                         usesNotchStyle: true)
        XCTAssertLessThanOrEqual(width, room, "-12° is \(width) pt in a \(room) pt wing")
        try Shots.write(WingFigure(text: "-12°").padding(4).background(Color.black),
                        name: "wing-minus-12")
    }
}

/// Pictures a test draws of something the harness does not show, written
/// beside the harness's own shots.
@MainActor
enum Shots {
    static func write(_ view: some View, name: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        else { throw CocoaError(.fileWriteUnknown) }
        let directory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("shots/extra", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try png.write(to: directory.appendingPathComponent("\(name).png"))
    }
}

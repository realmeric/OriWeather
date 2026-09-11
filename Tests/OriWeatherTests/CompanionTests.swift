import DroppyKit
import SwiftUI
import XCTest
@testable import OriWeather

/// The harness draws no companion pill, so these draw it: a round 24 pt puck
/// with the mark in it, and the capsule the puck grows into with the line
/// beside the mark. The pictures land in `shots/extra/`.
@MainActor
final class CompanionTests: XCTestCase {
    private let puck = CGSize(width: 24, height: 24)

    func testTheMarkFillsThePuckRatherThanSittingInItAsADot() async throws {
        let droplet = OriWeatherDroplet(fetcher: FakeWeather(reading: Sky.reading()))
        try droplet.activate(host: TestHost().host)
        await settle()
        let context = CompactLiveActivityContext(surface: .builtInNotch, seat: .secondary, slotSize: puck)
        let mark = droplet.makeCompanionCompact(context: context)
        let size = NSHostingView(rootView: mark).fittingSize
        XCTAssertEqual(size.width, puck.width, accuracy: 0.5)
        XCTAssertEqual(size.height, puck.height, accuracy: 0.5)

        try Shots.write(
            mark.background(Circle().fill(Color.black).padding(-DroppySpacing.xs))
                .padding(DroppySpacing.sm),
            name: "companion-puck")

        let line = try XCTUnwrap(droplet.makeCompanionDetail(
            context: LiveActivityContext(surface: .builtInNotch, availableWidth: 160)))
        try Shots.write(
            HStack(spacing: DroppySpacing.sm) {
                droplet.makeCompanionCompact(context: context)
                line
            }
            .frame(width: 200, height: 36)
            .padding(.horizontal, DroppySpacing.md)
            .background(Capsule().fill(Color.black)),
            name: "companion-capsule")
        droplet.deactivate()
    }
}

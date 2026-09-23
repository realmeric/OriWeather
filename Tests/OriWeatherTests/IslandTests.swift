import AppKit
import DroppyKit
import SwiftUI
import XCTest
@testable import OriWeather

/// The harness hands both of its shelf stages the session's own curvature, so
/// its island never gets the 12 pt a solo card there is inset on every edge,
/// and the island's corner cuts into a widget the host would have inset. This
/// draws that card the way the host does, at the declared size, and checks
/// the solo composition fits inside the inset. The picture lands in
/// `shots/extra/`.
@MainActor
final class IslandTests: XCTestCase {
    func testTheSoloWidgetFitsInsideTheIslandsInset() async throws {
        let droplet = OriWeatherDroplet(fetcher: DemoWeather(mode: .fixed))
        try droplet.activate(host: TestHost().host)
        await settle()
        let size = CGSize(width: Look.shelfSoloWidth, height: Look.shelfHeight)
        let context = ShelfWidgetContext(
            availableSize: size, isPaired: false, placement: .solo, isCompact: false,
            isShelfTransitioning: false, isPreview: true, surface: .dynamicIsland,
            usesIslandCurvature: true, usesAdaptiveForegrounds: false)
        XCTAssertFalse(droplet.glance?.hours.isEmpty ?? true, "the tallest composition has the hours")

        let natural = NSHostingView(rootView: WeatherWidget(droplet: droplet, context: context)
            .frame(width: size.width)
            .fixedSize(horizontal: false, vertical: true)).fittingSize
        XCTAssertLessThanOrEqual(natural.height, size.height, "the hours run past the island's inset")

        try Shots.write(
            WeatherWidget(droplet: droplet, context: context)
                .frame(width: size.width, height: size.height)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: DroppyShellMetrics.shelfFullBleedCornerRadius,
                                            style: .continuous))
                .padding(DroppySpacing.xxl)
                .background(Color(white: 0.22)),
            name: "shelf-island")
        droplet.deactivate()
    }
}

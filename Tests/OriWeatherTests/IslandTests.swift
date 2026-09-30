import AppKit
import DroppyKit
import SwiftUI
import XCTest
@testable import OriWeather

/// A solo card on an island, drawn the way the host draws it: the island's
/// curvature, the host's inset for it (none since DroppyKit 1.20.1, the shell
/// being the clip) and the declared size. The solo composition has to fit. The
/// picture lands in `shots/extra/`.
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

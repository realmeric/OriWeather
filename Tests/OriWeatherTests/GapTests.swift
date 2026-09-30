import AppKit
import DroppyKit
import SwiftUI
import XCTest
@testable import OriWeather

/// The widget's ink stands as far from the floor as from the walls, alone and
/// beside another widget, measured on the rendered pixels the way the Store's
/// review measures it. The host's inset is the one under a notch.
@MainActor
final class GapTests: XCTestCase {
    func testTheLastRowStandsAsFarFromTheFloorAsFromTheWalls() async throws {
        let droplet = OriWeatherDroplet(fetcher: DemoWeather(mode: .fixed))
        try droplet.activate(host: TestHost().host)
        await settle()
        for paired in [false, true] {
            let size = CGSize(width: paired ? Look.shelfPairedWidth : Look.shelfSoloWidth, height: Look.shelfHeight)
            let context = ShelfWidgetContext(
                availableSize: size, isPaired: paired, placement: paired ? .leading : .solo, isCompact: paired,
                isShelfTransitioning: false, isPreview: true, surface: .builtInNotch,
                usesIslandCurvature: false, usesAdaptiveForegrounds: false)
            let gaps = try ink(WeatherWidget(droplet: droplet, context: context)
                .frame(width: size.width, height: size.height).background(Color.black))
            let walls = (gaps.left + gaps.right) / 2
            XCTAssertEqual(gaps.bottom, walls, accuracy: 1, "paired: \(paired), gaps: \(gaps)")
        }
        droplet.deactivate()
    }

    /// The gaps, in points, between the edges and anything lit.
    private func ink(_ view: some View) throws -> (left: Double, right: Double, top: Double, bottom: Double) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.cgImage)
        let w = image.width, h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let context = try XCTUnwrap(CGContext(
            data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var minX = w, maxX = 0, minY = h, maxY = 0
        for y in 0 ..< h {
            for x in 0 ..< w where Int(data[(y * w + x) * 4]) + Int(data[(y * w + x) * 4 + 1])
                + Int(data[(y * w + x) * 4 + 2]) > 90 {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        // The bitmap's first row is the top of the image.
        return (Double(minX) / 2, Double(w - 1 - maxX) / 2, Double(minY) / 2, Double(h - 1 - maxY) / 2)
    }
}

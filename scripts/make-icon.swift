//
// Draws the droplet's icon layer and the creator avatar. Run it when a mark
// changes:
//
//     make icon
//
// The icon is a sun behind a cloud, drawn from this droplet's own shapes
// (`Sources/OriWeather/Marks.swift`, compiled in beside this file), so the icon
// and the wing cannot drift apart. The layer is artwork only: no square, no
// rounded corners and no shadow, because Icon Composer adds all three and a
// painted-in one shows as a double edge. The artwork stays inside the centre
// 820 of 1024.
//
// The avatar is Meric's mark, OriNotch's notch with a wing out either side, in
// ink on paper, square and unrounded: the Store clips it to a circle itself.
//
// Three previews land in shots/: the icon as the Store would compose it at
// 1024, and the same at 28 pt, at 1x and 2x, the smallest size the Store
// draws and the one that decides whether it reads.

import AppKit
import SwiftUI

/// Paper and ink, the two colours everything of Meric's is built from.
let paper = NSColor(srgbRed: 0.757, green: 0.792, blue: 0.851, alpha: 1)   // #c1cad9
let ink = NSColor(srgbRed: 0.165, green: 0.196, blue: 0.255, alpha: 1)     // #2a3241
/// OriNotch's warm yellow, the sun's colour on the wing.
let warm = NSColor(srgbRed: 1.0, green: 0.83, blue: 0.35, alpha: 1)

@main
struct MakeIcon {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let icon = root.appendingPathComponent("OriWeather.icon/Assets/mark.png")
        let avatar = root.appendingPathComponent("Assets/Creator.png")
        let shots = root.appendingPathComponent("shots", isDirectory: true)
        try FileManager.default.createDirectory(at: shots, withIntermediateDirectories: true)

        try png(pixels: 1024) { drawSky(in: $0, side: 1024) }.write(to: icon)
        try png(pixels: 512) { drawNotch(in: $0, side: 512) }.write(to: avatar)

        // What the Store composes: the document's flat ink fill in a rounded
        // square, and the layer at the document's 0.8 scale on top.
        for (pixels, name) in [(1024, "icon-preview.png"), (56, "icon-28pt@2x.png"), (28, "icon-28pt.png")] {
            try png(pixels: pixels) { context in
                let side = CGFloat(pixels)
                let radius = side * 0.2237
                context.setFillColor(ink.cgColor)
                context.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: side, height: side),
                                       cornerWidth: radius, cornerHeight: radius, transform: nil))
                context.fillPath()
                context.translateBy(x: side * 0.1, y: side * 0.1)
                context.scaleBy(x: 0.8, y: 0.8)
                drawSky(in: context, side: side)
            }.write(to: shots.appendingPathComponent(name))
        }
        print("wrote \(icon.path), \(avatar.path) and three previews in shots/")
    }

    /// The sun up and to the right, the cloud in front of it down and to the
    /// left, with a gap cut round the cloud so the two stay two shapes at 28 pt.
    static func drawSky(in context: CGContext, side: CGFloat) {
        let unit = side / 1024
        let sun = CGRect(x: 420, y: 118, width: 486, height: 486).scaled(by: unit)
        let cloud = CGRect(x: 118, y: 330, width: 700, height: 560).scaled(by: unit)

        let sunPath = Marks.Sun().path(in: sun).cgPath
        let cloudPath = Marks.Cloud().path(in: cloud).cgPath

        context.setFillColor(warm.cgColor)
        context.addPath(sunPath)
        context.fillPath()

        // The gap: the cloud's outline, stroked wide, erased out of the sun.
        context.saveGState()
        context.setBlendMode(.clear)
        context.setLineWidth(56 * unit)
        context.setLineJoin(.round)
        context.addPath(cloudPath)
        context.strokePath()
        context.restoreGState()

        context.setFillColor(NSColor.white.cgColor)
        context.addPath(cloudPath)
        context.fillPath()
    }

    /// OriNotch's mark: the notch, square where the bezel cuts it and round at
    /// the bottom, with a wing either side overlapping it so the three are one
    /// object small. Ink on a full paper square, unrounded.
    static func drawNotch(in context: CGContext, side: CGFloat) {
        context.setFillColor(paper.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))

        let grid = side * 0.14
        let box = CGRect(x: grid, y: grid, width: side - grid * 2, height: side - grid * 2)
        let bodyWidth = box.width * 0.62
        let bodyHeight = box.height * 0.36
        // Flipped context: y grows downward, so the square top is minY.
        let body = CGRect(x: box.midX - bodyWidth / 2, y: box.midY - bodyHeight * 0.58,
                          width: bodyWidth, height: bodyHeight)
        let corner = bodyHeight * 0.46
        let mark = CGMutablePath()
        mark.move(to: CGPoint(x: body.minX, y: body.minY))
        mark.addLine(to: CGPoint(x: body.minX, y: body.maxY - corner))
        mark.addArc(center: CGPoint(x: body.minX + corner, y: body.maxY - corner), radius: corner,
                    startAngle: .pi, endAngle: .pi / 2, clockwise: true)
        mark.addLine(to: CGPoint(x: body.maxX - corner, y: body.maxY))
        mark.addArc(center: CGPoint(x: body.maxX - corner, y: body.maxY - corner), radius: corner,
                    startAngle: .pi / 2, endAngle: 0, clockwise: true)
        mark.addLine(to: CGPoint(x: body.maxX, y: body.minY))
        mark.closeSubpath()

        context.setFillColor(ink.cgColor)
        context.addPath(mark)
        context.fillPath()

        // Filled one by one: a wing wound the other way from the body would
        // punch a hole where the two overlap.
        let wingHeight = bodyHeight * 0.36
        let wingWidth = box.width * 0.19
        let wingY = body.maxY - bodyHeight * 0.2 - wingHeight
        for x in [body.minX - wingWidth + wingHeight / 2, body.maxX - wingHeight / 2] {
            context.addPath(CGPath(roundedRect: CGRect(x: x, y: wingY, width: wingWidth, height: wingHeight),
                                   cornerWidth: wingHeight / 2, cornerHeight: wingHeight / 2,
                                   transform: nil))
            context.fillPath()
        }
    }

    /// A square bitmap drawn in a flipped context, so y grows downward the way
    /// SwiftUI's shapes expect.
    static func png(pixels: Int, draw: (CGContext) -> Void) throws -> Data {
        guard let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw CocoaError(.fileWriteUnknown) }
        context.translateBy(x: 0, y: CGFloat(pixels))
        context.scaleBy(x: 1, y: -1)
        draw(context)
        guard let image = context.makeImage(),
              let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
        else { throw CocoaError(.fileWriteUnknown) }
        return data
    }
}

extension CGRect {
    func scaled(by factor: CGFloat) -> CGRect {
        CGRect(x: minX * factor, y: minY * factor, width: width * factor, height: height * factor)
    }
}

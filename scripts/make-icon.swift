//
// Draws the droplet's icon layers and the creator avatar. Run it when the
// artwork changes:
//
//     make icon
//
// The icon is the Ori family's rise: the top of a large sun coming up over the
// tile's bottom edge, which is the family's signature (docs/family.md), and
// this droplet's own mark above it, a sun behind an ink cloud. Three layers,
// back to front, so Icon Composer can light each one: rise.png, sun.png and
// cloud.png. The paper ground is the document's own fill, a gradient in
// icon.json. The layers are artwork only: no square, no rounded corners and
// no drop shadow of the icon, because Icon Composer adds all three. The mark
// stays inside the centre 820 of 1024; the rise runs to the edge on purpose,
// and the corners cut it.
//
// The avatar is the maker's mark, the family's rise at dawn: the same sun,
// nearer and higher so a circle shows its crown, on the ink the cloud is
// drawn in. Square and unrounded: the Store clips it to a circle itself.
//
// Three previews land in shots/: the icon as the Store would compose it at
// 1024, and the same at 28 pt, at 1x and 2x, the smallest size the Store
// draws and the one that decides whether it reads.

import AppKit

/// The ground, top to bottom, which icon.json carries as its fill.
let groundTop = rgb(0xF7F9FC)
let groundBottom = rgb(0xC9D3E2)

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func gradient(_ colors: [CGColor], _ locations: [CGFloat]? = nil) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors as CFArray, locations: locations)!
}

@main
struct MakeIcon {
    typealias Layer = (CGContext, CGFloat) -> Void

    static let layers: [(String, Layer)] = [("rise.png", drawRise), ("sun.png", drawSun), ("cloud.png", drawCloud)]

    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let assets = root.appendingPathComponent("OriWeather.icon/Assets", isDirectory: true)
        let avatar = root.appendingPathComponent("Assets/Creator.png")
        let shots = root.appendingPathComponent("shots", isDirectory: true)
        try FileManager.default.createDirectory(at: shots, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

        for (name, draw) in layers {
            try png(pixels: 1024) { draw($0, 1024) }.write(to: assets.appendingPathComponent(name))
        }
        try png(pixels: 512) { drawAvatar($0, 512) }.write(to: avatar)

        // What the Store composes: the document's paper gradient in a rounded
        // square, and the three layers on it at the document's scale, 1.0.
        for (pixels, name) in [(1024, "icon-preview.png"), (56, "icon-28pt@2x.png"), (28, "icon-28pt.png")] {
            try png(pixels: pixels) { context in
                let side = CGFloat(pixels)
                let radius = side * 0.2237
                context.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: side, height: side),
                                       cornerWidth: radius, cornerHeight: radius, transform: nil))
                context.clip()
                context.drawLinearGradient(gradient([groundTop, groundBottom]), start: .zero,
                                           end: CGPoint(x: 0, y: side), options: [])
                for (_, draw) in layers { draw(context, side) }
            }.write(to: shots.appendingPathComponent(name))
        }
        print("wrote \(layers.count) icon layers, \(avatar.path) and three previews in shots/")
    }

    /// The family's signature: the top of a sun far larger than the tile,
    /// coming up over its bottom edge, with its glow above it. The same on
    /// every Ori icon.
    static func drawRise(_ context: CGContext, _ side: CGFloat) {
        sunrise(context, side, centreY: side * 2.02, radius: side * 1.22)
    }

    /// The maker's avatar: the rise on the cloud's ink, the sun at half the
    /// icon's size and its crown a little below the middle.
    static func drawAvatar(_ context: CGContext, _ side: CGFloat) {
        context.drawLinearGradient(gradient([rgb(0x3A4660), rgb(0x262F42)]), start: .zero,
                                   end: CGPoint(x: 0, y: side), options: [])
        sunrise(context, side, centreY: side * 1.18, radius: side * 0.62)
    }

    /// A sun of `radius` centred `centreY` down the tile, in its glow, filled
    /// from its crown to the tile's bottom edge.
    static func sunrise(_ context: CGContext, _ side: CGFloat, centreY: CGFloat, radius: CGFloat) {
        let centre = CGPoint(x: side / 2, y: centreY)
        context.drawRadialGradient(gradient([rgb(0xFFB85A, 0.55), rgb(0xFFB85A, 0)]),
                                   startCenter: centre, startRadius: radius,
                                   endCenter: centre, endRadius: radius + side * 0.22, options: [])
        context.saveGState()
        context.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: 2 * radius, height: 2 * radius))
        context.clip()
        context.drawLinearGradient(gradient([rgb(0xFFD58F), rgb(0xFFA23A)]),
                                   start: CGPoint(x: 0, y: centre.y - radius), end: CGPoint(x: 0, y: side), options: [])
        context.restoreGState()
    }

    /// This droplet's sun, up and to the right, half behind the cloud: a warm
    /// disc lit from its upper left, in its own glow.
    static func drawSun(_ context: CGContext, _ side: CGFloat) {
        let unit = side / 1024
        let centre = CGPoint(x: 668 * unit, y: 318 * unit)
        let radius = 150 * unit
        context.drawRadialGradient(gradient([rgb(0xFFA928, 0.45), rgb(0xFFA928, 0)]),
                                   startCenter: centre, startRadius: radius * 0.9,
                                   endCenter: centre, endRadius: radius * 2.1, options: [])
        context.saveGState()
        context.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: 2 * radius, height: 2 * radius))
        context.clip()
        context.drawRadialGradient(gradient([rgb(0xFFE7A0), rgb(0xFFA928)]),
                                   startCenter: CGPoint(x: centre.x - radius * 0.3, y: centre.y - radius * 0.35),
                                   startRadius: 0, endCenter: centre, endRadius: radius * 1.05,
                                   options: [.drawsAfterEndLocation])
        context.restoreGState()
    }

    /// The cloud in front, in ink, softer than the wing's three-lump glyph
    /// because an icon is seen larger: a pill for its base and three bumps,
    /// shaded top to bottom and resting on a soft shadow of its own.
    static func drawCloud(_ context: CGContext, _ side: CGFloat) {
        let unit = side / 1024
        let rect = CGRect(x: 172 * unit, y: 320 * unit, width: 640 * unit, height: 380 * unit)
        let path = CGMutablePath()
        let h = rect.height, w = rect.width
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + 0.52 * h, width: w, height: 0.48 * h),
                            cornerWidth: 0.24 * h, cornerHeight: 0.24 * h)
        for (x, y, r) in [(0.30, 0.56, 0.25), (0.56, 0.40, 0.38), (0.80, 0.62, 0.22)] as [(CGFloat, CGFloat, CGFloat)] {
            path.addEllipse(in: CGRect(x: rect.minX + x * w - r * h, y: rect.minY + y * h - r * h,
                                       width: 2 * r * h, height: 2 * r * h))
        }
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 20 * unit), blur: 50 * unit, color: rgb(0x0B1220, 0.25))
        context.addPath(path)
        context.setFillColor(rgb(0x262F42))
        context.fillPath()
        context.restoreGState()
        context.saveGState()
        context.addPath(path)
        context.clip()
        context.drawLinearGradient(gradient([rgb(0x3A4660), rgb(0x262F42)]),
                                   start: CGPoint(x: 0, y: rect.minY), end: CGPoint(x: 0, y: rect.maxY), options: [])
        context.restoreGState()
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

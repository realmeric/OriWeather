import CoreGraphics
import SwiftUI

/// The weather marks, drawn rather than shipped.
///
/// One glyph family, flat and filled with one weight, drawn for a
/// surface that shows them from 13 pt on the wing to 20 on the card. Each mark
/// is one or more parts, and each part has a tone the view colours: a rain
/// cloud is a pale cloud with blue drops, not a blue cloud. Where one part
/// sits in front of another, a thin gap is cut round the front one, so the two
/// stay two shapes at 13 pt instead of merging into a blot.
///
/// Every mark stays inside its rect: a shape that leaks past it at 13 pt is
/// clipped by a wing without a word. SwiftUI and CoreGraphics only.
enum Marks {
    /// Which colour a part is drawn in. The view decides what each means on
    /// its surface.
    enum Tone: Sendable {
        case warm
        case rain
        case primary
        case secondary
        case tertiary
    }

    struct Part: Sendable {
        let tone: Tone
        let path: @Sendable (CGRect) -> CGPath
    }

    /// The parts of a mark, back to front. By night the sun is a moon.
    static func parts(_ mark: WeatherCode.Mark, isDay: Bool) -> [Part] {
        switch mark {
        case .sun:
            return isDay ? [Part(tone: .warm, path: sun)] : [Part(tone: .secondary, path: moon)]
        case .partlyCloudy:
            let behind: @Sendable (CGRect) -> CGPath = isDay ? sunBehindCloud : moonBehindCloud
            return [Part(tone: isDay ? .warm : .secondary, path: behind),
                    Part(tone: .secondary, path: frontCloud)]
        case .cloud:
            return [Part(tone: .secondary, path: cloud)]
        case .fog:
            return [Part(tone: .tertiary, path: fog)]
        case .rain:
            return [Part(tone: .secondary, path: highCloud), Part(tone: .rain, path: drops)]
        case .snow:
            return [Part(tone: .secondary, path: highCloud), Part(tone: .primary, path: flakes)]
        case .storm:
            return [Part(tone: .secondary, path: stormCloud), Part(tone: .warm, path: bolt)]
        }
    }

    /// A mark as one path, every part together, for the places that measure
    /// a mark rather than draw it (the tests).
    static func path(_ mark: WeatherCode.Mark, in rect: CGRect, isDay: Bool = true) -> Path {
        let whole = parts(mark, isDay: isDay).map { $0.path(rect) }
            .reduce(CGMutablePath() as CGPath) { $0.union($1) }
        return Path(whole)
    }

    // MARK: The pieces, in a unit square scaled to the rect

    /// A point in the rect, from fractions of its side.
    private static func point(_ x: CGFloat, _ y: CGFloat, in r: CGRect) -> CGPoint {
        let side = min(r.width, r.height)
        let origin = CGPoint(x: r.midX - side / 2, y: r.midY - side / 2)
        return CGPoint(x: origin.x + x * side, y: origin.y + y * side)
    }

    /// A sub-rect of the rect, from fractions of its side.
    private static func area(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, in r: CGRect) -> CGRect {
        let side = min(r.width, r.height)
        let origin = point(x, y, in: r)
        return CGRect(x: origin.x, y: origin.y, width: w * side, height: h * side)
    }

    private static func side(_ r: CGRect) -> CGFloat { min(r.width, r.height) }

    /// The gap cut round a part in front, as a fraction of the side.
    private static let gap: CGFloat = 0.065

    /// A disc and eight rays. The rays are round-capped and stop half their
    /// width short of the edge, because a cap drawn to the edge pokes out.
    @Sendable static func sun(_ r: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addPath(sunDisc(r))
        sunRays(r).forEach { path.addPath($0) }
        return path
    }

    private static func sunDisc(_ r: CGRect) -> CGPath {
        let centre = point(0.5, 0.5, in: r), disc = 0.205 * side(r)
        return CGPath(ellipseIn: CGRect(x: centre.x - disc, y: centre.y - disc, width: disc * 2, height: disc * 2),
                      transform: nil)
    }

    /// The eight rays, each its own path, so one the cloud would cut can be
    /// left out whole rather than drawn as a stub.
    private static func sunRays(_ r: CGRect) -> [CGPath] {
        let s = side(r), centre = point(0.5, 0.5, in: r)
        let width = 0.088 * s
        let inner = 0.315 * s, outer = 0.5 * s - width / 2
        return (0 ..< 8).map { step in
            let angle = Double(step) * .pi / 4
            let ray = CGMutablePath()
            ray.move(to: CGPoint(x: centre.x + cos(angle) * inner, y: centre.y + sin(angle) * inner))
            ray.addLine(to: CGPoint(x: centre.x + cos(angle) * outer, y: centre.y + sin(angle) * outer))
            return ray.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 1)
        }
    }

    /// A crescent: a disc with a smaller one taken out of its upper right.
    @Sendable static func moon(_ r: CGRect) -> CGPath {
        let body = CGPath(ellipseIn: area(0.10, 0.12, 0.76, 0.76, in: r), transform: nil)
        let bite = CGPath(ellipseIn: area(0.36, 0.02, 0.60, 0.60, in: r), transform: nil)
        return body.subtracting(bite)
    }

    /// The cloud: a capsule for its base and two bumps, merged into one
    /// outline so no seam shows where they meet.
    static func cloudShape(in r: CGRect) -> CGPath {
        let base = CGPath(roundedRect: area(0.05, 0.50, 0.90, 0.30, in: r),
                          cornerWidth: 0.15 * side(r), cornerHeight: 0.15 * side(r), transform: nil)
        let left = CGPath(ellipseIn: area(0.15, 0.34, 0.36, 0.36, in: r), transform: nil)
        let crown = CGPath(ellipseIn: area(0.34, 0.19, 0.48, 0.48, in: r), transform: nil)
        return base.union(left).union(crown)
    }

    @Sendable static func cloud(_ r: CGRect) -> CGPath { cloudShape(in: r) }

    /// The cloud raised and narrowed, to leave room under it for rain or snow.
    private static func raisedCloudRect(_ r: CGRect) -> CGRect { area(0.02, -0.11, 0.96, 0.86, in: r) }

    @Sendable static func highCloud(_ r: CGRect) -> CGPath { cloudShape(in: raisedCloudRect(r)) }

    /// Three drops, short and slanted, falling to the left.
    @Sendable static func drops(_ r: CGRect) -> CGPath {
        let lines = CGMutablePath()
        for x in [0.33, 0.52, 0.71] as [CGFloat] {
            lines.move(to: point(x + 0.035, 0.67, in: r))
            lines.addLine(to: point(x - 0.035, 0.895, in: r))
        }
        return lines.copy(strokingWithWidth: 0.088 * side(r), lineCap: .round, lineJoin: .round, miterLimit: 1)
    }

    /// Three round flakes, staggered as if falling: a six-armed flake at
    /// 13 pt is a smudge.
    @Sendable static func flakes(_ r: CGRect) -> CGPath {
        let path = CGMutablePath()
        let radius: CGFloat = 0.058
        for (x, y) in [(0.31, 0.75), (0.51, 0.87), (0.71, 0.75)] as [(CGFloat, CGFloat)] {
            path.addEllipse(in: area(x - radius, y - radius, 2 * radius, 2 * radius, in: r))
        }
        return path
    }

    /// Three bars, staggered, the way weather has drawn fog since the
    /// barometer.
    @Sendable static func fog(_ r: CGRect) -> CGPath {
        let lines = CGMutablePath()
        for (y, from, to) in [(0.30, 0.10, 0.78), (0.50, 0.22, 0.90), (0.70, 0.10, 0.70)] as [(CGFloat, CGFloat, CGFloat)] {
            lines.move(to: point(from, y, in: r))
            lines.addLine(to: point(to, y, in: r))
        }
        return lines.copy(strokingWithWidth: 0.12 * side(r), lineCap: .round, lineJoin: .round, miterLimit: 1)
    }

    /// A lightning bolt coming out of the bottom of a cloud.
    @Sendable static func bolt(_ r: CGRect) -> CGPath {
        let path = CGMutablePath()
        // Its top just meets the cloud's underside, so the gap cut round it
        // takes a bite out of the cloud and leaves no loose sliver beside it.
        let corners: [(CGFloat, CGFloat)] = [
            (0.555, 0.53), (0.705, 0.53), (0.615, 0.665), (0.725, 0.665),
            (0.455, 0.955), (0.535, 0.745), (0.425, 0.745),
        ]
        path.addLines(between: corners.map { point($0.0, $0.1, in: r) })
        path.closeSubpath()
        return path
    }

    /// The storm's cloud, with a gap cut round the bolt in front of it.
    @Sendable static func stormCloud(_ r: CGRect) -> CGPath {
        cloudShape(in: raisedCloudRect(r)).subtracting(clearance(bolt(r), in: r))
    }

    /// Partly cloudy: the cloud low and to the left, in front.
    private static func frontCloudRect(_ r: CGRect) -> CGRect { area(-0.02, 0.21, 0.86, 0.86, in: r) }

    @Sendable static func frontCloud(_ r: CGRect) -> CGPath { cloudShape(in: frontCloudRect(r)) }

    /// A smaller sun up and to the right, behind the cloud, with a gap cut
    /// round the cloud so the two do not merge.
    @Sendable static func sunBehindCloud(_ r: CGRect) -> CGPath {
        let sunRect = area(0.37, 0.0, 0.63, 0.63, in: r)
        let cut = clearance(frontCloud(r), in: r)
        let path = CGMutablePath()
        path.addPath(sunDisc(sunRect).subtracting(cut))
        // A ray the cloud would cut is left out: a stub past the cloud's edge
        // reads as a stray dash.
        for ray in sunRays(sunRect) where !ray.intersects(cut) {
            path.addPath(ray)
        }
        return path
    }

    @Sendable static func moonBehindCloud(_ r: CGRect) -> CGPath {
        moon(area(0.40, 0.0, 0.60, 0.60, in: r)).subtracting(clearance(frontCloud(r), in: r))
    }

    /// A part and the gap round it, which is what is cut out of whatever is
    /// behind it.
    private static func clearance(_ front: CGPath, in r: CGRect) -> CGPath {
        front.union(front.copy(strokingWithWidth: 2 * gap * side(r), lineCap: .round, lineJoin: .round, miterLimit: 1))
    }
}

/// One part of a mark as a SwiftUI shape.
///
/// The parts are built with path arithmetic (unions, a gap cut round the part
/// in front, a ray dropped when the cloud would cut it), which is too much work
/// to repeat every time the host lays the wing out. Each part is built once
/// and kept; drawing it at any size is a scale and a move.
struct MarkPart: Shape {
    let mark: WeatherCode.Mark
    let isDay: Bool
    let index: Int

    func path(in rect: CGRect) -> Path {
        let built = MarkCache.parts(mark, isDay: isDay)[index]
        let side = min(rect.width, rect.height)
        let scale = side / MarkCache.canvas
        var place = CGAffineTransform(translationX: rect.midX - side / 2, y: rect.midY - side / 2)
            .scaledBy(x: scale, y: scale)
        return Path(built.copy(using: &place) ?? built)
    }
}

/// Every mark's parts, built once on a 1000 point canvas: Core Graphics
/// flattens round caps and curves to a fixed precision in absolute units, so
/// a part stroked in a one-point square comes out visibly smaller.
enum MarkCache {
    static let canvas: CGFloat = 1000
    private static let lock = NSLock()
    nonisolated(unsafe) private static var built: [String: [CGPath]] = [:]

    static func parts(_ mark: WeatherCode.Mark, isDay: Bool) -> [CGPath] {
        let key = "\(mark)-\(isDay)"
        return lock.withLock {
            if let parts = built[key] { return parts }
            let square = CGRect(x: 0, y: 0, width: canvas, height: canvas)
            let parts = Marks.parts(mark, isDay: isDay).map { $0.path(square) }
            built[key] = parts
            return parts
        }
    }
}

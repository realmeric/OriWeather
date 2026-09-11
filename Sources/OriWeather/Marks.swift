import SwiftUI

/// The six weather marks, drawn rather than shipped.
///
/// OriNotch's glyphs, carried over as this droplet's own shapes. Every one is a
/// `Shape` in a unit square, asked for at the size it is drawn at and never
/// scaled from a bitmap, and every one stays inside its rect: a shape that
/// leaks past it at 13 pt is clipped by a wing without a word.
///
/// SwiftUI and nothing else, so `scripts/make-icon.swift` compiles this file
/// with its own and the icon is drawn from the same shapes as the wing.
enum Marks {
    /// A disc with eight rays. The rays stop short of the edge by half their
    /// own width, because a round cap drawn to the edge pokes out of it.
    struct Sun: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let side = min(rect.width, rect.height)
            let centre = CGPoint(x: rect.midX, y: rect.midY)
            let core = side * 0.22
            path.addEllipse(in: CGRect(x: centre.x - core, y: centre.y - core,
                                       width: core * 2, height: core * 2))
            let width = core * 0.55
            let inner = core * 1.6
            let outer = side * 0.5 - width / 2
            for step in 0 ..< 8 {
                let angle = Double(step) * .pi / 4
                var ray = Path()
                ray.move(to: CGPoint(x: centre.x + cos(angle) * inner,
                                     y: centre.y + sin(angle) * inner))
                ray.addLine(to: CGPoint(x: centre.x + cos(angle) * outer,
                                        y: centre.y + sin(angle) * outer))
                path.addPath(ray.strokedPath(StrokeStyle(lineWidth: width, lineCap: .round)))
            }
            return path
        }
    }

    /// Three lumps on a flat bottom, which is the shortest way to say cloud at
    /// sixteen points.
    struct Cloud: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let base = rect.minY + rect.height * 0.78
            path.addEllipse(in: CGRect(x: rect.minX, y: base - rect.height * 0.42,
                                       width: rect.width * 0.46, height: rect.height * 0.46))
            path.addEllipse(in: CGRect(x: rect.midX - rect.width * 0.28,
                                       y: rect.minY + rect.height * 0.1,
                                       width: rect.width * 0.56, height: rect.height * 0.56))
            path.addEllipse(in: CGRect(x: rect.maxX - rect.width * 0.5,
                                       y: base - rect.height * 0.38,
                                       width: rect.width * 0.5, height: rect.height * 0.38))
            path.addRect(CGRect(x: rect.minX + rect.width * 0.1, y: base - rect.height * 0.2,
                                width: rect.width * 0.8, height: rect.height * 0.2))
            return path
        }
    }

    /// A cloud with three strokes of rain under it.
    struct Rain: Shape {
        func path(in rect: CGRect) -> Path {
            let cloud = CGRect(x: rect.minX, y: rect.minY,
                               width: rect.width, height: rect.height * 0.68)
            var path = Cloud().path(in: cloud)
            let width = rect.width * 0.07
            for step in 0 ..< 3 {
                let x = rect.minX + rect.width * (0.24 + Double(step) * 0.26)
                path.addRoundedRect(
                    in: CGRect(x: x, y: rect.maxY - rect.height * 0.28,
                               width: width, height: rect.height * 0.26),
                    cornerSize: CGSize(width: width / 2, height: width / 2)
                )
            }
            return path
        }
    }

    /// A cloud with three flakes under it, round rather than starred: a
    /// six-armed flake at sixteen points is a smudge.
    struct Snow: Shape {
        func path(in rect: CGRect) -> Path {
            let cloud = CGRect(x: rect.minX, y: rect.minY,
                               width: rect.width, height: rect.height * 0.68)
            var path = Cloud().path(in: cloud)
            let size = rect.width * 0.13
            for step in 0 ..< 3 {
                let x = rect.minX + rect.width * (0.22 + Double(step) * 0.26)
                path.addEllipse(in: CGRect(x: x, y: rect.maxY - rect.height * 0.22,
                                           width: size, height: size))
            }
            return path
        }
    }

    /// Three bars, the middle one shorter, which is how weather has drawn fog
    /// since the barometer.
    struct Fog: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let bar = rect.height * 0.14
            let widths = [1.0, 0.72, 0.9]
            for (index, width) in widths.enumerated() {
                let y = rect.minY + rect.height * (0.18 + Double(index) * 0.3)
                path.addRoundedRect(
                    in: CGRect(x: rect.minX, y: y, width: rect.width * width, height: bar),
                    cornerSize: CGSize(width: bar / 2, height: bar / 2)
                )
            }
            return path
        }
    }

    /// A lightning bolt: a storm.
    struct Bolt: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let body = rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.04)
            path.move(to: CGPoint(x: body.maxX - body.width * 0.1, y: body.minY))
            path.addLine(to: CGPoint(x: body.minX + body.width * 0.05, y: body.midY + body.height * 0.08))
            path.addLine(to: CGPoint(x: body.midX + body.width * 0.04, y: body.midY + body.height * 0.08))
            path.addLine(to: CGPoint(x: body.minX + body.width * 0.28, y: body.maxY))
            path.addLine(to: CGPoint(x: body.maxX - body.width * 0.05, y: body.midY - body.height * 0.08))
            path.addLine(to: CGPoint(x: body.midX - body.width * 0.02, y: body.midY - body.height * 0.08))
            path.closeSubpath()
            return path
        }
    }

    /// The shape for a mark, as a path in a rect, for the places that draw one
    /// outside a view (the tests, the icon script).
    static func path(_ mark: WeatherCode.Mark, in rect: CGRect) -> Path {
        switch mark {
        case .sun: Sun().path(in: rect)
        case .cloud: Cloud().path(in: rect)
        case .rain: Rain().path(in: rect)
        case .snow: Snow().path(in: rect)
        case .fog: Fog().path(in: rect)
        case .storm: Bolt().path(in: rect)
        }
    }
}

import Combine
import DroppyKit
import SwiftUI

// MARK: - Live activity

extension OriWeatherDroplet: LiveActivityProviding {
    public var liveActivityState: AnyPublisher<LiveActivityState?, Never> {
        activitySubject.eraseToAnyPublisher()
    }

    /// Where the clock lives: seated it runs, unseated it stops and the last
    /// reading stays. Losing the seat is normal, not an error.
    public func liveActivitySeatDidChange(_ seat: DropletLiveActivitySeat) {
        seatChanged(seat)
    }

    /// The mark, on the leading wing. No padding of its own: the host insets
    /// the wing by `symmetricPadding` already.
    public func makeCompactLeading() -> AnyView {
        AnyView(WingMark(droplet: self))
    }

    /// The degrees, on the trailing wing.
    public func makeCompactTrailing() -> AnyView {
        AnyView(WingDegrees(droplet: self))
    }

    public func makeExpanded(context: LiveActivityContext) -> AnyView {
        AnyView(Color.clear.frame(width: context.availableWidth,
                                  height: DroppyLiveActivityMetrics.cardContentHeight))
    }
}

/// The mark at the wing's glyph size.
struct WingMark: View {
    @ObservedObject var droplet: OriWeatherDroplet

    var body: some View {
        if let glance = droplet.glance {
            WeatherMark(code: glance.reading.code, isDay: glance.reading.isDay)
                .frame(width: DroppyLiveActivityMetrics.iconSize,
                       height: DroppyLiveActivityMetrics.iconSize)
                .accessibilityHidden(true)
        }
    }
}

/// The degrees at the wing's label size, in plain SF as OriNotch draws them,
/// with monospaced digits so the wing does not jitter when the figure moves.
struct WingDegrees: View {
    @ObservedObject var droplet: OriWeatherDroplet

    var body: some View {
        if let glance = droplet.glance {
            WingFigure(text: glance.degrees)
        }
    }
}

struct WingFigure: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
            .lineLimit(1)
            .fixedSize()
    }
}

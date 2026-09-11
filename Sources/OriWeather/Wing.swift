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

    /// The mark alone in the companion pill, sized to the slot the host
    /// resolved rather than to the wing's glyph: the default reuses the
    /// leading accessory, and a 13 pt sun in a 24 pt puck is a dot.
    public func makeCompanionCompact(context: CompactLiveActivityContext) -> AnyView {
        AnyView(CompanionMark(droplet: self, slot: context.slotSize))
    }

    /// One line beside the mark when the pill grows into its capsule.
    public func makeCompanionDetail(context: LiveActivityContext) -> AnyView? {
        AnyView(CompanionDetail(droplet: self))
    }

    /// The card the row grows into on hover.
    public func makeExpanded(context: LiveActivityContext) -> AnyView {
        AnyView(ExpandedCard(droplet: self, context: context))
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

/// The mark, filling the companion pill's round slot.
struct CompanionMark: View {
    @ObservedObject var droplet: OriWeatherDroplet
    let slot: CGSize

    var body: some View {
        if let glance = droplet.glance {
            let side = min(slot.width, slot.height)
            WeatherMark(code: glance.reading.code, isDay: glance.reading.isDay)
                .frame(width: side, height: side)
                .frame(width: slot.width, height: slot.height)
                .accessibilityHidden(true)
        }
    }
}

/// "26° Partly cloudy", laid out leading beside the companion mark.
struct CompanionDetail: View {
    @ObservedObject var droplet: OriWeatherDroplet

    var body: some View {
        if let glance = droplet.glance {
            HStack(spacing: DroppyLiveActivityMetrics.contentSpacing) {
                Text(verbatim: glance.degrees)
                    .monospacedDigit()
                    .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                Text(verbatim: glance.detail)
                    .foregroundStyle(AdaptiveColors.notchSurfaceSecondaryText)
            }
            .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

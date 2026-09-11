import DroppyKit
import SwiftUI

/// The card the wing grows into on hover: the mark, the degrees large with the
/// condition under them, and the city with what it feels like on the right.
///
/// Exactly `availableWidth` by `cardContentHeight` and not a point taller,
/// because a taller view is clipped without a word. Nothing avoids the camera
/// housing: the host has already inset the card below it.
struct ExpandedCard: View {
    @ObservedObject var droplet: OriWeatherDroplet
    let context: LiveActivityContext
    /// What was on the card when the host's spring started. Nothing rebuilds
    /// while the presentation is still moving (D6).
    @State private var held: Glance?

    private var isSettled: Bool { context.presentation.isPresentationSettled }

    var body: some View {
        Group {
            if let glance = isSettled ? droplet.glance : (held ?? droplet.glance) {
                WeatherCardContent(glance: glance)
            }
        }
        .frame(width: context.availableWidth, height: DroppyLiveActivityMetrics.cardContentHeight)
        .onAppear { held = droplet.glance }
        .onChange(of: droplet.glance) { _, glance in
            if isSettled { held = glance }
        }
    }
}

/// The card's composition, from one glance.
struct WeatherCardContent: View {
    let glance: Glance

    var body: some View {
        HStack(spacing: DroppySpacing.sm) {
            WeatherMark(code: glance.reading.code, isDay: glance.reading.isDay)
                .frame(width: Look.cardMark, height: Look.cardMark)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: glance.degrees)
                    .font(.system(size: Look.cardFigure, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                Text(verbatim: glance.detail)
                    .font(.system(size: DroppyLiveActivityMetrics.labelFontSize))
                    .foregroundStyle(AdaptiveColors.notchSurfaceTertiaryText)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text(verbatim: glance.city.name)
                    .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
                    .foregroundStyle(AdaptiveColors.notchSurfaceSecondaryText)
                Text(verbatim: "Feels like \(glance.feelsLike)")
                    .font(.system(size: DroppyLiveActivityMetrics.labelFontSize))
                    .monospacedDigit()
                    .foregroundStyle(AdaptiveColors.notchSurfaceTertiaryText)
            }
        }
        .lineLimit(1)
        // Dimmed rather than hidden: an old temperature with its age on it is
        // worth more than an empty card.
        .opacity(glance.isStale ? Look.staleOpacity : 1)
        .accessibilityElement(children: .combine)
    }
}

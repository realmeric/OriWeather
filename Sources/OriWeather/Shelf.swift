import Combine
import DroppyKit
import SwiftUI

// MARK: - Shelf widget

extension OriWeatherDroplet: ShelfWidgetProviding {
    static let widgetID: ShelfWidgetID = "weather"

    public var widgetDescriptors: [ShelfWidgetDescriptor] {
        [
            ShelfWidgetDescriptor(
                id: Self.widgetID,
                title: "Weather",
                systemImage: "cloud.sun.fill",
                layoutTraits: ShelfWidgetLayoutTraits(
                    preferredSoloWidth: Look.shelfSoloWidth,
                    preferredPairedWidth: Look.shelfPairedWidth,
                    contentHeight: .fixed(Look.shelfHeight)
                ),
                searchKeywords: ["weather", "temperature", "forecast", "city"]
            )
        ]
    }

    public func makeWidgetView(_ id: ShelfWidgetID, context: ShelfWidgetContext) -> AnyView {
        AnyView(WeatherWidget(droplet: self, context: context))
    }

    public func makeWidgetSettingsPopover(_ id: ShelfWidgetID) -> AnyView? { nil }
}

/// The weather on the shelf. Solo and paired are different compositions, not
/// one view at two widths, and the switch is `isCompact`. No background: the
/// shelf paints the card.
struct WeatherWidget: View {
    @ObservedObject var droplet: OriWeatherDroplet
    let context: ShelfWidgetContext

    var body: some View {
        Group {
            if let glance = droplet.glance {
                if context.isCompact {
                    PairedWeather(glance: glance)
                } else {
                    SoloWeather(glance: glance)
                }
            } else {
                Text(verbatim: "Choose a city in the droplet's settings.")
                    .font(.system(size: DroppyLiveActivityMetrics.labelFontSize))
                    .foregroundStyle(AdaptiveColors.notchSurfaceTertiaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .padding(DroppySpacing.mdl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Alone on the shelf: the mark, the degrees, the condition, the city, what it
/// feels like, and how old the reading is on a line of its own.
private struct SoloWeather: View {
    let glance: Glance

    var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.sm) {
            HStack(alignment: .center, spacing: DroppySpacing.md) {
                WeatherMark(code: glance.reading.code, isDay: glance.reading.isDay)
                    .frame(width: Look.shelfMark, height: Look.shelfMark)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: glance.degrees)
                        .font(.system(size: Look.shelfFigure, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
                    Text(verbatim: glance.condition)
                        .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
                        .foregroundStyle(AdaptiveColors.notchSurfaceSecondaryText)
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
            Spacer(minLength: 0)
            Text(verbatim: glance.age)
                .font(.system(size: DroppyLiveActivityMetrics.labelFontSize))
                .foregroundStyle(AdaptiveColors.notchSurfaceTertiaryText)
        }
        .lineLimit(1)
        .opacity(glance.isStale ? Look.staleOpacity : 1)
        .accessibilityElement(children: .combine)
    }
}

/// Beside another widget: the mark and the degrees, and the condition under
/// them when the slot is tall enough for one more line.
private struct PairedWeather: View {
    let glance: Glance

    var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            HStack(spacing: DroppySpacing.sm) {
                WeatherMark(code: glance.reading.code, isDay: glance.reading.isDay)
                    .frame(width: Look.shelfMark, height: Look.shelfMark)
                    .accessibilityHidden(true)
                Text(verbatim: glance.degrees)
                    .font(.system(size: Look.shelfFigure, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(AdaptiveColors.notchSurfacePrimaryText)
            }
            ViewThatFits(in: .vertical) {
                Text(verbatim: glance.detail)
                    .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
                    .foregroundStyle(AdaptiveColors.notchSurfaceSecondaryText)
                EmptyView()
            }
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .opacity(glance.isStale ? Look.staleOpacity : 1)
        .accessibilityElement(children: .combine)
    }
}

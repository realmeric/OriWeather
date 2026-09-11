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
    /// The user's Widget Text colour, when the host hands one down. Read from
    /// the SDK's own key: a local key of the same name would never receive it.
    @Environment(\.dropletShelfWidgetTextColor) private var textColor

    private var ink: WeatherInk {
        .shelf(textColor: textColor, adaptive: context.usesAdaptiveForegrounds)
    }

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
                    .foregroundStyle(ink.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .padding(DroppySpacing.mdl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.weatherInk, ink)
    }
}

/// Alone on the shelf: the reading across the top (the mark and the degrees
/// large, the condition and what it feels like beside them, the city and
/// today's high and low on the right) and the hours ahead under it. No age on
/// a fresh reading; a stale one says its age where the condition was.
private struct SoloWeather: View {
    let glance: Glance
    @Environment(\.weatherInk) private var ink

    var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.smd) {
            HStack(alignment: .center, spacing: DroppySpacing.md) {
                WeatherMark(code: glance.reading.code, isDay: glance.reading.isDay)
                    .frame(width: Look.shelfMark, height: Look.shelfMark)
                    .accessibilityHidden(true)
                Text(verbatim: glance.degrees)
                    .font(.system(size: Look.shelfFigure, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(ink.primary)
                    .fixedSize()
                VStack(alignment: .leading, spacing: DroppySpacing.xs / 2) {
                    Text(verbatim: glance.detail)
                        .font(.system(size: Look.shelfLabel, weight: .medium))
                        .foregroundStyle(ink.secondary)
                    Text(verbatim: "Feels like \(glance.feelsLike)")
                        .font(.system(size: DroppyLiveActivityMetrics.labelFontSize))
                        .monospacedDigit()
                        .foregroundStyle(ink.tertiary)
                }
                .layoutPriority(1)
                Spacer(minLength: DroppySpacing.sm)
                VStack(alignment: .trailing, spacing: DroppySpacing.xs / 2) {
                    Text(verbatim: glance.city.name)
                        .font(.system(size: Look.shelfLabel, weight: .medium))
                        .foregroundStyle(ink.secondary)
                    if let highLow = glance.highLow {
                        Text(verbatim: highLow)
                            .font(.system(size: DroppyLiveActivityMetrics.labelFontSize))
                            .monospacedDigit()
                            .foregroundStyle(ink.tertiary)
                    }
                }
            }
            .lineLimit(1)
            if !glance.hours.isEmpty {
                HourStrip(hours: glance.hours)
            }
            Spacer(minLength: 0)
        }
        .opacity(glance.isStale ? Look.staleOpacity : 1)
        .accessibilityElement(children: .combine)
    }
}

/// The hours ahead, evenly across the width: the hour, its mark, its degrees.
private struct HourStrip: View {
    let hours: [HourGlance]
    @Environment(\.weatherInk) private var ink

    var body: some View {
        HStack(spacing: 0) {
            ForEach(hours) { hour in
                VStack(spacing: DroppySpacing.xs) {
                    Text(verbatim: hour.label)
                        .font(.system(size: Look.hourLabel, weight: .medium))
                        .foregroundStyle(ink.tertiary)
                    WeatherMark(code: hour.code, isDay: hour.isDay)
                        .frame(width: Look.hourMark, height: Look.hourMark)
                        .accessibilityHidden(true)
                    Text(verbatim: hour.degrees)
                        .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(ink.primary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .lineLimit(1)
    }
}

/// Beside another widget: the mark and the degrees, the condition under them,
/// and at the foot the city and today's high and low when the slot is tall
/// enough for them.
private struct PairedWeather: View {
    let glance: Glance
    @Environment(\.weatherInk) private var ink

    var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            HStack(spacing: DroppySpacing.sm) {
                WeatherMark(code: glance.reading.code, isDay: glance.reading.isDay)
                    .frame(width: Look.pairedMark, height: Look.pairedMark)
                    .accessibilityHidden(true)
                Text(verbatim: glance.degrees)
                    .font(.system(size: Look.pairedFigure, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(ink.primary)
            }
            Text(verbatim: glance.detail)
                .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
                .foregroundStyle(ink.secondary)
            Spacer(minLength: 0)
            ViewThatFits(in: .vertical) {
                VStack(alignment: .leading, spacing: DroppySpacing.xs / 2) {
                    Text(verbatim: glance.city.name)
                        .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
                        .foregroundStyle(ink.secondary)
                    if let highLow = glance.highLow {
                        Text(verbatim: highLow)
                            .font(.system(size: DroppyLiveActivityMetrics.labelFontSize))
                            .monospacedDigit()
                            .foregroundStyle(ink.tertiary)
                    }
                }
                EmptyView()
            }
        }
        .lineLimit(1)
        .opacity(glance.isStale ? Look.staleOpacity : 1)
        .accessibilityElement(children: .combine)
    }
}

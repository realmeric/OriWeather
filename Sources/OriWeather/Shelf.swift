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
/// one view at two widths, and the switch is `isCompact`. No background:
/// Droppy paints nothing behind a widget. The one padding is the host's own
/// for the slot, which is zero under a notch, where the shelf's chrome has
/// already inset the rectangle (`Look.widgetInset`).
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
        .padding(Look.widgetInset(onIsland: context.usesIslandCurvature))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.weatherInk, ink)
    }
}

/// The header every Droppy widget opens with: a 12 pt symbol and a 12 pt
/// title in the secondary white, here the city. Nothing trails it: a figure
/// at its end would sit in the top corner's curve.
private struct WeatherHeader: View {
    let glance: Glance
    @Environment(\.weatherInk) private var ink

    var body: some View {
        HStack(spacing: DroppySpacing.xsm) {
            Image(systemName: "mappin")
                .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
                .accessibilityHidden(true)
            Text(verbatim: glance.city.name)
                .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .semibold))
        }
        .lineLimit(1)
        .frame(height: Look.headerHeight)
        .foregroundStyle(ink.secondary)
    }
}

/// Alone on the shelf: the header, the reading (the mark and the degrees
/// large, the condition and what it feels like beside them, today's high and
/// low trailing) and the hours ahead under it. A fresh reading carries no
/// age; a stale one says its age where the condition was.
private struct SoloWeather: View {
    let glance: Glance
    @Environment(\.weatherInk) private var ink

    var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.sm) {
            WeatherHeader(glance: glance)
            HStack(alignment: .center, spacing: DroppySpacing.md) {
                WeatherMark(code: glance.reading.code, isDay: glance.reading.isDay)
                    .frame(width: Look.shelfMark, height: Look.shelfMark)
                    .accessibilityHidden(true)
                Text(verbatim: glance.degrees)
                    .font(.system(size: Look.shelfFigure, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(ink.primary)
                    .fixedSize()
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: glance.detail)
                        .font(.system(size: Look.shelfLabel, weight: .medium))
                        .foregroundStyle(ink.secondary)
                    Text(verbatim: "Feels like \(glance.feelsLike)")
                        .font(.system(size: DroppyLiveActivityMetrics.labelFontSize))
                        .monospacedDigit()
                        .foregroundStyle(ink.tertiary)
                }
                .lineLimit(1)
                Spacer(minLength: 0)
                if let highLow = glance.highLow {
                    Text(verbatim: highLow)
                        .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(ink.secondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            if !glance.hours.isEmpty {
                // Down to the bottom edge, with no gap of its own: what the
                // height leaves over the composition sits above the hours.
                HourStrip(hours: glance.hours)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
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

/// Beside another widget: the header, the mark and the degrees, the
/// condition, and two rows with the label leading and the number trailing:
/// what it feels like, and today's high and low. The rows follow the
/// condition rather than sitting on the bottom edge, where the host's corner
/// clip would cut their first and last letters.
private struct PairedWeather: View {
    let glance: Glance
    @Environment(\.weatherInk) private var ink

    var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.xs) {
            WeatherHeader(glance: glance)
                .padding(.bottom, DroppySpacing.xs)
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
            row("Feels like", glance.feelsLike)
            if let high = glance.high, let low = glance.low {
                row("High / low", "\(high) / \(low)")
            }
        }
        .lineLimit(1)
        .opacity(glance.isStale ? Look.staleOpacity : 1)
        .accessibilityElement(children: .combine)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(verbatim: label)
                .foregroundStyle(ink.tertiary)
            Spacer(minLength: DroppySpacing.md)
            Text(verbatim: value)
                .monospacedDigit()
                .foregroundStyle(ink.primary)
        }
        .font(.system(size: DroppyLiveActivityMetrics.labelFontSize, weight: .medium))
    }
}

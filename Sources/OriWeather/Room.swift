import DroppyKit
import SwiftUI

// MARK: - Settings pane

extension OriWeatherDroplet: SettingsPaneProviding {
    public func makeSettingsPane(context: SettingsPaneContext) -> AnyView {
        AnyView(WeatherRoom(droplet: self))
    }

    public var settingsSearchEntries: [SettingsSearchEntry] {
        [
            SettingsSearchEntry(title: "City", keywords: ["weather", "place", "location", "where"]),
            SettingsSearchEntry(title: "Unit", keywords: ["celsius", "fahrenheit", "degrees", "temperature"]),
            SettingsSearchEntry(title: "Refresh every", keywords: ["interval", "minutes", "update"]),
            SettingsSearchEntry(title: "Keep on the notch", keywords: ["pin", "pinned", "always", "rest"]),
        ]
    }
}

/// The room: a city, a unit, an interval and the pin, built from Droppy's own
/// settings rows so it stays in step with the pages around it.
struct WeatherRoom: View {
    @ObservedObject var droplet: OriWeatherDroplet

    var body: some View {
        VStack(alignment: .leading, spacing: DroppySpacing.lg) {
            if let search = droplet.search {
                CityCard(droplet: droplet, search: search)
            }
            DropletSettingsCard {
                settingsUnifiedPickerRow(
                    title: "Unit",
                    subtitle: "Converted from the one reading, never fetched twice.",
                    options: TemperatureUnit.allCases,
                    groupPosition: .top,
                    isSelected: { $0 == droplet.unit },
                    action: { droplet.unit = $0 }
                ) { unit, selected, enabled in
                    settingsUnifiedSegmentLabel(icon: "thermometer.medium",
                                                title: unit == .celsius ? "Celsius" : "Fahrenheit",
                                                isSelected: selected, isEnabled: enabled)
                }
                settingsUnifiedPickerRow(
                    title: "Refresh every",
                    subtitle: "One reading per interval, and only while the weather is on the notch or the shelf.",
                    options: Preferences.intervals,
                    groupPosition: .middle,
                    isSelected: { $0 == droplet.intervalMinutes },
                    action: { droplet.intervalMinutes = $0 }
                ) { minutes, selected, enabled in
                    settingsUnifiedSegmentLabel(icon: "clock",
                                                title: minutes == 60 ? "1 hour" : "\(minutes) min",
                                                isSelected: selected, isEnabled: enabled)
                }
                DropletToggleRow(
                    title: "Keep on the notch",
                    subtitle: "On, the weather sits on the wings when nothing else wants the notch. Off, it stays on the shelf and leaves the wings alone.",
                    isOn: Binding(get: { droplet.pinned }, set: { droplet.pinned = $0 })
                )
            }
        }
    }
}

/// The city row, and the matches under it. The SDK has no text-field row, so
/// this is the one place the room goes off the components: a plain field in a
/// stacked row, filled rather than outlined.
private struct CityCard: View {
    @ObservedObject var droplet: OriWeatherDroplet
    @ObservedObject var search: CitySearch

    var body: some View {
        DropletSettingsCard {
            DropletStackedRow(
                title: "City",
                infoTip: "The weather is read for a city you name, not for where this Mac is. Open-Meteo is sent the name while you type and a coordinate rounded to about a kilometre."
            ) {
                VStack(alignment: .leading, spacing: DroppySpacing.xs) {
                    TextField("Search for a city", text: $search.query)
                        .textFieldStyle(.plain)
                        .font(.callout)
                        .padding(.horizontal, DroppySpacing.sm)
                        .padding(.vertical, DroppySpacing.xsm)
                        .background(RoundedRectangle(cornerRadius: DroppyRadius.small, style: .continuous)
                            .fill(AdaptiveColors.overlayAuto(DroppyOpacity.light)))
                    Text(verbatim: droplet.chosenCity.map(Self.describe) ?? "No city yet.")
                        .font(.caption)
                        .foregroundStyle(AdaptiveColors.secondaryTextAuto)
                }
            }
            ForEach(search.matches) { city in
                DropletSettingsDivider()
                Button {
                    droplet.choose(city)
                } label: {
                    DropletControlRow(title: Self.title(city)) {
                        if let country = city.country {
                            DropletValuePill(text: country)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    static func title(_ city: City) -> String {
        guard let region = city.region, region != city.name else { return city.name }
        return "\(city.name), \(region)"
    }

    static func describe(_ city: City) -> String {
        [title(city), city.country].compactMap { $0 }.joined(separator: ", ")
    }
}

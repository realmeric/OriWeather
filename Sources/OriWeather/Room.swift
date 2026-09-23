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
            SettingsSearchEntry(title: "Find the city automatically", keywords: ["automatic", "location", "time zone", "travel"]),
            SettingsSearchEntry(title: "Unit", keywords: ["celsius", "fahrenheit", "degrees", "temperature"]),
            SettingsSearchEntry(title: "Refresh every", keywords: ["interval", "minutes", "update"]),
            SettingsSearchEntry(title: "Keep on the notch", keywords: ["pin", "pinned", "always", "rest", "wings"]),
            SettingsSearchEntry(title: "Shortcut", keywords: ["keyboard", "wings", "show", "hide"]),
        ]
    }
}

/// The room: a city, a unit, an interval and the pin, built from Droppy's own
/// settings rows so it stays in step with the pages around it. Rooted in
/// `DropletSettingsPane`, so Droppy mounts it in its grouped Form and every
/// row is the Form's own, separated by the Form rather than by dividers.
struct WeatherRoom: View {
    @ObservedObject var droplet: OriWeatherDroplet

    var body: some View {
        DropletSettingsPane {
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
                if droplet.canUseShortcut {
                    DropletControlRow(
                        title: "Shortcut",
                        infoTip: "Shows or hides the weather on the wings from anywhere. Change it in Droppy's Settings, Shortcuts."
                    ) {
                        DropletValuePill(text: droplet.shortcut.map(WingShortcut.words) ?? "Not set")
                    }
                }
            }
        }
    }
}

/// The city row, and the matches under it. The SDK has no text-field row, so
/// the field is the system's own in a stacked row: the guides keep text fields
/// native, with their border and focus ring.
private struct CityCard: View {
    @ObservedObject var droplet: OriWeatherDroplet
    @ObservedObject var search: CitySearch

    var body: some View {
        DropletSettingsCard {
            DropletToggleRow(
                title: "Find the city automatically",
                subtitle: "From the city this Mac's internet address is in, checked against its time zone, and looked up again on a new network, after sleep and when the zone changes. With a VPN in another country, the time zone's city instead. GeoJS answers, and sees the address and nothing else.",
                isOn: Binding(get: { droplet.automatic }, set: { droplet.automatic = $0 })
            )
            DropletStackedRow(
                title: "City",
                infoTip: "The weather is read for a city you name, not for where this Mac is. Open-Meteo is sent the name while you type and a coordinate rounded to about a kilometre."
            ) {
                VStack(alignment: .leading, spacing: DroppySpacing.xs) {
                    // Labelled by the row's title: in a Form a field's own
                    // label would sit beside it, and the prompt goes inside.
                    TextField("City", text: $search.query, prompt: Text(verbatim: "Search for a city"))
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                    Text(verbatim: caption)
                        .font(.caption)
                        .foregroundStyle(AdaptiveColors.secondaryTextAuto)
                }
            }
            ForEach(search.matches) { city in
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

    private var caption: String {
        guard let city = droplet.chosenCity else {
            return droplet.automatic ? "Looking for the city." : "No city yet."
        }
        return Self.describe(city) + (droplet.automatic ? ", found automatically" : "")
    }

    static func title(_ city: City) -> String {
        guard let region = city.region, region != city.name else { return city.name }
        return "\(city.name), \(region)"
    }

    static func describe(_ city: City) -> String {
        [title(city), city.country].compactMap { $0 }.joined(separator: ", ")
    }
}

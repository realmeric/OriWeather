import DroppyKit
import Foundation

/// What the user chose, stored through the host under `droplet.ori-weather.*`.
///
/// The keys are the whole list of what this droplet writes; nothing else goes
/// into the host's defaults.
@MainActor
struct Preferences {
    enum Key {
        static let city = "city"
        static let automatic = "automatic"
        static let unit = "unit"
        static let intervalMinutes = "intervalMinutes"
        static let pinned = "pinned"
    }

    /// The intervals the room offers. Anything else stored is read as the
    /// default rather than trusted.
    static let intervals = [15, 30, 60]

    let service: any DropletPreferencesService

    /// Stored as JSON, which is what the service does with any `Codable`.
    /// A country stored in the geocoder's long form is read in the short one.
    var city: City? {
        get {
            service.value(forKey: Key.city, as: City.self).map {
                City(name: $0.name, region: $0.region, country: OpenMeteoGeocoder.shortCountry($0.country),
                     place: $0.place, timeZone: $0.timeZone)
            }
        }
        nonmutating set { service.setValue(newValue, forKey: Key.city) }
    }

    /// Whether the city is found from this Mac's time zone. On until the user
    /// names one, and never switched on over a city somebody already chose.
    var automatic: Bool {
        get { service.value(forKey: Key.automatic, as: Bool.self) ?? !service.hasValue(forKey: Key.city) }
        nonmutating set { service.setValue(newValue, forKey: Key.automatic) }
    }

    /// How the degrees are counted. Celsius unless chosen.
    var unit: TemperatureUnit {
        get { service.value(forKey: Key.unit, default: TemperatureUnit.celsius) }
        nonmutating set { service.setValue(newValue, forKey: Key.unit) }
    }

    /// Minutes between readings: 15, 30 or 60, half an hour unless chosen.
    var intervalMinutes: Int {
        get {
            let stored = service.value(forKey: Key.intervalMinutes, default: 30)
            return Self.intervals.contains(stored) ? stored : 30
        }
        nonmutating set { service.setValue(newValue, forKey: Key.intervalMinutes) }
    }

    /// "Keep on the notch". Off by default: the wing is a strong claim on
    /// somebody else's notch, so the user turns it on (D5). The demo sky turns
    /// it on unless told otherwise, because a demo is for looking at the wing.
    func pinned(byDefault fallback: Bool) -> Bool {
        service.value(forKey: Key.pinned, default: fallback)
    }

    func setPinned(_ pinned: Bool) {
        service.setValue(pinned, forKey: Key.pinned)
    }
}


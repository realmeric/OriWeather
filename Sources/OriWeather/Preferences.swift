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
    }

    let service: any DropletPreferencesService

    /// Stored as JSON, which is what the service does with any `Codable`.
    var city: City? {
        get { service.value(forKey: Key.city, as: City.self) }
        nonmutating set { service.setValue(newValue, forKey: Key.city) }
    }
}

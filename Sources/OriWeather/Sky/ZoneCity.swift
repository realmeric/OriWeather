import Foundation

/// The city a time zone is named after, which is how the droplet finds where
/// it is without asking where the Mac is.
///
/// macOS sets the time zone from the Mac's location when "Set time zone
/// automatically" is on, and keeps it right as the Mac travels; the zone's
/// name ends in a city. It is coarse on purpose: one city per zone, so all of
/// Türkiye is Istanbul and all of the US east coast is New York.
enum ZoneCity {
    /// "Europe/Istanbul" is Istanbul and "America/Argentina/Buenos_Aires" is
    /// Buenos Aires. A zone that names no city ("UTC", "Etc/GMT+3") is nil.
    static func name(of zone: String) -> String? {
        let parts = zone.split(separator: "/")
        guard parts.count >= 2, parts.first != "Etc", let last = parts.last else { return nil }
        return last.replacingOccurrences(of: "_", with: " ")
    }

    /// Of the geocoder's matches, the one in the zone itself, so Paris is the
    /// one in Europe/Paris and not the one in Texas; the first when none is.
    static func pick(_ cities: [City], in zone: String) -> City? {
        cities.first { $0.timeZone == zone } ?? cities.first
    }
}

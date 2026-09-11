import Foundation

/// Where this Mac is, to the city, without asking macOS where it is.
///
/// DroppyKit has no location capability, so the droplet does not use
/// CoreLocation. It asks instead which city the Mac's internet address is in,
/// which follows the Mac from city to city the way a time zone cannot (Ankara
/// and Istanbul share one), and checks the answer against the time zone,
/// because a VPN puts the address in the VPN's city. The server that answers
/// sees the address and nothing else; Open-Meteo already sees the same one.
protocol Locating: Sendable {
    func locate() async throws -> City
}

/// GeoJS: free, no key, no account, and it keeps nothing it is asked.
struct GeoJS: Locating {
    static let url = URL(string: "https://get.geojs.io/v1/ip/geo.json")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func locate() async throws -> City {
        let (data, response) = try await session.data(from: Self.url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.refused
        }
        return try Self.city(from: data)
    }

    /// The answer keeps the city, the region, the country, the coordinate and
    /// the zone, and nothing else: not the address, not the network's owner.
    /// The coordinate arrives as text and leaves rounded to two decimals, as
    /// every coordinate here does.
    static func city(from data: Data) throws -> City {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["city"] as? String, !name.isEmpty,
              let latitude = number(json["latitude"]),
              let longitude = number(json["longitude"])
        else { throw WeatherError.nowhere }
        return City(name: name,
                    region: json["region"] as? String,
                    country: OpenMeteoGeocoder.countryName(code: json["country_code"] as? String)
                        ?? json["country"] as? String,
                    place: Place(latitude: latitude, longitude: longitude),
                    timeZone: json["timezone"] as? String)
    }

    private static func number(_ value: Any?) -> Double? {
        if let text = value as? String { return Double(text) }
        return (value as? NSNumber)?.doubleValue
    }
}

/// Where the address says, checked against the zone. The address wins when
/// it is in the Mac's own zone; otherwise (a VPN abroad, or no answer) the
/// zone's own city does.
enum Whereabouts {
    static func choose(address: City?, zone: String) -> City? {
        guard let address, address.timeZone == nil || address.timeZone == zone else { return nil }
        return address
    }

    /// Two answers for the same town are the same city, however the
    /// coordinate moved between them, so a second lookup does not read the
    /// weather again for a place the Mac never left.
    static func isSameTown(_ one: City?, _ other: City) -> Bool {
        guard let one else { return false }
        return one.name == other.name && one.region == other.region && one.country == other.country
    }
}

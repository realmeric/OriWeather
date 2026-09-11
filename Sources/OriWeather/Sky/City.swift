import Foundation

/// A place with a name, chosen by the user, which is where the weather is read.
///
/// A city rather than a location (D4): DroppyKit has no location capability,
/// and CoreLocation in a droplet is a symbol with nothing to declare it under.
struct City: Equatable, Codable, Sendable, Identifiable {
    let name: String
    /// The state or province, `admin1` in the geocoder's answer.
    let region: String?
    let country: String?
    /// Rounded to two decimals when it is read, so nothing finer is ever held.
    let place: Place
    /// The city's own zone, which an age is not measured in (an age is a
    /// duration) and a future hourly row would be labelled in.
    let timeZone: String?

    var id: String { "\(name)|\(place.latitude)|\(place.longitude)" }

    init(name: String, region: String?, country: String?, place: Place, timeZone: String?) {
        self.name = name
        self.region = region
        self.country = country
        self.place = place.rounded
        self.timeZone = timeZone
    }
}

/// Where a city's name is turned into a coordinate. Open-Meteo's geocoder in
/// the droplet, a recorded answer in the tests.
protocol Geocoding: Sendable {
    func cities(named name: String) async throws -> [City]
}

/// Open-Meteo's geocoder: no key, no account, the same people as the forecast.
struct OpenMeteoGeocoder: Geocoding {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    static func url(for name: String) -> URL? {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: name),
            // Ten asked for, five kept: the answer mixes airports and old
            // towns in with the cities, and those are dropped.
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ]
        return components?.url
    }

    func cities(named name: String) async throws -> [City] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = Self.url(for: trimmed) else { return [] }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.refused
        }
        return try Self.cities(from: data)
    }

    /// The answer keeps `name`, `admin1`, the country, `latitude`, `longitude`
    /// and `timezone`, and nothing else, for places people live in: an airport
    /// is not a city, and neither is a city's old town. No `results` is an
    /// empty list: a city nobody has heard of is not a failure.
    ///
    /// The country is the name macOS gives `country_code` in English, the
    /// language the names are asked for in, and the geocoder's own `country`
    /// only when there is no code: the geocoder says "Republic of Türkiye"
    /// where everybody else says "Türkiye".
    static func cities(from data: Data) throws -> [City] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WeatherError.unreadable
        }
        let results = json["results"] as? [[String: Any]] ?? []
        let cities = results.compactMap { result -> City? in
            if let feature = result["feature_code"] as? String, !isPopulatedPlace(feature) { return nil }
            guard let name = result["name"] as? String,
                  let latitude = (result["latitude"] as? NSNumber)?.doubleValue,
                  let longitude = (result["longitude"] as? NSNumber)?.doubleValue
            else { return nil }
            return City(name: name,
                        region: result["admin1"] as? String,
                        country: countryName(code: result["country_code"] as? String)
                            ?? result["country"] as? String,
                        place: Place(latitude: latitude, longitude: longitude),
                        timeZone: result["timezone"] as? String)
        }
        return Array(cities.prefix(5))
    }

    /// GeoNames' populated places, `PPL` and its kinds (a capital, a seat of
    /// government, a village), less the ones nobody lives in as a town: a
    /// section of a city, and places historical, abandoned or destroyed.
    static func isPopulatedPlace(_ feature: String) -> Bool {
        feature.hasPrefix("PPL") && !["PPLX", "PPLH", "PPLQ", "PPLW", "PPLCH"].contains(feature)
    }

    static func countryName(code: String?) -> String? {
        guard let code, !code.isEmpty else { return nil }
        return Locale(identifier: "en").localizedString(forRegionCode: code)
    }

    /// A country stored before names came from the code ("Republic of
    /// Türkiye") read as the name the code gives ("Türkiye"): the longest
    /// region name it ends with, or itself.
    static func shortCountry(_ stored: String?) -> String? {
        guard let stored else { return nil }
        let english = Locale(identifier: "en")
        let names = Locale.Region.isoRegions.compactMap { english.localizedString(forRegionCode: $0.identifier) }
        return names.filter { stored.hasSuffix($0) }.max(by: { $0.count < $1.count }) ?? stored
    }
}

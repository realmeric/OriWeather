import Foundation

/// Open-Meteo: no key, no account, no paid programme.
struct OpenMeteo: WeatherFetching {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    static func url(for place: Place) -> URL? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: "\(place.rounded.latitude)"),
            URLQueryItem(name: "longitude", value: "\(place.rounded.longitude)"),
            URLQueryItem(name: "current",
                         value: "temperature_2m,apparent_temperature,is_day,weather_code"),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        return components?.url
    }

    func read(at place: Place) async throws -> WeatherReading {
        guard let url = Self.url(for: place) else { throw WeatherError.badPlace }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.refused
        }
        return try Self.reading(from: data)
    }

    /// The body, as it comes back: `current` holds the figures, and the time
    /// beside them is local wall clock with the offset given separately.
    static func reading(from data: Data, now: Date = Date()) throws -> WeatherReading {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = json["current"] as? [String: Any],
              let temperature = (current["temperature_2m"] as? NSNumber)?.doubleValue,
              let code = (current["weather_code"] as? NSNumber)?.intValue
        else { throw WeatherError.unreadable }
        let feels = (current["apparent_temperature"] as? NSNumber)?.doubleValue ?? temperature
        let isDay = (current["is_day"] as? NSNumber)?.intValue ?? 1
        let offset = (json["utc_offset_seconds"] as? NSNumber)?.doubleValue ?? 0
        let at = (current["time"] as? String).flatMap { stamp(from: $0, offset: offset) } ?? now
        return WeatherReading(temperature: temperature, feelsLike: feels, code: code,
                              isDay: isDay == 1, at: at)
    }

    private static func stamp(from text: String, offset: Double) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: text)?.addingTimeInterval(-offset)
    }
}

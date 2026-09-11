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
            // Today's high and low and the hours ahead, in the same request:
            // the shelf shows them, and a second request would be a second
            // request.
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code,is_day"),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "forecast_hours", value: "7"),
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
        let currentTime = current["time"] as? String
        let at = currentTime.flatMap { stamp(from: $0, offset: offset) } ?? now
        var reading = WeatherReading(temperature: temperature, feelsLike: feels, code: code,
                                     isDay: isDay == 1, at: at)
        if let daily = json["daily"] as? [String: Any] {
            reading.high = ((daily["temperature_2m_max"] as? [Any])?.first as? NSNumber)?.doubleValue
            reading.low = ((daily["temperature_2m_min"] as? [Any])?.first as? NSNumber)?.doubleValue
        }
        if let hourly = json["hourly"] as? [String: Any] {
            reading.hours = hours(from: hourly, after: currentTime)
        }
        return reading
    }

    /// The hours after the current one, at most five. The times are local
    /// wall clock in the place, "2026-09-11T15:00", and so are compared as
    /// text: an hour that sorts after the current reading's time is ahead.
    private static func hours(from hourly: [String: Any], after current: String?) -> [WeatherReading.Hour] {
        guard let times = hourly["time"] as? [String],
              let temperatures = hourly["temperature_2m"] as? [Any],
              let codes = hourly["weather_code"] as? [Any] else { return [] }
        let days = hourly["is_day"] as? [Any] ?? []
        var hours: [WeatherReading.Hour] = []
        for (index, time) in times.enumerated() where index < temperatures.count && index < codes.count {
            if let current, time <= current { continue }
            guard let temperature = (temperatures[index] as? NSNumber)?.doubleValue,
                  let code = (codes[index] as? NSNumber)?.intValue,
                  let hour = Int(time.split(separator: "T").last?.prefix(2) ?? "") else { continue }
            let isDay = index < days.count ? ((days[index] as? NSNumber)?.intValue ?? 1) == 1 : true
            hours.append(WeatherReading.Hour(hour: hour, temperature: temperature, code: code, isDay: isDay))
            if hours.count == 5 { break }
        }
        return hours
    }

    private static func stamp(from text: String, offset: Double) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: text)?.addingTimeInterval(-offset)
    }
}

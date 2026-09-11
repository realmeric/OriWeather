import Foundation

/// What the sky is doing, in the only detail the notch shows.
///
/// Carried over from OriNotch's `Weather.swift`; nothing in `Sky/` knows it is
/// a droplet.
struct WeatherReading: Equatable, Sendable {
    /// Celsius.
    let temperature: Double
    let feelsLike: Double
    let code: Int
    let isDay: Bool
    /// When the reading was taken, which is what an old one is dimmed by.
    let at: Date

    var degrees: String { degrees(in: .celsius) }
    var condition: String { WeatherCode.words(code) }

    /// The temperature the way the user counts it, converted from the one
    /// Celsius reading and rounded after converting: 25.5 °C is 26° and 78°,
    /// where rounding first would say 79°.
    func degrees(in unit: TemperatureUnit) -> String {
        Self.figure(temperature, in: unit)
    }

    func feelsLike(in unit: TemperatureUnit) -> String {
        Self.figure(feelsLike, in: unit)
    }

    private static func figure(_ celsius: Double, in unit: TemperatureUnit) -> String {
        let value = unit == .celsius ? celsius : celsius * 9 / 5 + 32
        // Through Int, so a value that rounds to zero from below is "0°" and
        // never "-0°".
        return "\(Int(value.rounded()))°"
    }
}

/// The one reading is in Celsius; Fahrenheit is a conversion, never a second
/// request.
enum TemperatureUnit: String, Codable, CaseIterable, Sendable {
    case celsius
    case fahrenheit
}

/// The WMO code table, as much of it as anybody reads.
///
/// Open-Meteo answers in these codes and nothing else; the words and the mark
/// beside them are this droplet's own.
enum WeatherCode {
    enum Mark: Equatable, CaseIterable, Sendable {
        case sun
        case cloud
        case rain
        case snow
        case fog
        case storm
    }

    static func mark(_ code: Int) -> Mark {
        switch code {
        case 0, 1: return .sun
        case 2, 3: return .cloud
        case 45, 48: return .fog
        case 51 ... 67, 80 ... 82: return .rain
        case 71 ... 77, 85, 86: return .snow
        case 95 ... 99: return .storm
        default: return .cloud
        }
    }

    static func words(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1: return "Mainly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55, 56, 57: return "Drizzle"
        case 61, 63, 65, 66, 67: return "Rain"
        case 71, 73, 75, 77: return "Snow"
        case 80, 81, 82: return "Showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Hail"
        default: return "Unknown"
        }
    }
}

/// Somewhere on the map, rounded.
struct Place: Equatable, Codable, Sendable {
    let latitude: Double
    let longitude: Double

    /// Two decimals is about a kilometre, which is as much as a temperature
    /// needs and less than the notch has any business sending anywhere.
    var rounded: Place {
        Place(latitude: (latitude * 100).rounded() / 100,
              longitude: (longitude * 100).rounded() / 100)
    }
}

/// Where the reading comes from. Open-Meteo in the droplet, a recorded answer
/// in the tests, which is how nothing in `make test` reaches the network.
protocol WeatherFetching: Sendable {
    func read(at place: Place) async throws -> WeatherReading
}

enum WeatherError: Error, Equatable {
    case badPlace
    case refused
    case unreadable
    case nowhere
}

import Foundation

/// A fixed sky, for the harness and for a Playground run that asks for one.
///
/// Read once at activation: in the harness, or with `OW_DEMO=1`, the fetcher
/// is `DemoWeather` and nothing reaches the network. `OW_DEMO=stale` answers
/// once and refuses two seconds later, which is what an aeroplane looks like.
enum Demo {
    enum Mode: Equatable {
        case fixed
        case stale
    }

    /// What `OW_DEMO` asks for, if anything; the harness is a fixed sky unless
    /// the variable says stale.
    static func mode(environment: [String: String] = ProcessInfo.processInfo.environment,
                     isHarness: Bool) -> Mode? {
        switch environment["OW_DEMO"] {
        case "stale": return .stale
        case .some: return .fixed
        case .none: return isHarness ? .fixed : nil
        }
    }

    /// Where the demo sky is, when nobody has chosen a city.
    static let city = City(name: "Istanbul", region: "Istanbul", country: "Republic of Türkiye",
                           place: Place(latitude: 41.01, longitude: 28.95),
                           timeZone: "Europe/Istanbul")
}

/// 25.5°, feels like 24.2°, partly cloudy, by day, and never a request.
final class DemoWeather: WeatherFetching, @unchecked Sendable {
    private let mode: Demo.Mode
    private let lock = NSLock()
    private var firstRead: Date?

    init(mode: Demo.Mode) {
        self.mode = mode
    }

    func read(at place: Place) async throws -> WeatherReading {
        let now = Date()
        // The stale sky answers its first read and refuses every one after,
        // and the droplet asks again two seconds later.
        let refused: Bool = lock.withLock {
            defer { firstRead = firstRead ?? now }
            return mode == .stale && firstRead != nil
        }
        if refused { throw WeatherError.refused }
        // The stale demo's one good reading is two hours old, so the card has
        // an age worth saying the moment the next read is refused.
        let at = mode == .stale ? now.addingTimeInterval(-2 * 3600) : now
        return WeatherReading(temperature: 25.5, feelsLike: 24.2, code: 2, isDay: true, at: at)
    }
}

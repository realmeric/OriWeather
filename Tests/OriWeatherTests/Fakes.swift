import Foundation
@testable import OriWeather

actor Counter {
    private(set) var count = 0
    func bump() { count += 1 }
}

/// A fetcher that answers from memory and counts how often it was asked,
/// which is how a test says "nothing was fetched".
struct FakeWeather: WeatherFetching {
    let reading: WeatherReading?
    let counter = Counter()

    func read(at place: Place) async throws -> WeatherReading {
        await counter.bump()
        guard let reading else { throw WeatherError.refused }
        return reading
    }
}

/// A fetcher whose answer can be changed between reads: good, then refused.
final class SwitchableWeather: WeatherFetching, @unchecked Sendable {
    private let lock = NSLock()
    private var answer: WeatherReading?
    let counter = Counter()

    init(_ answer: WeatherReading?) { self.answer = answer }

    func answer(_ reading: WeatherReading?) {
        lock.withLock { answer = reading }
    }

    func read(at place: Place) async throws -> WeatherReading {
        await counter.bump()
        let reading = lock.withLock { answer }
        guard let reading else { throw WeatherError.refused }
        return reading
    }
}

enum Sky {
    static let now = Date(timeIntervalSince1970: 1_788_000_000)

    static let istanbul = City(name: "Istanbul", region: "Istanbul", country: "Republic of Türkiye",
                               place: Place(latitude: 41.01, longitude: 28.95),
                               timeZone: "Europe/Istanbul")

    static func reading(_ at: Date = now, temperature: Double = 25.5) -> WeatherReading {
        WeatherReading(temperature: temperature, feelsLike: 24.2, code: 2, isDay: true, at: at)
    }
}

/// Lets the main actor run the tasks a model started, then returns.
@MainActor
func settle() async {
    for _ in 0 ..< 20 {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 2_000_000)
    }
}

/// A geocoder that answers from memory and counts how often it was asked.
struct FakeGeocoder: Geocoding {
    let answer: [City]
    let counter = Counter()

    func cities(named name: String) async throws -> [City] {
        await counter.bump()
        return answer
    }
}

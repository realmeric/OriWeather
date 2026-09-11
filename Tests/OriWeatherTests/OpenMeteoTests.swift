import XCTest
@testable import OriWeather

final class OpenMeteoTests: XCTestCase {
    /// The body as Open-Meteo answered on 2026-09-08, kept here rather than in
    /// a recording so that a test never reaches the network.
    private let body = Data("""
        {"latitude":41.0,"longitude":29.0,"utc_offset_seconds":10800,
         "timezone":"Europe/Istanbul","current_units":{"temperature_2m":"°C"},
         "current":{"time":"2026-09-08T14:00","interval":900,"temperature_2m":25.5,
         "apparent_temperature":24.2,"is_day":1,"weather_code":1}}
        """.utf8)

    func testItReadsTheCurrentBlock() throws {
        let reading = try OpenMeteo.reading(from: body)
        XCTAssertEqual(reading.temperature, 25.5)
        XCTAssertEqual(reading.feelsLike, 24.2)
        XCTAssertEqual(reading.code, 1)
        XCTAssertTrue(reading.isDay)
        XCTAssertEqual(reading.degrees, "26°")
        XCTAssertEqual(reading.condition, "Mainly clear")
    }

    /// `current.time` is local wall clock with the offset given separately, so
    /// 14:00 in Istanbul is 11:00 UTC and not 14:00 UTC.
    func testTheTimeIsLocalWithTheOffsetBesideIt() throws {
        let reading = try OpenMeteo.reading(from: body)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(utc.component(.hour, from: reading.at), 11)
    }

    func testABodyWithNoCurrentBlockIsUnreadable() {
        XCTAssertThrowsError(try OpenMeteo.reading(from: Data("{}".utf8)))
    }

    /// Two decimals is about a kilometre. A temperature does not need more and
    /// somebody else's server has no business with more.
    func testTheCoordinateIsRoundedBeforeItIsSent() throws {
        let url = try XCTUnwrap(OpenMeteo.url(for: Place(latitude: 41.013_745,
                                                         longitude: 28.949_666)))
        let query = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems)
        XCTAssertEqual(query.first { $0.name == "latitude" }?.value, "41.01")
        XCTAssertEqual(query.first { $0.name == "longitude" }?.value, "28.95")
        XCTAssertEqual(url.host, "api.open-meteo.com")
    }

    func testTheCodeTableSaysWhatToDraw() {
        XCTAssertEqual(WeatherCode.mark(0), .sun)
        XCTAssertEqual(WeatherCode.mark(3), .cloud)
        XCTAssertEqual(WeatherCode.mark(48), .fog)
        XCTAssertEqual(WeatherCode.mark(65), .rain)
        XCTAssertEqual(WeatherCode.mark(81), .rain)
        XCTAssertEqual(WeatherCode.mark(75), .snow)
        XCTAssertEqual(WeatherCode.mark(95), .storm)
        XCTAssertEqual(WeatherCode.words(61), "Rain")
    }
}

final class AgoTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_788_000_000)

    func testItSaysHowLongAgoInTheWordsARowUses() {
        XCTAssertEqual(Ago.words(now - 5, at: now), "now")
        XCTAssertEqual(Ago.words(now - 59, at: now), "now")
        XCTAssertEqual(Ago.words(now - 60, at: now), "1 min ago")
        XCTAssertEqual(Ago.words(now - 7 * 60, at: now), "7 min ago")
        XCTAssertEqual(Ago.words(now - 3600, at: now), "1 h ago")
        XCTAssertEqual(Ago.words(now - 26 * 3600, at: now), "1 d ago")
    }
}

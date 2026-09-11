import XCTest
@testable import OriWeather

final class ForecastTests: XCTestCase {
    /// Open-Meteo's answer for Istanbul at 14:30 on 2026-09-11, with today's
    /// high and low and the hours from the current one, kept here so no test
    /// reaches the network.
    private let body = Data("""
        {"latitude":41.0,"longitude":29.0,"utc_offset_seconds":10800,"timezone":"Europe/Istanbul",
         "current":{"time":"2026-09-11T14:30","interval":900,"temperature_2m":27.6,
                    "apparent_temperature":27.6,"is_day":1,"weather_code":1},
         "daily":{"time":["2026-09-11"],"temperature_2m_max":[27.6],"temperature_2m_min":[20.6]},
         "hourly":{"time":["2026-09-11T14:00","2026-09-11T15:00","2026-09-11T16:00","2026-09-11T17:00",
                           "2026-09-11T18:00","2026-09-11T19:00","2026-09-11T20:00"],
                   "temperature_2m":[27.6,27.4,26.9,26.0,25.0,23.8,22.9],
                   "weather_code":[1,1,1,2,3,61,2],"is_day":[1,1,1,1,1,1,0]}}
        """.utf8)

    func testTodaysHighAndLowAreRead() throws {
        let reading = try OpenMeteo.reading(from: body)
        XCTAssertEqual(reading.high, 27.6)
        XCTAssertEqual(reading.low, 20.6)
    }

    /// The hour the reading is in has passed; the five after it are ahead.
    func testTheHoursAheadStartAfterTheCurrentOneAndStopAtFive() throws {
        let hours = try OpenMeteo.reading(from: body).hours
        XCTAssertEqual(hours.map(\.hour), [15, 16, 17, 18, 19])
        XCTAssertEqual(hours.map(\.code), [1, 1, 2, 3, 61])
        XCTAssertEqual(hours.first?.temperature, 27.4)
        XCTAssertEqual(hours.last?.isDay, true)
    }

    /// An answer without them is still a reading, only without the extras.
    func testAnAnswerWithoutTheForecastIsStillAReading() throws {
        let plain = Data(#"{"current":{"time":"2026-09-08T14:00","temperature_2m":25.5,"weather_code":1}}"#.utf8)
        let reading = try OpenMeteo.reading(from: plain)
        XCTAssertNil(reading.high)
        XCTAssertEqual(reading.hours, [])
    }

    func testTheForecastIsAskedForInTheSameRequest() throws {
        let url = try XCTUnwrap(OpenMeteo.url(for: Place(latitude: 41.01, longitude: 28.95)))
        let query = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(query.first { $0.name == "daily" }?.value, "temperature_2m_max,temperature_2m_min")
        XCTAssertEqual(query.first { $0.name == "hourly" }?.value, "temperature_2m,weather_code,is_day")
        XCTAssertEqual(query.first { $0.name == "forecast_days" }?.value, "1")
    }

    /// The shelf's words: the high and low in the user's unit, the hours in
    /// the Mac's own way of writing an hour.
    func testTheGlanceSaysTheHighLowAndHoursInTheUsersUnit() throws {
        let reading = try OpenMeteo.reading(from: body)
        let celsius = Glance(reading: reading, isStale: false, now: reading.at, city: Sky.istanbul, unit: .celsius)
        XCTAssertEqual(celsius.highLow, "H 28°  L 21°")
        XCTAssertEqual(celsius.hours.first?.degrees, "27°")
        let fahrenheit = Glance(reading: reading, isStale: false, now: reading.at, city: Sky.istanbul, unit: .fahrenheit)
        XCTAssertEqual(fahrenheit.highLow, "H 82°  L 69°")
        XCTAssertFalse(HourGlance.label(15).isEmpty)
        XCTAssertTrue(HourGlance.label(15) == "15" || HourGlance.label(15).contains("3"))
    }
}

import DroppyKit
import DroppyKitHarness
import XCTest
@testable import OriWeather

final class GeocoderTests: XCTestCase {
    /// The geocoder's answer for "Istanbul" on 2026-09-11, kept here so that a
    /// test never reaches the network.
    private let istanbul = Data("""
        {"results":[{"id":745044,"name":"Istanbul","latitude":41.01384,"longitude":28.94966,"elevation":39.0,"feature_code":"PPLA","country_code":"TR","admin1_id":745042,"timezone":"Europe/Istanbul","population":15701602,"postcodes":["34122"],"country_id":298795,"country":"Republic of Türkiye","admin1":"Istanbul"},
         {"id":10953465,"name":"İstanbulboğazı","latitude":41.0641,"longitude":37.71004,"elevation":433.0,"feature_code":"PPL","country_code":"TR","admin1_id":741098,"admin2_id":8631637,"timezone":"Europe/Istanbul","country_id":298795,"country":"Republic of Türkiye","admin1":"Ordu","admin2":"Perşembe İlçesi"},
         {"id":11838481,"name":"Istanbul Airport","latitude":41.2629,"longitude":28.74242,"elevation":125.0,"feature_code":"AIRP","country_code":"TR","admin1_id":745042,"admin2_id":8521528,"timezone":"Europe/Istanbul","country_id":298795,"country":"Republic of Türkiye","admin1":"Istanbul","admin2":"Arnavutköy"},
         {"id":12908718,"name":"Istanbul Old Town","latitude":41.00783,"longitude":28.97838,"elevation":9999.0,"feature_code":"PPLX","country_code":"TR","admin1_id":745042,"admin2_id":7733237,"timezone":"Europe/Istanbul","country_id":298795,"country":"Republic of Türkiye","admin1":"Istanbul","admin2":"Fatih"},
         {"id":6299743,"name":"Istanbul Atatürk Airport","latitude":40.97692,"longitude":28.81461,"elevation":49.0,"feature_code":"AIRP","country_code":"TR","admin1_id":745042,"admin2_id":7732461,"timezone":"Europe/Istanbul","country_id":298795,"country":"Republic of Türkiye","admin1":"Istanbul","admin2":"Bakırköy"}],"generationtime_ms":0.38588047}
        """.utf8)

    /// Of the five answers, two are places people live in. The two airports
    /// and the old town are not cities.
    func testTheAnswerIsTheCitiesWithTheCoordinateAlreadyRounded() throws {
        let cities = try OpenMeteoGeocoder.cities(from: istanbul)
        XCTAssertEqual(cities.map(\.name), ["Istanbul", "İstanbulboğazı"])
        let first = try XCTUnwrap(cities.first)
        XCTAssertEqual(first.name, "Istanbul")
        XCTAssertEqual(first.region, "Istanbul")
        XCTAssertEqual(first.country, "Türkiye", "the name for TR, not the geocoder's Republic of Türkiye")
        XCTAssertEqual(first.timeZone, "Europe/Istanbul")
        XCTAssertEqual(first.place, Place(latitude: 41.01, longitude: 28.95))
    }

    /// Ten answers asked for, five kept, all of them towns.
    func testNoMoreThanFiveAreKept() throws {
        let place = #"{"name":"Springfield","latitude":1.0,"longitude":2.0,"feature_code":"PPL","country_code":"US"}"#
        let body = Data("{\"results\":[\(Array(repeating: place, count: 8).joined(separator: ","))]}".utf8)
        XCTAssertEqual(try OpenMeteoGeocoder.cities(from: body).count, 5)
    }

    func testAStoredLongCountryReadsShort() {
        XCTAssertEqual(OpenMeteoGeocoder.shortCountry("Republic of Türkiye"), "Türkiye")
        XCTAssertEqual(OpenMeteoGeocoder.shortCountry("Germany"), "Germany")
        XCTAssertEqual(OpenMeteoGeocoder.shortCountry("Elsewhere"), "Elsewhere")
    }

    /// No country code, and the geocoder's own name is kept.
    func testWithoutACodeTheGeocodersCountryIsKept() throws {
        let body = Data(#"{"results":[{"name":"Somewhere","latitude":1.0,"longitude":2.0,"country":"Elsewhere"}]}"#.utf8)
        XCTAssertEqual(try OpenMeteoGeocoder.cities(from: body).first?.country, "Elsewhere")
    }

    /// A city nobody has heard of is not a failure.
    func testNoResultsIsAnEmptyListRatherThanAnError() throws {
        let cities = try OpenMeteoGeocoder.cities(from: Data(#"{"generationtime_ms":0.31}"#.utf8))
        XCTAssertEqual(cities, [])
    }

    func testTheNameIsPercentEncodedAndGoesToTheGeocoder() throws {
        let url = try XCTUnwrap(OpenMeteoGeocoder.url(for: "İstanbul"))
        XCTAssertEqual(url.host, "geocoding-api.open-meteo.com")
        XCTAssertTrue(url.absoluteString.contains("name=%C4%B0stanbul"), url.absoluteString)
        let query = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(query.first { $0.name == "count" }?.value, "10")
        XCTAssertEqual(query.first { $0.name == "language" }?.value, "en")
        XCTAssertEqual(query.first { $0.name == "format" }?.value, "json")
    }

    @MainActor
    func testACityWrittenToThePreferencesReadsBackEqual() throws {
        let service = HarnessPreferencesService(dropletID: OriWeatherDroplet.id,
                                                recorder: HarnessRecorder())
        let preferences = Preferences(service: service)
        let city = try XCTUnwrap(OpenMeteoGeocoder.cities(from: istanbul).first)
        preferences.city = city
        XCTAssertEqual(preferences.city, city)
        XCTAssertEqual(service.storedKeys, ["city"])
    }
}

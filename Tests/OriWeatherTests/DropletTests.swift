import XCTest
@testable import OriWeather

@MainActor
final class DropletTests: XCTestCase {
    /// The id is the folder the loader looks in, the key prefix preferences
    /// are stored under and the manifest's first line; the three must agree.
    func testTheIdIsTheOneTheManifestNames() {
        XCTAssertEqual(OriWeatherDroplet.id, "ori-weather")
    }
}

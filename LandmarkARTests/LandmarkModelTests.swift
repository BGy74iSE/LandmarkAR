import XCTest
import CoreLocation
@testable import LandmarkAR

final class LandmarkModelTests: XCTestCase {

    private let coord = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)

    // MARK: - Default values

    func testDefaultDistanceIsZero() {
        let lm = makeLandmark()
        XCTAssertEqual(lm.distance, 0)
    }

    func testDefaultBearingIsZero() {
        let lm = makeLandmark()
        XCTAssertEqual(lm.bearing, 0)
    }

    func testDefaultAltitudeIsNil() {
        let lm = makeLandmark()
        XCTAssertNil(lm.altitude)
    }

    func testDefaultWikipediaURLIsNil() {
        let lm = makeLandmark(url: nil)
        XCTAssertNil(lm.wikipediaURL)
    }

    // MARK: - Custom values

    func testStoredProperties() {
        let url = URL(string: "https://en.wikipedia.org/wiki/Seattle")!
        let lm = Landmark(
            id: "42",
            title: "Seattle",
            summary: "A city in Washington",
            coordinate: coord,
            wikipediaURL: url,
            category: .cultural,
            distance: 500,
            bearing: 45
        )

        XCTAssertEqual(lm.id, "42")
        XCTAssertEqual(lm.title, "Seattle")
        XCTAssertEqual(lm.summary, "A city in Washington")
        XCTAssertEqual(lm.coordinate.latitude,  coord.latitude,  accuracy: 1e-6)
        XCTAssertEqual(lm.coordinate.longitude, coord.longitude, accuracy: 1e-6)
        XCTAssertEqual(lm.wikipediaURL, url)
        XCTAssertEqual(lm.category, .cultural)
        XCTAssertEqual(lm.distance, 500)
        XCTAssertEqual(lm.bearing,  45)
    }

    func testMutableAltitude() {
        var lm = makeLandmark()
        lm.altitude = 1234.5
        XCTAssertEqual(lm.altitude, 1234.5)
    }

    func testMutableDistance() {
        var lm = makeLandmark()
        lm.distance = 9999
        XCTAssertEqual(lm.distance, 9999)
    }

    func testMutableBearing() {
        var lm = makeLandmark()
        lm.bearing = 270
        XCTAssertEqual(lm.bearing, 270)
    }

    // MARK: - All categories round-trip through Landmark

    func testAllCategoriesCanBeStored() {
        for category in [LandmarkCategory.historical, .natural, .cultural, .other] {
            let lm = makeLandmark(category: category)
            XCTAssertEqual(lm.category, category)
        }
    }

    // MARK: - Identifiable

    func testIdIsUnique() {
        let lm1 = makeLandmark(id: "1")
        let lm2 = makeLandmark(id: "2")
        XCTAssertNotEqual(lm1.id, lm2.id)
    }

    func testSameIdIsEqual() {
        let lm1 = makeLandmark(id: "abc")
        let lm2 = makeLandmark(id: "abc")
        XCTAssertEqual(lm1.id, lm2.id)
    }

    // MARK: - Helpers

    private func makeLandmark(
        id: String = "1",
        category: LandmarkCategory = .other,
        url: URL? = nil
    ) -> Landmark {
        Landmark(
            id: id,
            title: "Test Landmark",
            summary: "A test",
            coordinate: coord,
            wikipediaURL: url,
            category: category
        )
    }
}

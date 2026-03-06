import XCTest
import CoreLocation
@testable import LandmarkAR

final class BearingTests: XCTestCase {

    // Seattle as a well-known origin point
    private let origin = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)

    // MARK: - Cardinal directions

    func testBearingDueNorth() {
        let north = CLLocationCoordinate2D(latitude: 48.6062, longitude: -122.3321)
        XCTAssertEqual(origin.bearing(to: north), 0.0, accuracy: 0.5)
    }

    func testBearingDueSouth() {
        let south = CLLocationCoordinate2D(latitude: 46.6062, longitude: -122.3321)
        XCTAssertEqual(origin.bearing(to: south), 180.0, accuracy: 0.5)
    }

    func testBearingDueEast() {
        let east = CLLocationCoordinate2D(latitude: 47.6062, longitude: -121.0)
        XCTAssertEqual(origin.bearing(to: east), 90.0, accuracy: 1.0)
    }

    func testBearingDueWest() {
        let west = CLLocationCoordinate2D(latitude: 47.6062, longitude: -124.0)
        XCTAssertEqual(origin.bearing(to: west), 270.0, accuracy: 1.0)
    }

    // MARK: - Range

    func testBearingIsAlwaysInRange() {
        let destinations: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 48.0, longitude: -121.0),  // NE
            CLLocationCoordinate2D(latitude: 46.0, longitude: -121.0),  // SE
            CLLocationCoordinate2D(latitude: 46.0, longitude: -124.0),  // SW
            CLLocationCoordinate2D(latitude: 48.0, longitude: -124.0),  // NW
        ]
        for dest in destinations {
            let bearing = origin.bearing(to: dest)
            XCTAssertGreaterThanOrEqual(bearing, 0.0, "Bearing should be >= 0")
            XCTAssertLessThan(bearing, 360.0, "Bearing should be < 360")
        }
    }

    // MARK: - Special cases

    func testSamePointBearingIsZero() {
        let bearing = origin.bearing(to: origin)
        XCTAssertEqual(bearing, 0.0, accuracy: 0.001)
    }

    func testNortheastQuadrant() {
        let ne = CLLocationCoordinate2D(latitude: 48.0, longitude: -121.0)
        let bearing = origin.bearing(to: ne)
        XCTAssertGreaterThan(bearing, 0.0)
        XCTAssertLessThan(bearing, 90.0)
    }

    func testSoutheastQuadrant() {
        let se = CLLocationCoordinate2D(latitude: 46.0, longitude: -121.0)
        let bearing = origin.bearing(to: se)
        XCTAssertGreaterThan(bearing, 90.0)
        XCTAssertLessThan(bearing, 180.0)
    }

    func testSouthwestQuadrant() {
        let sw = CLLocationCoordinate2D(latitude: 46.0, longitude: -124.0)
        let bearing = origin.bearing(to: sw)
        XCTAssertGreaterThan(bearing, 180.0)
        XCTAssertLessThan(bearing, 270.0)
    }

    func testNorthwestQuadrant() {
        let nw = CLLocationCoordinate2D(latitude: 48.0, longitude: -124.0)
        let bearing = origin.bearing(to: nw)
        XCTAssertGreaterThan(bearing, 270.0)
        XCTAssertLessThan(bearing, 360.0)
    }

    // MARK: - toRadians / toDegrees

    func testToRadians() {
        XCTAssertEqual((180.0).toRadians(), Double.pi, accuracy: 1e-10)
        XCTAssertEqual((90.0).toRadians(),  Double.pi / 2, accuracy: 1e-10)
        XCTAssertEqual((0.0).toRadians(),   0.0, accuracy: 1e-10)
    }

    func testToDegrees() {
        XCTAssertEqual(Double.pi.toDegrees(),       180.0, accuracy: 1e-10)
        XCTAssertEqual((Double.pi / 2).toDegrees(),  90.0, accuracy: 1e-10)
        XCTAssertEqual((0.0).toDegrees(),             0.0, accuracy: 1e-10)
    }

    func testRadiansDegreeRoundtrip() {
        let angles = [0.0, 45.0, 90.0, 135.0, 180.0, 270.0, 359.0]
        for angle in angles {
            XCTAssertEqual(angle.toRadians().toDegrees(), angle, accuracy: 1e-10)
        }
    }
}

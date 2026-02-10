import XCTest
import CoreLocation
@testable import OnlinePicketLine

final class LocationManagerTests: XCTestCase {

    // MARK: - Distance Calculation

    func testDistanceBetweenSamePoint() {
        let distance = LocationManager.distance(
            from: (40.7128, -74.0060),
            to: (40.7128, -74.0060)
        )
        XCTAssertEqual(distance, 0.0, accuracy: 1.0)
    }

    func testDistanceBetweenNYCAndLA() {
        // NYC to LA is approximately 3,944 km
        let distance = LocationManager.distance(
            from: (40.7128, -74.0060),
            to: (34.0522, -118.2437)
        )
        let distanceKm = distance / 1000.0
        XCTAssertEqual(distanceKm, 3944, accuracy: 100) // Within 100km
    }

    func testDistanceBetweenNearbyPoints() {
        // Two points about 1 km apart in Manhattan
        let distance = LocationManager.distance(
            from: (40.7580, -73.9855),  // Times Square
            to: (40.7484, -73.9856)     // Empire State Bldg
        )
        let distanceKm = distance / 1000.0
        XCTAssertEqual(distanceKm, 1.07, accuracy: 0.2)
    }

    func testDistanceIsSymmetric() {
        let d1 = LocationManager.distance(
            from: (40.7128, -74.0060),
            to: (34.0522, -118.2437)
        )
        let d2 = LocationManager.distance(
            from: (34.0522, -118.2437),
            to: (40.7128, -74.0060)
        )
        XCTAssertEqual(d1, d2, accuracy: 1.0)
    }

    func testDistanceAcrossEquator() {
        let distance = LocationManager.distance(
            from: (1.0, 0.0),
            to: (-1.0, 0.0)
        )
        let distanceKm = distance / 1000.0
        // 2 degrees of latitude ≈ 222 km
        XCTAssertEqual(distanceKm, 222, accuracy: 5)
    }

    func testDistanceAcrossDateLine() {
        let distance = LocationManager.distance(
            from: (0.0, 179.0),
            to: (0.0, -179.0)
        )
        let distanceKm = distance / 1000.0
        // 2 degrees of longitude at equator ≈ 222 km
        XCTAssertEqual(distanceKm, 222, accuracy: 5)
    }

    // MARK: - Authorization Status

    func testInitialAuthorizationStatus() {
        let manager = LocationManager.shared
        // Should have a valid authorization status
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined, .restricted, .denied,
            .authorizedWhenInUse, .authorizedAlways
        ]
        XCTAssertTrue(validStatuses.contains(manager.authorizationStatus))
    }
}

import XCTest
@testable import OnlinePicketLine

final class ModelsTests: XCTestCase {
    
    // MARK: - GeofenceItem Decoding
    
    func testGeofenceItemDecodesFromJSON() throws {
        let json = """
        {
            "id": "geo-1",
            "type": "picket",
            "actionId": "action-123",
            "employerId": "emp-1",
            "employerName": "Acme Corp",
            "actionType": "strike",
            "organization": "Workers Union",
            "location": "123 Main St",
            "coordinates": { "lat": 40.7128, "lng": -74.0060 },
            "distance": 5000,
            "notificationRadius": 500,
            "startDate": "2025-01-01T00:00:00Z",
            "endDate": null,
            "description": "Test strike",
            "locationName": "HQ"
        }
        """.data(using: .utf8)!
        
        let item = try JSONDecoder().decode(GeofenceItem.self, from: json)
        XCTAssertEqual(item.id, "geo-1")
        XCTAssertEqual(item.employerName, "Acme Corp")
        XCTAssertEqual(item.coordinates.lat, 40.7128)
        XCTAssertEqual(item.coordinates.lng, -74.0060)
        XCTAssertEqual(item.distance, 5000)
        XCTAssertEqual(item.notificationRadius, 500)
        XCTAssertEqual(item.organization, "Workers Union")
        XCTAssertNil(item.endDate)
        XCTAssertEqual(item.locationName, "HQ")
    }
    
    func testGeofenceItemDecodesWithMinimalFields() throws {
        let json = """
        {
            "id": "geo-2",
            "type": "picket",
            "actionId": "action-456",
            "employerId": "emp-2",
            "employerName": "TestCo",
            "actionType": "boycott",
            "coordinates": { "lat": 0.0, "lng": 0.0 },
            "distance": 100,
            "notificationRadius": 200
        }
        """.data(using: .utf8)!
        
        let item = try JSONDecoder().decode(GeofenceItem.self, from: json)
        XCTAssertEqual(item.id, "geo-2")
        XCTAssertNil(item.organization)
        XCTAssertNil(item.location)
        XCTAssertNil(item.startDate)
        XCTAssertNil(item.description)
    }
    
    // MARK: - BlocklistEntry
    
    func testBlocklistEntryId() throws {
        let json = """
        {
            "url": "example.com",
            "employer": "Example Inc",
            "employerId": "emp-3",
            "actionType": "strike",
            "actionId": "act-1"
        }
        """.data(using: .utf8)!
        
        let entry = try JSONDecoder().decode(BlocklistEntry.self, from: json)
        XCTAssertEqual(entry.id, "emp-3-example.com")
        XCTAssertEqual(entry.url, "example.com")
        XCTAssertEqual(entry.employer, "Example Inc")
    }
    
    // MARK: - ActiveStrike
    
    func testActiveStrikeDisplayName() throws {
        let json = """
        {
            "id": "strike-1",
            "organization": "SEIU Local 32BJ",
            "actionType": "strike",
            "location": "NYC",
            "employerName": "Related Companies",
            "employerId": "emp-10",
            "startDate": "2025-01-01"
        }
        """.data(using: .utf8)!
        
        let strike = try JSONDecoder().decode(ActiveStrike.self, from: json)
        XCTAssertEqual(strike.displayName, "Related Companies — SEIU Local 32BJ")
    }
    
    func testActiveStrikeDisplayNameWithoutOrganization() throws {
        let json = """
        {
            "id": "strike-2",
            "actionType": "boycott",
            "employerName": "BigCorp",
            "employerId": "emp-11"
        }
        """.data(using: .utf8)!
        
        let strike = try JSONDecoder().decode(ActiveStrike.self, from: json)
        XCTAssertEqual(strike.displayName, "BigCorp — Boycott")
    }
    
    // MARK: - GpsSnapshotRequest Encoding
    
    func testGpsSnapshotRequestEncodesCorrectly() throws {
        let request = GpsSnapshotRequest(
            actionId: "act-1",
            latitude: 40.7128,
            longitude: -74.0060,
            address: "123 Main St",
            notes: "Visible picket line"
        )
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(GpsSnapshotRequest.self, from: data)
        
        XCTAssertEqual(decoded.actionId, "act-1")
        XCTAssertEqual(decoded.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(decoded.longitude, -74.0060, accuracy: 0.0001)
        XCTAssertEqual(decoded.address, "123 Main St")
        XCTAssertEqual(decoded.notes, "Visible picket line")
    }
    
    func testGpsSnapshotRequestWithNilOptionals() throws {
        let request = GpsSnapshotRequest(
            actionId: "act-2",
            latitude: 34.0522,
            longitude: -118.2437,
            address: nil,
            notes: nil
        )
        let data = try JSONEncoder().encode(request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to deserialize JSON as dictionary")
            return
        }
        
        // nil values should still be present as null or absent
        XCTAssertEqual(json["actionId"] as? String, "act-2")
        XCTAssertEqual(json["latitude"] as? Double, 34.0522, accuracy: 0.0001)
    }
    
    // MARK: - StrikeSubmissionRequest Encoding
    
    func testStrikeSubmissionRequestEncodesCorrectly() throws {
        let request = StrikeSubmissionRequest(
            employer: EmployerSubmission(name: "TestCo", industry: "Tech", website: "https://test.co"),
            action: ActionSubmission(
                organization: "Union Local 1",
                actionType: "strike",
                location: "New York, NY",
                startDate: "2025-01-01",
                durationDays: 14,
                description: "Test strike",
                demands: "Better wages",
                contactInfo: "test@union.org",
                learnMoreUrl: nil,
                coordinates: GpsCoordinates(latitude: 40.7, longitude: -74.0)
            )
        )
        
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(StrikeSubmissionRequest.self, from: data)
        
        XCTAssertEqual(decoded.employer.name, "TestCo")
        XCTAssertEqual(decoded.action.organization, "Union Local 1")
        XCTAssertEqual(decoded.action.durationDays, 14)
        XCTAssertEqual(decoded.action.coordinates?.latitude, 40.7, accuracy: 0.1)
    }
    
    // MARK: - MobileDataResponse Decoding
    
    func testMobileDataResponseDecodes() throws {
        let json = """
        {
            "version": "1.0",
            "cachedRegion": {
                "center": { "lat": 40.0, "lng": -74.0 },
                "radiusMeters": 160934,
                "refreshThresholdMeters": 80000
            },
            "suggestedRefreshInterval": 3600000,
            "geofences": {
                "total": 0,
                "byEmployer": [],
                "all": []
            },
            "blocklist": {
                "totalUrls": 0,
                "totalEmployers": 0,
                "urls": []
            },
            "generatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(MobileDataResponse.self, from: json)
        XCTAssertEqual(response.version, "1.0")
        XCTAssertEqual(response.cachedRegion.radiusMeters, 160934)
        XCTAssertEqual(response.geofences.total, 0)
        XCTAssertEqual(response.blocklist.totalUrls, 0)
        XCTAssertEqual(response.suggestedRefreshInterval, 3600000)
    }
    
    // MARK: - GeocodeResponse
    
    func testGeocodeResponseDecodes() throws {
        let json = """
        {
            "success": true,
            "input": "New York, NY",
            "result": {
                "latitude": 40.7128,
                "longitude": -74.0060,
                "displayName": "New York, NY, USA",
                "confidence": 0.95,
                "source": "nominatim"
            }
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(GeocodeResponse.self, from: json)
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.result?.latitude, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(response.result?.displayName, "New York, NY, USA")
    }
    
    // MARK: - ReverseGeocodeResult
    
    func testReverseGeocodeResultDecodes() throws {
        let json = """
        {
            "address": "350 Fifth Ave",
            "city": "New York",
            "state": "NY",
            "zipCode": "10118",
            "country": "US",
            "displayName": "Empire State Building, 350 Fifth Ave, New York, NY 10118"
        }
        """.data(using: .utf8)!
        
        let result = try JSONDecoder().decode(ReverseGeocodeResult.self, from: json)
        XCTAssertEqual(result.address, "350 Fifth Ave")
        XCTAssertEqual(result.city, "New York")
        XCTAssertEqual(result.state, "NY")
        XCTAssertEqual(result.zipCode, "10118")
    }
    
    // MARK: - BlockedRequest
    
    func testBlockedRequestCreation() {
        let request = BlockedRequest(
            url: "https://example.com",
            employer: "Example Inc",
            actionType: "strike",
            timestamp: Date(),
            appName: "Safari",
            userAction: .pending
        )
        XCTAssertEqual(request.url, "https://example.com")
        XCTAssertEqual(request.employer, "Example Inc")
        // ID should be unique UUID
        XCTAssertFalse(request.id.uuidString.isEmpty)
    }
}

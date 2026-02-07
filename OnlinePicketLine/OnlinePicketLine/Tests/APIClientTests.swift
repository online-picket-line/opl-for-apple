import XCTest
@testable import OnlinePicketLine

final class APIClientTests: XCTestCase {
    
    // MARK: - URL Construction
    
    func testBaseURLIsValid() {
        let client = APIClient.shared
        XCTAssertFalse(client.baseURL.isEmpty)
        XCTAssertTrue(client.baseURL.hasPrefix("https://"))
        XCTAssertTrue(client.baseURL.contains("onlinepicketline.com"))
    }
    
    func testMobileDataURLConstruction() {
        let baseURL = APIClient.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/mobile/data")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: "40.7128"),
            URLQueryItem(name: "lng", value: "-74.0060"),
            URLQueryItem(name: "radius", value: "160934")
        ]
        
        let url = components.url!
        XCTAssertTrue(url.absoluteString.contains("lat=40.7128"))
        XCTAssertTrue(url.absoluteString.contains("lng=-74.006"))
        XCTAssertTrue(url.absoluteString.contains("radius=160934"))
    }
    
    func testActiveStrikesURLConstruction() {
        let baseURL = APIClient.shared.baseURL
        let url = URL(string: "\(baseURL)/mobile/active-strikes")!
        XCTAssertTrue(url.absoluteString.hasSuffix("/mobile/active-strikes"))
    }
    
    func testGpsSnapshotURLConstruction() {
        let baseURL = APIClient.shared.baseURL
        let url = URL(string: "\(baseURL)/mobile/gps-snapshot")!
        XCTAssertTrue(url.absoluteString.hasSuffix("/mobile/gps-snapshot"))
    }
    
    // MARK: - Error Types
    
    func testOPLErrorApiDescription() {
        let error = OPLError.api(401, "Unauthorized")
        XCTAssertEqual(error.errorDescription, "[401] Unauthorized")
    }
    
    func testOPLErrorNotFoundDescription() {
        let error = OPLError.notFound("No results")
        XCTAssertEqual(error.errorDescription, "No results")
    }
    
    func testOPLErrorNoApiKeyDescription() {
        let error = OPLError.noApiKey
        XCTAssertEqual(error.errorDescription, "API key not configured")
    }
    
    // MARK: - MobileDataResult
    
    func testMobileDataResultSuccess() {
        let data = MobileDataResponse(
            version: "1.0",
            cachedRegion: CachedRegion(
                center: Coordinates(lat: 0, lng: 0),
                radiusMeters: 160934,
                refreshThresholdMeters: 80000
            ),
            suggestedRefreshInterval: 3600000,
            geofences: GeofenceCollection(total: 0, byEmployer: [], all: []),
            blocklist: BlocklistData(totalUrls: 0, totalEmployers: 0, urls: []),
            generatedAt: "2025-01-01"
        )
        
        let result = MobileDataResult.success(data, hash: "abc123")
        if case .success(let responseData, let hash) = result {
            XCTAssertEqual(responseData.version, "1.0")
            XCTAssertEqual(hash, "abc123")
        } else {
            XCTFail("Expected success result")
        }
    }
    
    func testMobileDataResultNotModified() {
        let result = MobileDataResult.notModified
        if case .notModified = result {
            // Pass
        } else {
            XCTFail("Expected notModified result")
        }
    }
    
    // MARK: - ApiErrorResponse
    
    func testApiErrorResponseDecoding() throws {
        let json = """
        { "error": "Invalid API key" }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(ApiErrorResponse.self, from: json)
        XCTAssertEqual(response.error, "Invalid API key")
    }
}

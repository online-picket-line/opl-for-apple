import Foundation





























































































































}    }        )            actionId: "act-1"            actionType: "strike",            employerId: "test-\(employer)",            employer: employer,            url: url,        BlocklistEntry(    private func makeBlocklistEntry(url: String, employer: String) -> BlocklistEntry {        }        return appState        appState.mobileData = testData        )            generatedAt: "2025-01-01T00:00:00Z"            blocklist: BlocklistData(totalUrls: entries.count, totalEmployers: 1, urls: entries),            geofences: GeofenceCollection(total: 0, byEmployer: [], all: []),            suggestedRefreshInterval: 3600000,            ),                refreshThresholdMeters: 80000                radiusMeters: 160934,                center: Coordinates(lat: 0, lng: 0),            cachedRegion: CachedRegion(            version: "1.0",        let testData = MobileDataResponse(        // Inject test data        let appState = AppState.shared    private func createAppStateWithBlocklist(_ entries: [BlocklistEntry]) -> AppState {    @MainActor        // MARK: - Helpers        }        XCTAssertNil(data)        let data = await appState.mobileData        await appState.clearCache()        let appState = await AppState.shared    func testClearCache() async {        // MARK: - Cache Operations        }        XCTAssertTrue(result)        let result = await appState.shouldRefreshForLocation(lat: 0, lng: 0)        // With no data, should always refresh        let appState = await AppState.shared    func testShouldRefreshForLocationNilData() async {        // MARK: - Region Refresh Check        }        XCTAssertNotNil(result)        let result = await appState.findBlockedUrl("example.com")                ])            makeBlocklistEntry(url: "Example.COM", employer: "ExCo")        let appState = await createAppStateWithBlocklist([    func testFindBlockedUrlCaseInsensitive() async {        }        XCTAssertFalse(notBlocked)        let notBlocked = await appState.isDomainBlocked("safe.com")                XCTAssertTrue(blocked)        let blocked = await appState.isDomainBlocked("blocked.com")                ])            makeBlocklistEntry(url: "blocked.com", employer: "BlockedCo")        let appState = await createAppStateWithBlocklist([    func testIsDomainBlocked() async {        }        XCTAssertNil(result)        let result = await appState.findBlockedUrl("notexample.com")        // "notexample.com" should NOT match "example.com"                ])            makeBlocklistEntry(url: "example.com", employer: "ExCo")        let appState = await createAppStateWithBlocklist([    func testFindBlockedUrlPartialName() async {        }        XCTAssertNil(result)        let result = await appState.findBlockedUrl("other.com")                ])            makeBlocklistEntry(url: "example.com", employer: "ExCo")        let appState = await createAppStateWithBlocklist([    func testFindBlockedUrlNoMatch() async {        }        XCTAssertNotNil(result)        let result = await appState.findBlockedUrl("https://example.com")                ])            makeBlocklistEntry(url: "example.com", employer: "ExCo")        let appState = await createAppStateWithBlocklist([    func testFindBlockedUrlWithScheme() async {        }        XCTAssertNotNil(result)        let result = await appState.findBlockedUrl("www.example.com")                ])            makeBlocklistEntry(url: "example.com", employer: "ExCo")        let appState = await createAppStateWithBlocklist([    func testFindBlockedUrlSubdomain() async {        }        XCTAssertEqual(result?.employer, "ExCo")        XCTAssertNotNil(result)        let result = await appState.findBlockedUrl("example.com")                ])            makeBlocklistEntry(url: "example.com", employer: "ExCo")        let appState = await createAppStateWithBlocklist([    func testFindBlockedUrlExactMatch() async {        // MARK: - Host Extraction & Blocklist Matching    final class AppStateTests: XCTestCase {// MARK: - Mobile Data API Response

struct MobileDataResponse: Codable {
    let version: String
    let cachedRegion: CachedRegion
    let suggestedRefreshInterval: Int
    let geofences: GeofenceCollection
    let blocklist: BlocklistData
    let generatedAt: String
}

struct CachedRegion: Codable {
    let center: Coordinates
    let radiusMeters: Int
    let refreshThresholdMeters: Int
}

struct Coordinates: Codable {
    let lat: Double
    let lng: Double
}

struct GeofenceCollection: Codable {
    let total: Int
    let byEmployer: [EmployerGeofences]
    let all: [GeofenceItem]
}

struct EmployerGeofences: Codable {
    let employerId: String
    let employerName: String
    let geofences: [GeofenceItem]
}

struct GeofenceItem: Codable, Identifiable {
    let id: String
    let type: String
    let actionId: String
    let employerId: String
    let employerName: String
    let actionType: String
    let organization: String?
    let location: String?
    let coordinates: Coordinates
    let distance: Int
    let notificationRadius: Int
    let startDate: String?
    let endDate: String?
    let description: String?
    let demands: String?
    let moreInfoUrl: String?
    let locationName: String?
    let locationType: String?

    enum CodingKeys: String, CodingKey {
        case id, type, actionId, employerId, employerName, actionType
        case organization, location, coordinates, distance, notificationRadius
        case startDate, endDate, description, demands, moreInfoUrl
        case locationName, locationType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        actionId = try container.decode(String.self, forKey: .actionId)
        employerId = try container.decode(String.self, forKey: .employerId)
        employerName = try container.decode(String.self, forKey: .employerName)
        actionType = try container.decode(String.self, forKey: .actionType)
        organization = try container.decodeIfPresent(String.self, forKey: .organization)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        coordinates = try container.decode(Coordinates.self, forKey: .coordinates)
        distance = try container.decode(Int.self, forKey: .distance)
        notificationRadius = try container.decode(Int.self, forKey: .notificationRadius)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        demands = try container.decodeIfPresent(String.self, forKey: .demands)
        moreInfoUrl = try container.decodeIfPresent(String.self, forKey: .moreInfoUrl)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        locationType = try container.decodeIfPresent(String.self, forKey: .locationType)
    }
}

struct BlocklistData: Codable {
    let totalUrls: Int
    let totalEmployers: Int
    let urls: [BlocklistEntry]
}

struct BlocklistEntry: Codable, Identifiable {
    var id: String { "\(employerId)-\(url)" }
    let url: String
    let employer: String
    let employerId: String
    let actionType: String
    let actionId: String
}

// MARK: - Active Strikes

struct ActiveStrikesResponse: Codable {
    let success: Bool
    let count: Int
    let generatedAt: String
    let strikes: [ActiveStrike]
}

struct ActiveStrike: Codable, Identifiable {
    let id: String
    let organization: String?
    let actionType: String
    let location: String?
    let employerName: String
    let employerId: String
    let startDate: String?
    let endDate: String?
    let description: String?

    var displayName: String {
        "\(employerName) — \(organization ?? actionType.capitalized)"
    }
}

// MARK: - GPS Snapshot

struct GpsSnapshotRequest: Codable {
    let actionId: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let notes: String?
}

struct GpsSnapshotResponse: Codable {
    let success: Bool
    let message: String
    let id: String
}

// MARK: - Strike Submission

struct StrikeSubmissionRequest: Codable {
    let employer: EmployerSubmission
    let action: ActionSubmission
}

struct EmployerSubmission: Codable {
    let name: String
    let industry: String?
    let website: String?
}

struct ActionSubmission: Codable {
    let organization: String
    let actionType: String
    let location: String
    let startDate: String
    let durationDays: Int
    let description: String
    let demands: String?
    let contactInfo: String?
    let learnMoreUrl: String?
    let coordinates: GpsCoordinates?
}

struct GpsCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct StrikeSubmissionResponse: Codable {
    let success: Bool
    let message: String
    let id: String
}

// MARK: - Geocoding

struct GeocodeRequest: Codable {
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let street: String?
}

struct GeocodeResponse: Codable {
    let success: Bool
    let input: String?
    let result: GeocodeResult?
}

struct GeocodeResult: Codable {
    let latitude: Double
    let longitude: Double
    let displayName: String?
    let confidence: Double?
    let source: String?
}

struct ReverseGeocodeRequest: Codable {
    let latitude: Double
    let longitude: Double
}

struct ReverseGeocodeResponse: Codable {
    let success: Bool
    let result: ReverseGeocodeResult?
}

struct ReverseGeocodeResult: Codable {
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let displayName: String?
}

// MARK: - Error

struct ApiErrorResponse: Codable {
    let error: String
}

// MARK: - Blocked Request Tracking

struct BlockedRequest: Identifiable {
    let id = UUID()
    let url: String
    let employer: String
    let actionType: String
    let timestamp: Date
    let appName: String?
    var userAction: UserAction

    enum UserAction {
        case pending, blocked, allowed
    }
}

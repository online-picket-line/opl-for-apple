import XCTest
@testable import OnlinePicketLine

final class AppStateTests: XCTestCase {
    
    // MARK: - Host Extraction & Blocklist Matching
    
    @MainActor
    func testFindBlockedUrlExactMatch() {
        let appState = createAppStateWithBlocklist([
            makeBlocklistEntry(url: "example.com", employer: "ExCo")
        ])
        
        let result = appState.findBlockedUrl("example.com")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.employer, "ExCo")
    }
    
    @MainActor
    func testFindBlockedUrlSubdomain() {
        let appState = createAppStateWithBlocklist([
            makeBlocklistEntry(url: "example.com", employer: "ExCo")
        ])
        
        let result = appState.findBlockedUrl("www.example.com")
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testFindBlockedUrlWithScheme() {
        let appState = createAppStateWithBlocklist([
            makeBlocklistEntry(url: "example.com", employer: "ExCo")
        ])
        
        let result = appState.findBlockedUrl("https://example.com")
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testFindBlockedUrlNoMatch() {
        let appState = createAppStateWithBlocklist([
            makeBlocklistEntry(url: "example.com", employer: "ExCo")
        ])
        
        let result = appState.findBlockedUrl("other.com")
        XCTAssertNil(result)
    }
    
    @MainActor
    func testFindBlockedUrlPartialName() {
        let appState = createAppStateWithBlocklist([
            makeBlocklistEntry(url: "example.com", employer: "ExCo")
        ])
        
        // "notexample.com" should NOT match "example.com"
        let result = appState.findBlockedUrl("notexample.com")
        XCTAssertNil(result)
    }
    
    @MainActor
    func testIsDomainBlocked() {
        let appState = createAppStateWithBlocklist([
            makeBlocklistEntry(url: "blocked.com", employer: "BlockedCo")
        ])
        
        XCTAssertTrue(appState.isDomainBlocked("blocked.com"))
        XCTAssertFalse(appState.isDomainBlocked("safe.com"))
    }
    
    @MainActor
    func testFindBlockedUrlCaseInsensitive() {
        let appState = createAppStateWithBlocklist([
            makeBlocklistEntry(url: "Example.COM", employer: "ExCo")
        ])
        
        let result = appState.findBlockedUrl("example.com")
        XCTAssertNotNil(result)
    }
    
    // MARK: - Region Refresh Check
    
    @MainActor
    func testShouldRefreshForLocationNilData() {
        let appState = AppState.shared
        appState.mobileData = nil
        let result = appState.shouldRefreshForLocation(lat: 0, lng: 0)
        XCTAssertTrue(result)
    }
    
    // MARK: - Cache Operations
    
    @MainActor
    func testClearCache() {
        let appState = AppState.shared
        appState.clearCache()
        XCTAssertNil(appState.mobileData)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func createAppStateWithBlocklist(_ entries: [BlocklistEntry]) -> AppState {
        let appState = AppState.shared
        appState.mobileData = MobileDataResponse(
            version: "1.0",
            cachedRegion: CachedRegion(
                center: Coordinates(lat: 0, lng: 0),
                radiusMeters: 160934,
                refreshThresholdMeters: 80000
            ),
            suggestedRefreshInterval: 3600000,
            geofences: GeofenceCollection(total: 0, byEmployer: [], all: []),
            blocklist: BlocklistData(totalUrls: entries.count, totalEmployers: 1, urls: entries),
            generatedAt: "2025-01-01T00:00:00Z"
        )
        return appState
    }
    
    private func makeBlocklistEntry(url: String, employer: String) -> BlocklistEntry {
        BlocklistEntry(
            url: url,
            employer: employer,
            employerId: "test-\(employer)",
            actionType: "strike",
            actionId: "act-1"
        )
    }
}

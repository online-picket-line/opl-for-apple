import Foundation
import Combine

/// Central app state manager. Owns cached data, blocklist, and geofence state.
@MainActor
final class AppState: ObservableObject {
    
    static let shared = AppState()
    
    @Published var mobileData: MobileDataResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var blockedRequests: [BlockedRequest] = []
    @Published var hasApiKey: Bool
    @Published var lastRefresh: Date?
    
    private var contentHash: String?
    private let api = APIClient.shared
    private let defaults = UserDefaults.standard
    
    private init() {
        hasApiKey = SecureStorage.shared.hasApiKey
        loadCachedData()
    }
    
    // MARK: - Data Refresh
    
    func refreshData() async {
        guard hasApiKey else { return }
        guard let location = LocationManager.shared.lastLocation else {
            errorMessage = "Location not available yet"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await api.getMobileData(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                hash: contentHash
            )
            
            switch result {
            case .success(let data, let hash):
                mobileData = data
                contentHash = hash
                lastRefresh = Date()
                cacheData(data, hash: hash)
            case .notModified:
                lastRefresh = Date()
                break // Keep using cached data
            }
        } catch {
            errorMessage = error.localizedDescription
            // Fall back to cached data
        }
        
        isLoading = false
    }
    
    // MARK: - API Key Management
    
    func setApiKey(_ key: String) {
        SecureStorage.shared.apiKey = key
        hasApiKey = true
    }
    
    func clearApiKey() {
        SecureStorage.shared.apiKey = nil
        hasApiKey = false
        mobileData = nil
        contentHash = nil
    }
    
    // MARK: - Blocklist Checking
    
    func findBlockedUrl(_ url: String) -> BlocklistEntry? {
        guard let entries = mobileData?.blocklist.urls else { return nil }
        guard let host = extractHost(url) else { return nil }
        
        return entries.first { entry in
            guard let entryHost = extractHost(entry.url) else { return false }
            return host == entryHost || host.hasSuffix(".\(entryHost)")
        }
    }
    
    func isDomainBlocked(_ domain: String) -> Bool {
        findBlockedUrl(domain) != nil
    }
    
    // MARK: - Geofence Checking
    
    func shouldRefreshForLocation(lat: Double, lng: Double) -> Bool {
        guard let region = mobileData?.cachedRegion else { return true }
        let distance = LocationManager.distance(
            from: (lat, lng),
            to: (region.center.lat, region.center.lng)
        )
        return distance > Double(region.refreshThresholdMeters)
    }
    
    // MARK: - Caching
    
    func clearCache() {
        defaults.removeObject(forKey: "opl_cached_data")
        defaults.removeObject(forKey: "opl_content_hash")
        mobileData = nil
        contentHash = nil
    }
    
    private func cacheData(_ data: MobileDataResponse, hash: String?) {
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: "opl_cached_data")
        }
        defaults.set(hash, forKey: "opl_content_hash")
    }
    
    private func loadCachedData() {
        contentHash = defaults.string(forKey: "opl_content_hash")
        guard let data = defaults.data(forKey: "opl_cached_data") else { return }
        mobileData = try? JSONDecoder().decode(MobileDataResponse.self, from: data)
    }
    
    private func extractHost(_ url: String) -> String? {
        let urlString = url.contains("://") ? url : "https://\(url)"
        guard let components = URLComponents(string: urlString) else { return nil }
        return components.host?
            .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
            .lowercased()
    }
}

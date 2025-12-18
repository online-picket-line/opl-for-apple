import Foundation
import Combine

/// Manager for handling labor dispute data and caching
class DisputeManager: ObservableObject {
    static let shared = DisputeManager()
    
    @Published var disputes: [LaborDispute] = []
    @Published var lastUpdate: Date?
    @Published var isLoading = false
    
    private let apiClient = APIClient.shared
    private let cacheKey = "cached_disputes"
    private let lastUpdateKey = "last_update_date"
    
    private init() {
        loadFromCache()
    }
    
    /// Fetch disputes from API
    func fetchDisputes() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let fetchedDisputes = try await apiClient.fetchDisputes()
            
            await MainActor.run {
                self.disputes = fetchedDisputes
                self.lastUpdate = Date()
                self.isLoading = false
                self.saveToCache()
            }
        } catch {
            print("Error fetching disputes: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    /// Find a dispute for a given URL
    func findDispute(for url: URL) -> LaborDispute? {
        guard let host = url.host else { return nil }
        
        return disputes.first { dispute in
            dispute.affectedDomains.contains { domain in
                // Check if the host matches or is a subdomain of the affected domain
                host == domain || host.hasSuffix(".\(domain)")
            }
        }
    }
    
    /// Check if a domain is affected by any dispute
    func isDomainAffected(_ domain: String) -> Bool {
        return disputes.contains { dispute in
            dispute.affectedDomains.contains { affectedDomain in
                domain == affectedDomain || domain.hasSuffix(".\(affectedDomain)")
            }
        }
    }
    
    /// Get all affected domains across all disputes
    func getAllAffectedDomains() -> Set<String> {
        var domains = Set<String>()
        for dispute in disputes {
            domains.formUnion(dispute.affectedDomains)
        }
        return domains
    }
    
    // MARK: - Caching
    
    private func saveToCache() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(disputes)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(lastUpdate, forKey: lastUpdateKey)
        } catch {
            print("Failed to save cache: \(error.localizedDescription)")
        }
    }
    
    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            disputes = try decoder.decode([LaborDispute].self, from: data)
            lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date
        } catch {
            print("Failed to load cache: \(error.localizedDescription)")
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: lastUpdateKey)
        disputes = []
        lastUpdate = nil
    }
}

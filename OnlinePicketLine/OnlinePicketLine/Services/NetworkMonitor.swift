import Foundation
import Combine
import Network

/// Network monitor for tracking outgoing traffic
/// Note: iOS restricts direct network interception without using VPN or Network Extension
/// This is a simplified monitoring approach that tracks user navigation
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isMonitoring = false
    @Published var blockedCount = 0
    @Published var currentBlockedURL: URL?
    
    private var blockedURLs: [BlockedURLRecord] = []
    private var allowedURLsThisSession: Set<String> = []
    private let blockedCountKey = "blocked_count"
    
    private init() {
        loadBlockedCount()
    }
    
    /// Start monitoring network activity
    func startMonitoring() {
        isMonitoring = true
        print("Network monitoring started")
    }
    
    /// Stop monitoring network activity
    func stopMonitoring() {
        isMonitoring = false
        print("Network monitoring stopped")
    }
    
    /// Check if a URL should be blocked
    func shouldBlockURL(_ url: URL) -> Bool {
        guard isMonitoring else { return false }
        
        // Check if already allowed this session
        if allowedURLsThisSession.contains(url.absoluteString) {
            return false
        }
        
        // Check with dispute manager
        if let dispute = DisputeManager.shared.findDispute(for: url) {
            recordBlockedURL(url, disputeId: dispute.id, wasAllowed: false)
            currentBlockedURL = url
            return true
        }
        
        return false
    }
    
    /// Allow the current blocked URL
    func allowCurrentURL() {
        guard let url = currentBlockedURL else { return }
        allowedURLsThisSession.insert(url.absoluteString)
        
        // Update the record to mark it as allowed
        if let dispute = DisputeManager.shared.findDispute(for: url) {
            recordBlockedURL(url, disputeId: dispute.id, wasAllowed: true)
        }
        
        currentBlockedURL = nil
    }
    
    /// Record a blocked URL attempt
    private func recordBlockedURL(_ url: URL, disputeId: String, wasAllowed: Bool) {
        let record = BlockedURLRecord(
            url: url.absoluteString,
            disputeId: disputeId,
            timestamp: Date(),
            wasAllowed: wasAllowed
        )
        
        blockedURLs.append(record)
        
        if !wasAllowed {
            blockedCount += 1
            saveBlockedCount()
        }
    }
    
    /// Get blocking statistics
    func getBlockingStats() -> (total: Int, allowed: Int, blocked: Int) {
        let allowed = blockedURLs.filter { $0.wasAllowed }.count
        let blocked = blockedURLs.filter { !$0.wasAllowed }.count
        return (total: blockedURLs.count, allowed: allowed, blocked: blocked)
    }
    
    /// Clear session-specific data
    func clearSession() {
        allowedURLsThisSession.removeAll()
        currentBlockedURL = nil
    }
    
    /// Reset all statistics
    func resetStatistics() {
        blockedURLs.removeAll()
        blockedCount = 0
        allowedURLsThisSession.removeAll()
        currentBlockedURL = nil
        saveBlockedCount()
    }
    
    // MARK: - Persistence
    
    private func saveBlockedCount() {
        UserDefaults.standard.set(blockedCount, forKey: blockedCountKey)
    }
    
    private func loadBlockedCount() {
        blockedCount = UserDefaults.standard.integer(forKey: blockedCountKey)
    }
}

/// Extension to help with URL domain extraction
extension URL {
    var domainWithoutWWW: String? {
        guard let host = self.host else { return nil }
        return host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
    }
}

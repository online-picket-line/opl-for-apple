import Foundation

/// Represents a company or organization involved in a labor action (from blocklist API)
struct LaborDispute: Identifiable, Codable {
    /// Unique employer or organization ID
    let id: String
    /// Employer or organization name
    let companyName: String
    /// Description or reason for the labor action
    let disputeDescription: String
    /// List of affected domains (from blocklist URLs)
    let affectedDomains: [String]
    /// Source/news URL for the action (from action resources, if available)
    let sourceURL: String?
    /// Start date of the action (if available)
    let startDate: Date?
    /// Tags or labels (from action resources, if available)
    let tags: [String]?
}

// DisputesResponse struct removed: not used with new unified API

/// Blocked URL record for tracking
struct BlockedURLRecord: Codable {
    let url: String
    let disputeId: String
    let timestamp: Date
    let wasAllowed: Bool
}

import Foundation

/// Represents a company involved in a labor dispute
struct LaborDispute: Codable, Identifiable {
    let id: String
    let companyName: String
    let disputeDescription: String
    let affectedDomains: [String]
    let sourceURL: String?
    let startDate: Date?
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case companyName = "company_name"
        case disputeDescription = "dispute_description"
        case affectedDomains = "affected_domains"
        case sourceURL = "source_url"
        case startDate = "start_date"
        case tags
    }
    
    init(id: String, companyName: String, disputeDescription: String, affectedDomains: [String], sourceURL: String? = nil, startDate: Date? = nil, tags: [String]? = nil) {
        self.id = id
        self.companyName = companyName
        self.disputeDescription = disputeDescription
        self.affectedDomains = affectedDomains
        self.sourceURL = sourceURL
        self.startDate = startDate
        self.tags = tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        companyName = try container.decode(String.self, forKey: .companyName)
        disputeDescription = try container.decode(String.self, forKey: .disputeDescription)
        affectedDomains = try container.decode([String].self, forKey: .affectedDomains)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        
        // Handle date decoding
        if let dateString = try container.decodeIfPresent(String.self, forKey: .startDate) {
            let formatter = ISO8601DateFormatter()
            startDate = formatter.date(from: dateString)
        } else {
            startDate = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(companyName, forKey: .companyName)
        try container.encode(disputeDescription, forKey: .disputeDescription)
        try container.encode(affectedDomains, forKey: .affectedDomains)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try container.encodeIfPresent(tags, forKey: .tags)
        
        if let date = startDate {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: date), forKey: .startDate)
        }
    }
}

/// Response wrapper for the API
struct DisputesResponse: Codable {
    let disputes: [LaborDispute]
    let lastUpdated: Date?
    
    enum CodingKeys: String, CodingKey {
        case disputes
        case lastUpdated = "last_updated"
    }
}

/// Blocked URL record for tracking
struct BlockedURLRecord: Codable {
    let url: String
    let disputeId: String
    let timestamp: Date
    let wasAllowed: Bool
}

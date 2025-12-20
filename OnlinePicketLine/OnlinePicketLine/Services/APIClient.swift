import Foundation

/// API Client for fetching labor dispute data

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited(retryAfter: Int?)
    case serverError
    case decodingError(Error)
    case unknownError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limit exceeded. Please wait \(seconds) seconds."
            } else {
                return "Rate limit exceeded. Please try again later."
            }
        case .serverError:
            return "Server error. Please try again later."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unknownError(let code):
            return "Unknown error (status code: \(code))"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    // Unified API endpoint for blocklist and action resources
    private let baseURL = "https://your-instance.com/api"

    private init() {}

    /// Fetch all active labor disputes (from unified /api/blocklist endpoint)
    func fetchDisputes() async throws -> [LaborDispute] {
        let endpoint = "\(baseURL)/blocklist?format=json"
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("OnlinePicketLine-iOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let blocklistResponse = try decoder.decode(BlocklistAPIResponse.self, from: data)
                // Convert blocklist entries to LaborDispute objects
                return blocklistResponse.toLaborDisputes()
            } catch {
                throw APIError.decodingError(error)
            }
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) }
            throw APIError.rateLimited(retryAfter: retryAfter)
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknownError(statusCode: httpResponse.statusCode)
        }
    }

    /// Search for disputes affecting a specific domain (client-side filter)
    func searchDisputesByDomain(_ domain: String) async throws -> [LaborDispute] {
        let allDisputes = try await fetchDisputes()
        return allDisputes.filter { dispute in
            dispute.affectedDomains.contains { affectedDomain in
                domain.hasSuffix(affectedDomain) || affectedDomain.hasSuffix(domain)
            }
        }
    }
}

// MARK: - Blocklist API Response Model

struct BlocklistAPIResponse: Codable {
    let version: String?
    let generatedAt: String?
    let totalUrls: Int?
    let employers: [Employer]?
    let blocklist: [BlocklistEntry]?
    let actionResources: ActionResources?

    struct Employer: Codable {
        let id: String?
        let name: String?
        let urlCount: Int?
    }

    struct BlocklistEntry: Codable {
        let url: String?
        let employer: String?
        let employerId: String?
        let label: String?
        let category: String?
        let reason: String?
    }

    struct ActionResources: Codable {
        let totalActions: Int?
        let totalResources: Int?
        let actions: [Action]?
        let resources: [Resource]?

        struct Action: Codable {
            let id: String?
            let organization: String?
            let actionType: String?
            let status: String?
            let resourceCount: Int?
        }

        struct Resource: Codable {
            let actionId: String?
            let actionType: String?
            let organization: String?
            let status: String?
            let url: String?
            let label: String?
            let description: String?
            let startDate: String?
            let endDate: String?
            let location: String?
        }
    }

    // Convert blocklist and action resources to [LaborDispute]
    func toLaborDisputes() -> [LaborDispute] {
        guard let blocklist = blocklist else { return [] }
        // Group blocklist entries by employerId
        let grouped = Dictionary(grouping: blocklist) { $0.employerId ?? "" }
        var disputes: [LaborDispute] = []
        for (employerId, entries) in grouped {
            let employerName = entries.first?.employer ?? "Unknown"
            let affectedDomains = entries.compactMap { entry in
                if let urlString = entry.url, let url = URL(string: urlString) {
                    return url.host
                }
                return nil
            }
            let disputeDescription = entries.first?.reason ?? "Labor action detected."
            // Find a related resource for sourceURL and tags
            let resource = actionResources?.resources?.first(where: { $0.organization == employerName })
            let sourceURL = resource?.url
            let startDate: Date? = {
                if let dateString = resource?.startDate {
                    let formatter = ISO8601DateFormatter()
                    return formatter.date(from: dateString)
                }
                return nil
            }()
            let tags: [String]? = resource?.label.map { [$0] }
            disputes.append(LaborDispute(
                id: employerId,
                companyName: employerName,
                disputeDescription: disputeDescription,
                affectedDomains: affectedDomains,
                sourceURL: sourceURL,
                startDate: startDate,
                tags: tags
            ))
        }
        return disputes
    }
}

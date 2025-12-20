import Foundation

/// API Client for fetching labor dispute data
class APIClient {
    static let shared = APIClient()
    
    // API endpoint - using GitHub raw content as a placeholder
    // In production, this would point to the actual Online Picket Line API
    private let baseURL = "https://raw.githubusercontent.com/online-picket-line/online-picketline/main"
    
    private init() {}
    
    /// Fetch all active labor disputes
    func fetchDisputes() async throws -> [LaborDispute] {
        // For now, return mock data since we can't access the actual API
        // In production, this would make a real API call
        
        // Simulated API endpoint
        let endpoint = "\(baseURL)/disputes.json"
        
        // Try to fetch from API, but fall back to mock data if unavailable
        do {
            guard let url = URL(string: endpoint) else {
                return getMockDisputes()
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                // If API fails, use mock data
                return getMockDisputes()
            }
            
            let decoder = JSONDecoder()
            let disputesResponse = try decoder.decode(DisputesResponse.self, from: data)
            return disputesResponse.disputes
        } catch {
            // Fall back to mock data
            print("Failed to fetch from API: \(error.localizedDescription)")
            return getMockDisputes()
        }
    }
    
    /// Search for disputes affecting a specific domain
    func searchDisputesByDomain(_ domain: String) async throws -> [LaborDispute] {
        let allDisputes = try await fetchDisputes()
        return allDisputes.filter { dispute in
            dispute.affectedDomains.contains { affectedDomain in
                domain.hasSuffix(affectedDomain) || affectedDomain.hasSuffix(domain)
            }
        }
    }
    
    /// Mock data for development and testing
    private func getMockDisputes() -> [LaborDispute] {
        return [
            LaborDispute(
                id: "1",
                companyName: "Example Retail Corp",
                disputeDescription: "Workers are on strike demanding better wages, healthcare benefits, and improved working conditions. The strike involves over 5,000 employees across multiple locations.",
                affectedDomains: [
                    "exampleretail.com",
                    "www.exampleretail.com",
                    "shop.exampleretail.com"
                ],
                sourceURL: "https://example.com/labor-news",
                startDate: Date(timeIntervalSinceNow: -86400 * 30),
                tags: ["strike", "retail", "wages"]
            ),
            LaborDispute(
                id: "2",
                companyName: "Tech Giant Industries",
                disputeDescription: "Software engineers and warehouse workers are protesting unfair labor practices and union-busting activities. Multiple labor law violations have been reported.",
                affectedDomains: [
                    "techgiant.com",
                    "www.techgiant.com",
                    "careers.techgiant.com"
                ],
                sourceURL: "https://example.com/tech-labor-dispute",
                startDate: Date(timeIntervalSinceNow: -86400 * 60),
                tags: ["union-busting", "tech", "labor-violations"]
            ),
            LaborDispute(
                id: "3",
                companyName: "Fast Food Chain",
                disputeDescription: "Restaurant workers across the chain are organizing for $15/hour minimum wage and better scheduling practices. Workers report unsafe working conditions.",
                affectedDomains: [
                    "fastfoodchain.com",
                    "www.fastfoodchain.com",
                    "order.fastfoodchain.com"
                ],
                sourceURL: "https://example.com/fast-food-workers",
                startDate: Date(timeIntervalSinceNow: -86400 * 15),
                tags: ["minimum-wage", "food-service", "safety"]
            )
        ]
    }
}

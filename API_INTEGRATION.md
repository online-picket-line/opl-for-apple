# API Integration Examples

This document provides examples of how to integrate with the Online Picket Line API once it's available.

## API Endpoint Structure

Based on the problem statement referencing `https://github.com/oplfun/online-picketline/blob/main/API_DOCUMENTATION.md`, the API should provide endpoints for querying labor dispute information.

## Expected API Response Format

The application expects the API to return JSON in the following format:

```json
{
  "disputes": [
    {
      "id": "unique-dispute-id",
      "company_name": "Company Name",
      "dispute_description": "Detailed description of the labor dispute, including worker demands and company responses.",
      "affected_domains": [
        "company.com",
        "www.company.com",
        "subdomain.company.com"
      ],
      "source_url": "https://news-source.com/article-about-dispute",
      "start_date": "2024-01-15T00:00:00Z",
      "tags": ["strike", "wages", "healthcare", "union"]
    }
  ],
  "last_updated": "2024-01-20T12:00:00Z",
  "total_count": 1
}
```

## Swift Integration Code

### Making API Requests

Here's how to update `APIClient.swift` to use the real API:

```swift
import Foundation

class APIClient {
    static let shared = APIClient()
    
    // Update this to the actual API endpoint
    private let baseURL = "https://api.online-picketline.org/v1"
    
    // If API requires authentication
    private var apiKey: String? {
        // Load from secure storage or environment
        return ProcessInfo.processInfo.environment["OPL_API_KEY"]
    }
    
    private init() {}
    
    /// Fetch all active labor disputes
    func fetchDisputes() async throws -> [LaborDispute] {
        let endpoint = "\(baseURL)/disputes"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication if required
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Add user agent
        request.setValue("OnlinePicketLine-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let disputesResponse = try decoder.decode(DisputesResponse.self, from: data)
            return disputesResponse.disputes
            
        case 401:
            throw APIError.unauthorized
            
        case 429:
            throw APIError.rateLimited
            
        case 500...599:
            throw APIError.serverError
            
        default:
            throw APIError.unknownError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Fetch disputes updated since a specific date
    func fetchDisputesSince(_ date: Date) async throws -> [LaborDispute] {
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        let endpoint = "\(baseURL)/disputes?since=\(dateString)"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let disputesResponse = try decoder.decode(DisputesResponse.self, from: data)
        return disputesResponse.disputes
    }
    
    /// Search for disputes by domain
    func searchDisputesByDomain(_ domain: String) async throws -> [LaborDispute] {
        let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? domain
        let endpoint = "\(baseURL)/disputes/search?domain=\(encodedDomain)"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let disputesResponse = try decoder.decode(DisputesResponse.self, from: data)
        return disputesResponse.disputes
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError
    case unknownError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized - check API credentials"
        case .rateLimited:
            return "Rate limit exceeded - please try again later"
        case .serverError:
            return "Server error - please try again later"
        case .unknownError(let statusCode):
            return "Unknown error (status code: \(statusCode))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
```

### Caching with ETags

For efficient API usage, implement ETag-based caching:

```swift
class APIClient {
    private var etag: String?
    private let etagKey = "api_etag"
    
    func fetchDisputesWithCache() async throws -> [LaborDispute] {
        let endpoint = "\(baseURL)/disputes"
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add If-None-Match header with stored ETag
        if let etag = UserDefaults.standard.string(forKey: etagKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            // New data available
            if let newEtag = httpResponse.value(forHTTPHeaderField: "ETag") {
                UserDefaults.standard.set(newEtag, forKey: etagKey)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let disputesResponse = try decoder.decode(DisputesResponse.self, from: data)
            return disputesResponse.disputes
            
        case 304:
            // Not modified - use cached data
            return DisputeManager.shared.disputes
            
        default:
            throw APIError.unknownError(statusCode: httpResponse.statusCode)
        }
    }
}
```

### Rate Limiting

Implement rate limiting to respect API quotas:

```swift
class APIClient {
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 300 // 5 minutes
    
    func fetchDisputesWithRateLimit() async throws -> [LaborDispute] {
        // Check if enough time has passed
        if let lastRequest = lastRequestTime,
           Date().timeIntervalSince(lastRequest) < minimumRequestInterval {
            // Return cached data if available
            if !DisputeManager.shared.disputes.isEmpty {
                return DisputeManager.shared.disputes
            }
        }
        
        // Proceed with API request
        let disputes = try await fetchDisputes()
        lastRequestTime = Date()
        return disputes
    }
}
```

### Error Handling in UI

Update `DisputeManager` to handle API errors gracefully:

```swift
class DisputeManager: ObservableObject {
    @Published var disputes: [LaborDispute] = []
    @Published var lastUpdate: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchDisputes() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetchedDisputes = try await apiClient.fetchDisputes()
            
            await MainActor.run {
                self.disputes = fetchedDisputes
                self.lastUpdate = Date()
                self.isLoading = false
                self.saveToCache()
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
                self.isLoading = false
            }
            print("API Error: \(error.errorDescription ?? "Unknown")")
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch disputes"
                self.isLoading = false
            }
            print("Error fetching disputes: \(error.localizedDescription)")
        }
    }
}
```

### Display Errors in UI

Update `ContentView` to show errors:

```swift
struct ContentView: View {
    @EnvironmentObject var disputeManager: DisputeManager
    
    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = disputeManager.errorMessage {
                    ErrorBanner(message: errorMessage)
                }
                
                // Rest of the UI
            }
        }
    }
}

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
```

## Testing API Integration

### Unit Tests

```swift
import XCTest
@testable import OnlinePicketLine

class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    
    override func setUp() {
        super.setUp()
        apiClient = APIClient.shared
    }
    
    func testFetchDisputes() async throws {
        let disputes = try await apiClient.fetchDisputes()
        XCTAssertFalse(disputes.isEmpty, "Should fetch at least one dispute")
    }
    
    func testSearchByDomain() async throws {
        let disputes = try await apiClient.searchDisputesByDomain("example.com")
        XCTAssertTrue(disputes.allSatisfy { dispute in
            dispute.affectedDomains.contains(where: { $0.contains("example.com") })
        })
    }
}
```

### Integration Testing

```swift
func testEndToEndFetch() async throws {
    // Start with empty cache
    DisputeManager.shared.clearCache()
    
    // Fetch from API
    await DisputeManager.shared.fetchDisputes()
    
    // Verify data is loaded
    XCTAssertFalse(DisputeManager.shared.disputes.isEmpty)
    XCTAssertNotNil(DisputeManager.shared.lastUpdate)
}
```

## API Documentation Reference

Once the Online Picket Line API documentation is available at:
https://github.com/oplfun/online-picketline/blob/main/API_DOCUMENTATION.md

Review it for:
- Authentication requirements
- Rate limits
- Available endpoints
- Response formats
- Error codes
- Versioning

## Production Checklist

- [ ] Update `baseURL` to production API
- [ ] Add API key management
- [ ] Implement proper error handling
- [ ] Add retry logic for failed requests
- [ ] Implement exponential backoff
- [ ] Add request timeout handling
- [ ] Test with real API data
- [ ] Monitor API usage and quotas
- [ ] Add analytics for API failures
- [ ] Document API integration in README

## Support

For API-specific questions:
- Check API documentation
- Open issue on online-picketline repository
- Contact API maintainers

For app integration questions:
- Open issue on opl-for-apple repository
- Review this integration guide
- Check DEVELOPER_GUIDE.md

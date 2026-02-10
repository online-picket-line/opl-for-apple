import Foundation

/// API client for the OPL Mobile API.
/// Handles all network requests with API key authentication and hash-based caching.
final class APIClient {

    static let shared = APIClient()

    #if DEBUG
    var baseURL = "https://onlinepicketline.com/api"
    #else
    let baseURL = "https://onlinepicketline.com/api"
    #endif

    private let session: URLSession
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        session = URLSession(configuration: config)
    }

    // MARK: - Mobile Data (blocklist + geofences)

    func getMobileData(
        latitude: Double,
        longitude: Double,
        radius: Int? = nil,
        hash: String? = nil
    ) async throws -> MobileDataResult {
        var components = URLComponents(string: "\(baseURL)/mobile/data")!
        var queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude))
        ]
        if let radius = radius {
            queryItems.append(URLQueryItem(name: "radius", value: String(radius)))
        }
        if let hash = hash {
            queryItems.append(URLQueryItem(name: "hash", value: hash))
        }
        components.queryItems = queryItems

        let request = authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OPLError.api(0, "Invalid response type")
        }

        if httpResponse.statusCode == 304 {
            return .notModified
        }

        try checkResponse(httpResponse, data: data)

        let mobileData = try decoder.decode(MobileDataResponse.self, from: data)
        let contentHash = httpResponse.value(forHTTPHeaderField: "X-Content-Hash")
        return .success(mobileData, hash: contentHash)
    }

    // MARK: - Active Strikes

    func getActiveStrikes() async throws -> [ActiveStrike] {
        let request = authenticatedRequest(url: URL(string: "\(baseURL)/mobile/active-strikes")!)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OPLError.api(0, "Invalid response type")
        }
        try checkResponse(httpResponse, data: data)

        let result = try decoder.decode(ActiveStrikesResponse.self, from: data)
        return result.strikes
    }

    // MARK: - GPS Snapshot

    func submitGpsSnapshot(_ snapshot: GpsSnapshotRequest) async throws -> GpsSnapshotResponse {
        let request = try authenticatedPostRequest(
            url: URL(string: "\(baseURL)/mobile/gps-snapshot")!,
            body: snapshot
        )
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OPLError.api(0, "Invalid response type")
        }
        try checkResponse(httpResponse, data: data)
        return try decoder.decode(GpsSnapshotResponse.self, from: data)
    }

    // MARK: - Strike Submission

    func submitStrike(_ submission: StrikeSubmissionRequest) async throws -> StrikeSubmissionResponse {
        let request = try authenticatedPostRequest(
            url: URL(string: "\(baseURL)/mobile/submit-strike")!,
            body: submission
        )
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OPLError.api(0, "Invalid response type")
        }
        try checkResponse(httpResponse, data: data)
        return try decoder.decode(StrikeSubmissionResponse.self, from: data)
    }

    // MARK: - Geocoding

    func geocode(address: String) async throws -> GeocodeResult {
        let request = try authenticatedPostRequest(
            url: URL(string: "\(baseURL)/mobile/geocode")!,
            body: GeocodeRequest(address: address, city: nil, state: nil, zipCode: nil, street: nil)
        )
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OPLError.api(0, "Invalid response type")
        }
        try checkResponse(httpResponse, data: data)
        let result = try decoder.decode(GeocodeResponse.self, from: data)
        guard let geocodeResult = result.result else {
            throw OPLError.notFound("No geocoding results found")
        }
        return geocodeResult
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> ReverseGeocodeResult {
        let request = try authenticatedPostRequest(
            url: URL(string: "\(baseURL)/mobile/reverse-geocode")!,
            body: ReverseGeocodeRequest(latitude: latitude, longitude: longitude)
        )
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OPLError.api(0, "Invalid response type")
        }
        try checkResponse(httpResponse, data: data)
        let result = try decoder.decode(ReverseGeocodeResponse.self, from: data)
        guard let reverseResult = result.result else {
            throw OPLError.notFound("No reverse geocoding results found")
        }
        return reverseResult
    }

    // MARK: - API Key Configuration

    func setApiKey(_ key: String?) {
        // Rebuild session isn't needed since we read from SecureStorage per request
    }

    /// Convenience: fetch mobile data without location (uses default coordinates).
    func getMobileData() async throws -> MobileDataResponse {
        let result = try await getMobileData(latitude: 0, longitude: 0)
        switch result {
        case .success(let data, _): return data
        case .notModified: throw OPLError.api(304, "Not modified")
        }
    }

    // MARK: - Helpers

    private func authenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let apiKey = SecureStorage.shared.apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        request.setValue("OPL-iOS/\(version)", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func authenticatedPostRequest<T: Encodable>(url: URL, body: T) throws -> URLRequest {
        var request = authenticatedRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func checkResponse(_ response: HTTPURLResponse, data: Data) throws {
        guard (200...299).contains(response.statusCode) else {
            if let apiError = try? decoder.decode(ApiErrorResponse.self, from: data) {
                throw OPLError.api(response.statusCode, apiError.error)
            }
            throw OPLError.api(response.statusCode, "Request failed with status \(response.statusCode)")
        }
    }
}

// MARK: - Result Types

enum MobileDataResult {
    case success(MobileDataResponse, hash: String?)
    case notModified
}

// MARK: - Errors

enum OPLError: LocalizedError {
    case api(Int, String)
    case notFound(String)
    case noApiKey

    var errorDescription: String? {
        switch self {
        case .api(let code, let message): return "[\(code)] \(message)"
        case .notFound(let message): return message
        case .noApiKey: return "API key not configured"
        }
    }
}

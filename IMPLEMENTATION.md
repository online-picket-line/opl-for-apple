# Implementation Guide: Network Filtering for Labor Dispute Detection

## Overview

This document explains how the Online Picket Line iOS application works and provides guidance for implementing system-wide network filtering in a production environment.

## Current Implementation

### Architecture

The current implementation provides a foundation with:

1. **User Interface**: Complete SwiftUI-based UI for displaying disputes and alerts
2. **Data Management**: API client and dispute manager with caching
3. **Domain Matching**: Logic to match URLs against labor dispute domains
4. **User Flow**: Alert system with user choice (block or allow)

### How It Works

1. **App Launch**: 
   - Fetches latest labor disputes from API (currently using mock data)
   - Caches disputes locally for offline access
   - Starts network monitoring service

2. **Domain Checking**:
   - When a URL needs to be checked, `NetworkMonitor.shouldBlockURL()` is called
   - The URL's domain is compared against all affected domains in the dispute database
   - If a match is found, an alert is shown to the user

3. **User Decision**:
   - User can choose to "Respect the Picket Line" (block)
   - Or "Proceed Anyway" (allow for this session)
   - Choice is tracked for statistics

## Production Implementation Strategies

### Option 1: Safari Content Blocker Extension (Recommended for Safari Only)

**Pros**: 
- Works with Safari without VPN
- Efficient, uses Apple's native content blocking
- Good battery life

**Cons**:
- Only works in Safari, not other apps
- Limited to pattern-based blocking
- Cannot show custom UI during blocking

**Implementation**:
1. Create a Content Blocker Extension target
2. Generate blocking rules from dispute database
3. Update rules when disputes change
4. Users enable the extension in Safari settings

**Code Example**:
```swift
// Generate content blocker rules
func generateBlockingRules() -> [[String: Any]] {
    let domains = DisputeManager.shared.getAllAffectedDomains()
    return domains.map { domain in
        [
            "trigger": [
                "url-filter": ".*\(domain).*",
                "resource-type": ["document"]
            ],
            "action": [
                "type": "block"
            ]
        ]
    }
}
```

### Option 2: Network Extension with DNS Filtering

**Pros**:
- Works across all apps
- Can intercept at DNS level
- Less battery intensive than VPN

**Cons**:
- Requires Network Extension entitlement from Apple
- Complex setup and configuration
- Cannot inspect HTTPS content

**Implementation**:
1. Apply for Network Extension entitlement
2. Create `NEDNSProxyProvider` subclass
3. Implement DNS filtering logic
4. Handle DNS queries and filter based on dispute database

**Code Outline**:
```swift
import NetworkExtension

class LaborDisputeDNSProvider: NEDNSProxyProvider {
    override func startProxy(options: [String: Any]?, completionHandler: @escaping (Error?) -> Void) {
        // Initialize dispute database
        // Start DNS proxy
        completionHandler(nil)
    }
    
    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        // Check if domain is in dispute
        // Return false to block, true to allow
        return true
    }
}
```

### Option 3: VPN-based Network Extension

**Pros**:
- Complete control over all network traffic
- Can show custom alerts
- Works across all apps

**Cons**:
- Most battery intensive
- Complex to implement
- Privacy concerns (requires user trust)
- Difficult App Store approval

**Implementation**:
1. Create `NETunnelProvider` subclass
2. Establish VPN tunnel
3. Filter packets based on destination
4. Communicate with main app for alerts

### Option 4: WKWebView Integration (Hybrid Approach)

**Pros**:
- Works for in-app browsing
- Can inject custom JavaScript
- Full control over web content

**Cons**:
- Only works within your app
- Not system-wide
- Users must browse within your app

**Implementation**:
```swift
class DisputeAwareWebView: WKWebView {
    override func load(_ request: URLRequest) -> WKNavigation? {
        if let url = request.url,
           NetworkMonitor.shared.shouldBlockURL(url) {
            // Show dispute alert
            // Return nil to cancel load
            return nil
        }
        return super.load(request)
    }
}
```

## Recommended Approach

For a production implementation of the Online Picket Line app, we recommend a **two-tier approach**:

### Tier 1: Safari Content Blocker (Immediate)
- Implement Safari Content Blocker extension
- Quick to develop and release
- Works for Safari users immediately
- No special entitlements needed

### Tier 2: Network Extension (Long-term)
- Apply for Network Extension entitlement
- Implement DNS-based filtering
- Provide system-wide protection
- Better user experience

## Security and Privacy Considerations

### Data Protection
- Never transmit user browsing data
- Store dispute database locally
- Encrypt sensitive data
- Clear cache on app deletion

### User Trust
- Be transparent about what is monitored
- Provide clear privacy policy
- Allow users to disable monitoring
- Show exactly what data is collected

### SSL/TLS Handling
- Do NOT attempt to break SSL/TLS encryption
- Filter at DNS or domain level only
- Respect certificate pinning
- Never implement a MITM attack

## Testing Strategy

### Unit Tests
```swift
func testDomainMatching() {
    let dispute = LaborDispute(
        id: "1",
        companyName: "Test Corp",
        disputeDescription: "Test dispute",
        affectedDomains: ["example.com"]
    )
    
    let manager = DisputeManager.shared
    manager.disputes = [dispute]
    
    XCTAssertTrue(manager.isDomainAffected("example.com"))
    XCTAssertTrue(manager.isDomainAffected("www.example.com"))
    XCTAssertFalse(manager.isDomainAffected("other.com"))
}
```

### Integration Tests
- Test API integration with real endpoints
- Verify caching mechanism
- Test offline functionality
- Validate alert flow

### UI Tests
- Test user can enable/disable monitoring
- Verify alerts appear correctly
- Test "block" and "allow" actions
- Validate settings persistence

## App Store Submission

### Required Documentation
1. **Privacy Policy**: Explain what data is monitored
2. **App Review Notes**: Explain the app's purpose
3. **Demo Video**: Show the app in action
4. **Test Account**: If API authentication is required

### Common Rejection Reasons
1. Insufficient privacy disclosure
2. Unclear app purpose
3. Potential for misuse
4. Network Extension without justification
5. Political content concerns

### Approval Tips
- Emphasize educational purpose
- Focus on worker rights and labor information
- Provide detailed privacy policy
- Show clear user controls
- Demonstrate responsible use

## API Integration

### Connecting to Real API

Update `APIClient.swift`:
```swift
private let baseURL = "https://api.online-picketline.org/v1"

func fetchDisputes() async throws -> [LaborDispute] {
    guard let url = URL(string: "\(baseURL)/disputes") else {
        throw APIError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    // Add authentication if required
    // request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw APIError.serverError
    }
    
    let decoder = JSONDecoder()
    return try decoder.decode(DisputesResponse.self, from: data).disputes
}
```

### Rate Limiting
- Cache disputes locally
- Only fetch updates every few hours
- Implement exponential backoff on errors
- Use ETags for conditional requests

### Error Handling
- Gracefully handle API failures
- Fall back to cached data
- Show user-friendly error messages
- Log errors for debugging

## Performance Optimization

### Battery Life
- Minimize network requests
- Use efficient data structures for domain matching
- Avoid continuous polling
- Implement smart caching

### Memory Usage
- Limit dispute cache size
- Clean up old records
- Use weak references where appropriate
- Profile memory usage regularly

### Network Efficiency
- Use compression for API responses
- Implement delta updates
- Cache DNS results
- Minimize redundant checks

## Future Enhancements

1. **Machine Learning**: Train model to predict dispute likelihood
2. **Community Reports**: Allow users to report new disputes
3. **Union Integration**: Partner with unions for verified data
4. **International Support**: Multi-language and multi-region disputes
5. **Analytics Dashboard**: Aggregate statistics (privacy-preserving)
6. **Notification System**: Alert users of new disputes
7. **Widget Support**: Home screen widget with stats
8. **Watch App**: Apple Watch companion app

## Resources

- [Apple Network Extension Programming Guide](https://developer.apple.com/documentation/networkextension)
- [Safari Content Blocker Documentation](https://developer.apple.com/documentation/safariservices/creating_a_content_blocker)
- [iOS App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)

## Support

For questions or issues:
- Open an issue on GitHub
- Contact: [project maintainers]
- Documentation: [project wiki]

## License

This implementation guide is part of the Online Picket Line for Apple project and follows the same license.

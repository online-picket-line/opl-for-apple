# Online Picket Line for Apple iOS

An iOS application that helps users support workers' rights by alerting them when they're about to access a company involved in a labor dispute.

## Overview

This application monitors outgoing traffic and checks against the [Online Picket Line API](https://github.com/oplfun/online-picketline) to inform users when they're accessing a company currently under a labor dispute. When a match is found, the user is presented with information about the dispute and can choose to respect the picket line or proceed anyway.

## Features

- 🛡️ **Traffic Monitoring**: Monitors network requests to detect access to companies in labor disputes
- 📋 **Labor Dispute Database**: Fetches and caches current labor disputes from the Online Picket Line API
- ⚠️ **User Alerts**: Displays detailed information about labor disputes when detected
- 🎯 **User Choice**: Allows users to choose whether to block or proceed with the connection
- 📊 **Statistics**: Tracks blocked sites and active disputes
- 🔄 **Offline Support**: Caches dispute data for offline access
- ⚙️ **Settings**: Configurable monitoring and notification preferences

## Architecture

The application is built using SwiftUI and follows the MVVM pattern:

### Core Components

- **OnlinePicketLineApp.swift**: Main application entry point
- **ContentView.swift**: Main dashboard showing protection status and active disputes
- **DisputeAlertView.swift**: Alert dialog displayed when a disputed site is detected
- **SettingsView.swift**: Configuration and preferences

### Models

- **DisputeModels.swift**: Data models for labor disputes and API responses
  - `LaborDispute`: Represents a company in a labor dispute
  - `DisputesResponse`: API response wrapper
  - `BlockedURLRecord`: Tracking blocked URL attempts

### Services

- **APIClient.swift**: Handles communication with the Online Picket Line API
- **DisputeManager.swift**: Manages dispute data, caching, and domain matching
- **NetworkMonitor.swift**: Monitors network activity and triggers alerts

## Technical Limitations

### iOS Network Interception Constraints

**Important**: Due to iOS security and privacy restrictions, this application has limitations compared to traditional network filtering applications:

1. **No System-Wide Traffic Interception**: iOS does not allow apps to intercept all network traffic without:
   - Implementing a VPN connection (requires Network Extension entitlements)
   - Using Network Extension framework with DNS filtering (requires special Apple approval)
   - Using on-device content filtering (limited to Safari and WKWebView)

2. **Current Implementation**: This version demonstrates the user interface and logic for labor dispute detection. In a production environment, you would need to:
   - Apply for Network Extension entitlements from Apple
   - Implement a Network Extension Provider for DNS filtering or VPN
   - Handle complex certificate pinning and HTTPS inspection (which has privacy implications)
   - Submit your app for App Store review with detailed privacy explanations

3. **Browser Integration**: To make this work in Safari, you would need to:
   - Create a Safari Content Blocker Extension
   - Register URL patterns as blocking rules
   - Update rules when the dispute database changes

### Production Considerations

For a production implementation, consider:

1. **Network Extension**: Implement `NEFilterDataProvider` for content filtering
2. **MDM Integration**: Deploy as a Mobile Device Management (MDM) configuration for enterprise users
3. **Privacy Policy**: Clearly communicate what data is monitored and how it's used
4. **API Integration**: Connect to the actual Online Picket Line API endpoint
5. **Certificate Handling**: Properly handle SSL/TLS without compromising security
6. **Battery Impact**: Optimize monitoring to minimize battery drain

## Building and Running

### Prerequisites

- macOS with Xcode 15.0 or later
- iOS 16.0 or later target device/simulator
- Apple Developer account (for Network Extension entitlements in production)

### Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/oplfun/opl-for-apple.git
   cd opl-for-apple
   ```

2. Open the project in Xcode:
   ```bash
   open OnlinePicketLine/OnlinePicketLine.xcodeproj
   ```

3. Select your target device or simulator

4. Build and run (⌘R)

### Development Mode

The application currently uses mock data for demonstration. To connect to a real API:

1. Update the `baseURL` in `APIClient.swift` to point to your API endpoint
2. Ensure your API matches the expected JSON format defined in `DisputeModels.swift`
3. Update the `Info.plist` to allow network access to your API domain

## API Integration

The application expects the Online Picket Line API to return data in the following format:

```json
{
  "disputes": [
    {
      "id": "unique-id",
      "company_name": "Company Name",
      "dispute_description": "Description of the labor dispute",
      "affected_domains": [
        "example.com",
        "www.example.com"
      ],
      "source_url": "https://source.com/article",
      "start_date": "2024-01-01T00:00:00Z",
      "tags": ["strike", "wages"]
    }
  ],
  "last_updated": "2024-01-15T12:00:00Z"
}
```

## Usage

1. **First Launch**: The app will fetch the latest labor disputes
2. **Enable Protection**: Toggle monitoring in Settings (enabled by default)
3. **Browse Normally**: When you attempt to access a site involved in a labor dispute, you'll see an alert
4. **Make Your Choice**: 
   - "Respect the Picket Line" - Block the connection
   - "Proceed Anyway" - Allow the connection for this session
5. **Review Statistics**: Check the main screen for blocking statistics and active disputes

## Privacy

This application:
- Only checks domains against the labor dispute database
- Does not collect or transmit personal browsing data
- Stores dispute data locally for offline access
- Does not share data with third parties

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

This project is open source. Please see the LICENSE file for details.

## Support Workers' Rights

This application is designed to help users make informed decisions about supporting companies involved in labor disputes. By using this app, you're standing in solidarity with workers fighting for fair wages, safe working conditions, and the right to organize.

## Acknowledgments

- Online Picket Line project for maintaining the labor dispute database
- Workers and unions fighting for labor rights worldwide

## Disclaimer

This application provides information about labor disputes for educational and informational purposes. Users should verify information independently and make their own decisions about which companies to support. The developers are not responsible for the accuracy of dispute information or any consequences of using this application.

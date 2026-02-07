# Online Picket Line for iOS

Native iOS application that helps workers stand in solidarity with active labor disputes. The app provides GPS-based proximity alerts for nearby picket lines, allows users to submit strike reports and GPS location snapshots, and alerts users when accessing employers with active disputes.

## Features

- **Solidarity Alerts**: Notifies users when accessing employers with active labor disputes via in-app blocklist checking
- **GPS Strike Proximity Alerts**: Monitors your location and alerts you when within a configurable radius of an active picket line (default 100 miles)
- **GPS Snapshot**: Submit your GPS coordinates to augment strike location data
- **Strike Submission**: Report new labor actions through a built-in submission wizard
- **Hash-Based Caching**: Efficient data syncing using SHA-256 content hashes and HTTP 304 responses
- **Secure API Key Storage**: Keychain-based storage for API credentials

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.0+
- API key from your OPL administrator

## Building

### Prerequisites

- macOS with Xcode 15+
- Apple Developer account (for device testing)

### Build Steps

```bash
git clone https://github.com/oplfun/opl-for-apple.git
cd opl-for-apple/OnlinePicketLine

# Build
xcodebuild -scheme OnlinePicketLine -configuration Debug build

# Run tests
xcodebuild -scheme OnlinePicketLineTests -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Or open `OnlinePicketLine.xcodeproj` in Xcode and build/run from there.

## Architecture

```
OnlinePicketLine/
├── OnlinePicketLineApp.swift    # Entry point with API key gating
├── Models/
│   └── Models.swift             # All API data models (Codable)
├── Services/
│   ├── APIClient.swift          # URLSession-based API client with caching
│   ├── AppState.swift           # Central ObservableObject state manager
│   ├── LocationManager.swift    # CLLocationManager + geofence proximity
│   └── SecureStorage.swift      # Keychain-based secure storage
├── Views/
│   ├── MainTabView.swift        # Tab navigation (Dashboard, GPS, Report, Settings)
│   ├── DashboardView.swift      # Stats, nearby strikes, geofence cards
│   ├── GpsSnapshotView.swift    # GPS snapshot submission form
│   ├── SubmitStrikeView.swift   # Strike submission wizard
│   ├── SettingsView.swift       # App settings and API key management
│   ├── ApiKeySetupView.swift    # First-launch API key entry
│   └── BlockAlertView.swift     # Solidarity alert sheet
└── Tests/
    ├── ModelsTests.swift        # Model serialization tests
    ├── AppStateTests.swift      # Blocklist matching tests
    ├── APIClientTests.swift     # URL construction + error type tests
    └── LocationManagerTests.swift # Distance calculation tests
```

### Key Technologies

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.0 |
| UI Framework | SwiftUI |
| State Management | Combine + ObservableObject |
| Networking | URLSession (async/await) |
| Location | CoreLocation (CLLocationManager) |
| Notifications | UserNotifications |
| Secure Storage | Security framework (Keychain) |

## API Integration

The app communicates with the OPL Mobile API using an `X-API-Key` header. Keys use the format `opl_` + 64 hex characters (68 chars total).

### Endpoints

| Method | Endpoint | Scope | Description |
|--------|----------|-------|-------------|
| GET | `/api/mobile/data` | `read:mobile` | Combined blocklist + geofences |
| GET | `/api/mobile/active-strikes` | `read:mobile` | List of active strikes |
| POST | `/api/mobile/gps-snapshot` | `write:gps-snapshot` | Submit GPS location snapshot |
| POST | `/api/mobile/submit-strike` | `write:submit-strike` | Submit new strike report |
| POST | `/api/mobile/geocode` | `read:mobile` | Forward geocoding |
| POST | `/api/mobile/reverse-geocode` | `read:mobile` | Reverse geocoding |

## Usage

1. **API Key Setup**: Enter your API key on first launch
2. **Dashboard**: View active strikes nearby and blocklist statistics
3. **GPS Snapshot**: Submit your current location to verify strike activity
4. **Report Strike**: Submit new strike reports with location and details
5. **Settings**: Manage notification radius, API key, and cached data

## Testing

```bash
# Run tests via Xcode command line
xcodebuild test \
  -scheme OnlinePicketLineTests \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Tests cover:
- Data model encoding/decoding (JSON round-trips)
- Blocklist domain matching (exact, subdomain, case-insensitive)
- API error types and descriptions
- GPS distance calculations (Haversine)

## iOS Platform Notes

iOS does not allow system-wide traffic interception without a Network Extension entitlement (which requires special Apple approval). The current version uses an in-app blocklist approach: when the app detects a user is near or accessing a blocked employer, it shows a solidarity alert. Full DNS-level filtering is possible with the Network Extension entitlement — see [APP_STORE_SUBMISSION.md](doc/APP_STORE_SUBMISSION.md) for the entitlement request process.

## Security

- API keys stored in iOS Keychain (hardware-backed encryption)
- All network traffic uses HTTPS with URLSession defaults (ATS enforced)
- No browsing history stored or transmitted
- Location data only used for proximity alerts and GPS snapshots
- API key format validated before use (`opl_` prefix, 68 chars)

## License

GPL-3.0 — see [LICENSE](../opl-for-android/LICENSE)

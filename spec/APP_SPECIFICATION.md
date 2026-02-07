# Online Picket Line for iOS — App Specification

## Overview

A native iOS application for the Online Picket Line labor action coordination platform. The app provides Network Extension-based traffic filtering, GPS geofencing for strike proximity alerts, and tools for submitting GPS snapshots and new strikes.

## Version

- **Semantic Versioning**: `vMAJOR.MINOR.PATCH`
- **Current**: `v0.1.0` (pre-release)
- **Minimum deployment target**: iOS 16.0
- **Build with**: Xcode 15+, Swift 5.9+

## Features

### 1. Network Extension-Based Traffic Filtering

**Purpose**: Analyze network traffic to identify connections to employers involved in active labor actions.

**Implementation**:
- `NEPacketTunnelProvider` — Local VPN tunnel for DNS interception
- `NEFilterDataProvider` — Content filter for domain-level blocking
- DNS request interception to check domains against the cached blocklist
- App attribution via `NEFilterFlow.sourceAppIdentifier` where available
- Displays a notification with:
  - The employer name and labor action details
  - The app attempting the connection (when identifiable)
  - Options to "Proceed" or "Block"

**User Experience**:
- Block Page: Full-screen overlay showing strike information with options to proceed or go back
- Banner Mode: Non-intrusive notification banner with action details
- User can configure default behavior (always ask, always block, always allow)

**Blocklist Data Source**: `GET /api/mobile/data?lat={lat}&lng={lng}`

### 2. GPS Geofencing & Strike Proximity Alerts

**Purpose**: Notify users when approaching physical strike locations.

**Implementation**:
- Uses `CLLocationManager` with `startMonitoringSignificantLocationChanges()`
- Region monitoring via `CLCircularRegion` (up to 20 regions monitored simultaneously)
- Fetches regional data (100-mile radius) from `/api/mobile/data`
- Performs on-device geofence detection to minimize API calls
- Refreshes data when:
  - User moves beyond 80% of cached region radius
  - Periodic interval (hourly) with hash-based change detection
  - App restart or cache clear

**Notifications**:
- "🚨 Entering Strike Zone" — `didEnterRegion` callback
- "📍 Near Strike" — proximity check within notification radius
- "✅ Leaving Strike Zone" — `didExitRegion` callback

**iOS Region Monitoring Limit**: Maximum 20 monitored regions. The app prioritizes the closest strikes and rotates regions as the user moves.

### 3. GPS Snapshot Submission

**Purpose**: Allow users to submit GPS location data to augment strike information.

**Flow**:
1. User taps "Submit GPS Snapshot" button
2. App shows list of active strikes from `/api/mobile/active-strikes`
3. User selects the relevant strike
4. Options:
   a. **Current Location**: Uses device GPS to get coordinates
   b. **Manual Entry**: Text field for address with geocode button
   c. **Map Picker**: Interactive MapKit view to drop a pin
5. Optional notes field
6. Submit via `POST /api/mobile/gps-snapshot`
7. Confirmation message: "Snapshot submitted for moderation"

**Manual Entry Geocoding**:
- Address-to-GPS: `POST /api/mobile/geocode` with address string or components
- GPS-to-address: `POST /api/mobile/reverse-geocode` for coordinate verification
- Also supports `CLGeocoder` for on-device geocoding

### 4. Strike Submission

**Purpose**: Allow users to submit new labor actions from the mobile app.

**Data Model** (matches web submission wizard):
- **Employer**: name (required), industry (optional), website (optional)
- **Action**: organization (required), actionType, location (required), startDate (required), durationDays, description (required), demands, contactInfo, learnMoreUrl, coordinates (optional)

**Flow**:
1. User taps "Report a Strike"
2. Step 1: Employer details (name, industry, website)
3. Step 2: Action details (organization, type, location, dates, description, demands)
4. Step 3: Optional GPS coordinates (current location or manual entry)
5. Review and submit via `POST /api/mobile/submit-strike`
6. Confirmation: "Submitted for moderation"

### 5. Data Caching & Sync

**Strategy**: Minimal messaging design for battery efficiency.

- Cache regional data in `UserDefaults` or Core Data
- Hash-based change detection (`X-Content-Hash` header)
- 304 Not Modified support to minimize data transfer
- Background sync via `BGAppRefreshTask` with battery-aware scheduling

## API Integration

### Authentication
- API key stored in iOS Keychain
- Sent via `X-API-Key` header on all requests

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/mobile/data` | GET | Blocklist + geofences + caching |
| `/api/mobile/active-strikes` | GET | Active strikes for snapshot selection |
| `/api/mobile/gps-snapshot` | POST | Submit GPS location data |
| `/api/mobile/submit-strike` | POST | Submit new labor action |
| `/api/mobile/geocode` | POST | Address to GPS conversion |
| `/api/mobile/reverse-geocode` | POST | GPS to address conversion |

## Entitlements & Capabilities

| Capability | Reason |
|------------|--------|
| Network Extensions | Local DNS filtering and traffic analysis |
| Personal VPN | Packet Tunnel Provider for DNS interception |
| Location Services | GPS geofencing and strike proximity |
| Background Modes | Location updates, background fetch |
| Push Notifications | Strike proximity alerts |
| Keychain Sharing | Secure API key storage |

## Info.plist Keys

| Key | Value |
|-----|-------|
| `NSLocationWhenInUseUsageDescription` | "Online Picket Line uses your location to alert you when you are near an active strike or picket line." |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | "Online Picket Line needs background location access to notify you when approaching strike zones, even when the app is not open." |
| `NSLocationAlwaysUsageDescription` | "Background location enables strike proximity alerts while the app is in the background." |

## Privacy & Security

- Network Extension operates locally (no remote proxy, no traffic forwarding)
- DNS queries analyzed on-device only
- GPS location only sent to server on explicit user action (snapshot)
- No user accounts or personal data stored
- No analytics or tracking SDKs
- API keys encrypted at rest using iOS Keychain Services
- App Transport Security (ATS) enforced for all connections

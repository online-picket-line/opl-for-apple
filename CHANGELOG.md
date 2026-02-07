# Changelog

All notable changes to the Online Picket Line iOS app will be documented in this file.

This project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2025-01-01

### Added
- Complete native iOS app with SwiftUI interface
- GPS proximity alerts for active picket lines within configurable radius (default 100 miles)
- GPS Snapshot feature for submitting location data to augment strike information
- Strike submission wizard for reporting new labor actions
- Dashboard with active strike statistics and nearby geofence cards
- Solidarity alert view for blocked employer domains
- Settings view with notification radius slider, GPS toggle, and API key management
- API key setup flow with validation on first launch
- Keychain-based secure storage for API credentials
- Hash-based caching (SHA-256) with HTTP 304 support for efficient data sync
- Geocoding and reverse geocoding via OPL Mobile API
- Tab-based navigation (Dashboard, GPS Snapshot, Report Strike, Settings)
- Unit tests for models, blocklist matching, API client, and distance calculations
- CI/CD workflow with lint (SwiftLint), test, security (CodeQL), build, and release jobs
- App Store submission guide with Network Extension entitlement instructions

### Technical Details
- Swift 5.0, iOS 16.0+ deployment target
- SwiftUI with Combine for reactive state management
- URLSession with async/await for networking
- CoreLocation for GPS monitoring and proximity alerts
- UserNotifications for strike proximity notifications
- Security framework (Keychain) for API key storage
- Bundle ID: com.onlinepicketline.opl

# Apple App Store Submission Guide

This document provides step-by-step instructions for submitting the Online Picket Line iOS app to the Apple App Store.

## Prerequisites

1. **Apple Developer Program membership** ($99/year)
   - Enroll at https://developer.apple.com/programs/
2. **Xcode 15+** with iOS 17 SDK
3. **App Store Connect access**
4. **Network Extension entitlement** (requires approval from Apple — see below)

## Step 0: Network Extension Entitlement

**Important**: Before building the app, you must request the Network Extension entitlement from Apple.

1. Go to https://developer.apple.com/contact/request/network-extension/
2. Fill out the request form:
   - **App name**: Online Picket Line
   - **Extension type**: Packet Tunnel Provider, Content Filter Provider
   - **Purpose**: Local network traffic analysis for labor action awareness
   - **Traffic routing**: Local only — no traffic is routed to external servers
3. Wait for Apple's approval (typically 1-2 weeks)
4. Once approved, the entitlement appears in your developer account's provisioning profile settings

## Step 1: Create the App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Fill in the details:
   - **Platforms**: iOS
   - **Name**: `Online Picket Line`
   - **Primary language**: English (U.S.)
   - **Bundle ID**: Select or create (e.g., `org.onlinepicketline.app`)
   - **SKU**: `opl-ios-001`
4. Click **"Create"**

## Step 2: App Information

### General Information
- **Name**: `Online Picket Line`
- **Subtitle**: `Stand with striking workers`
- **Category**: Social Networking (Primary), Utilities (Secondary)
- **Content Rights**: Does not contain third-party content that requires rights

### Privacy Policy
- **URL**: (host at a public URL)
- Must cover:
  - VPN/Network Extension usage (local-only, no traffic forwarding)
  - Location data usage (on-device only, explicit user action to transmit)
  - No user accounts or personal data collection
  - No analytics or tracking

## Step 3: App Store Listing

### Description
- **Promotional Text** (170 chars, can be updated without new build):
  > Get real-time alerts about active strikes and labor actions near you. Stand in solidarity with workers fighting for fair wages and conditions.

- **Description** (4000 chars max):
  > Online Picket Line helps you stand in solidarity with workers engaged in labor actions. The app provides:
  >
  > STRIKE PROXIMITY ALERTS
  > Receive notifications when you are near an active strike, picket line, or boycott location. The app uses GPS geofencing to alert you when entering or approaching a strike zone.
  >
  > NETWORK-LEVEL AWARENESS
  > The app uses a local Network Extension to analyze your network traffic and notify you when you are accessing services provided by employers involved in active labor disputes. You choose whether to proceed or support the action — the choice is always yours.
  >
  > GPS SNAPSHOT SUBMISSION
  > Help improve strike location data by submitting GPS snapshots of picket lines and protest locations you encounter. Select an active strike and submit your current location or manually enter an address.
  >
  > SUBMIT NEW STRIKES
  > Know about a labor action that is not in our database? Submit it directly from the app. Your submission will be reviewed by moderators before publication.
  >
  > PRIVACY-FIRST DESIGN
  > • All network traffic analysis happens on your device — no data is sent to remote servers
  > • GPS location is only transmitted when you explicitly choose to submit a snapshot
  > • No user accounts, analytics, or tracking
  > • The Network Extension is local-only and does not route traffic through any proxy
  >
  > Online Picket Line is an open-source project committed to supporting workers' rights.

- **Keywords** (100 chars, comma-separated):
  > labor,union,strike,solidarity,boycott,picket,workers rights,geofencing,fair wages

- **What's New** (for updates):
  > Initial release — Real-time strike proximity alerts, network traffic awareness, GPS snapshot submission, and strike reporting.

### Screenshots
- **iPhone 6.7"** (required): 1290 x 2796 or 2796 x 1290 (minimum 2)
- **iPhone 6.5"** (required): 1242 x 2688 or 2688 x 1242 (minimum 2)
- **iPad Pro 12.9" (6th gen)**: 2048 x 2732 (if supporting iPad)

### App Preview Videos (Optional)
- 15-30 second videos showing key features
- Same resolution requirements as screenshots

## Step 4: App Review Information

### Contact Information
- **First name**: (project lead)
- **Last name**: (project lead)
- **Phone**: (contact number)
- **Email**: (contact email)

### Demo Account
- Not required (app does not have user accounts)

### Notes for Review
> This app uses a Network Extension (Packet Tunnel Provider) to analyze DNS traffic locally on the device. No network traffic is forwarded to any external server. The VPN/Network Extension is used solely to check domain names against a locally cached list of employers involved in active labor disputes.
>
> The app also uses GPS location services to notify users when they are near physical strike locations. Location data is processed on-device; GPS coordinates are only transmitted to our server when the user explicitly taps "Submit GPS Snapshot."
>
> There are no user accounts, no personal data collection, and no analytics or tracking SDKs.

## Step 5: App Privacy (Nutrition Labels)

### Data Types Collected

#### Location
- **Precise Location**: Yes
  - Used for: App Functionality (strike proximity alerts)
  - Linked to user: No
  - Used for tracking: No
- **Coarse Location**: Yes
  - Used for: App Functionality (regional data fetching)
  - Linked to user: No
  - Used for tracking: No

#### Usage Data
- **Product Interaction**: No
- **Advertising Data**: No
- **Other Usage Data**: No

### Data Not Collected
- Contact Info
- Health & Fitness
- Financial Info
- Sensitive Info
- Contacts
- User Content (no accounts)
- Browsing History (DNS analysis is local-only)
- Search History
- Identifiers
- Purchases
- Diagnostics

## Step 6: Build and Submit

### Prepare for Submission
```bash
# Archive the app
xcodebuild archive \
  -project OnlinePicketLine.xcodeproj \
  -scheme OnlinePicketLine \
  -archivePath build/OnlinePicketLine.xcarchive \
  -destination 'generic/platform=iOS'

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/OnlinePicketLine.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export
```

### Upload via Xcode
1. Open the archive in Xcode Organizer (Window → Organizer)
2. Select the archive → **"Distribute App"**
3. Choose **"App Store Connect"**
4. Follow prompts to upload

### Upload via Command Line
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/export/OnlinePicketLine.ipa \
  --apiKey YOUR_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID
```

## Step 7: Submit for Review

1. In App Store Connect, go to your app
2. Select the build you uploaded
3. Fill in **"What's New in This Version"**
4. Add any review attachments or notes
5. Click **"Submit for Review"**

### Expected Review Timeline
- Standard review: 24-48 hours
- Network Extension apps may take longer (up to 1 week)
- Apple may request additional information about VPN/Network Extension usage

## Step 8: Post-Submission

### If Rejected
Common rejection reasons for this type of app:
1. **Guideline 2.5.1 (VPN)**: Ensure you clearly explain the VPN is local-only
2. **Guideline 5.4 (VPN Apps)**: Apps must not use VPN to collect user data
3. **Guideline 5.1.1 (Data Collection)**: Ensure privacy labels are accurate

For any rejection, respond via Resolution Center with clarification.

### After Approval
1. Set the release date (immediate or scheduled)
2. Monitor Crashlytics/crash reports
3. Respond to user reviews
4. Plan next version updates

## Review Checklist

Before submitting for review:

- [ ] Network Extension entitlement approved by Apple
- [ ] App Store listing complete (name, descriptions, screenshots)
- [ ] Privacy policy URL set and accessible
- [ ] App privacy nutrition labels completed
- [ ] Review notes explaining VPN/Network Extension usage
- [ ] App tested on multiple device sizes
- [ ] No crashes on current iOS versions
- [ ] Build uploaded to App Store Connect
- [ ] Version number and build number set correctly
- [ ] Export compliance (encryption) declaration completed

## Ongoing Maintenance

- **iOS version support**: Support at least the two most recent iOS versions
- **App Review Guidelines**: Review Apple's updates quarterly
- **Privacy updates**: Update nutrition labels when data practices change
- **TestFlight**: Use for beta testing before each release

# Developer Guide

## Project Structure

```
OnlinePicketLine/
├── OnlinePicketLine.xcodeproj/    # Xcode project file
│   └── project.pbxproj
└── OnlinePicketLine/              # Main application source
    ├── Info.plist                 # App configuration
    ├── OnlinePicketLineApp.swift  # App entry point
    ├── ContentView.swift          # Main view
    ├── DisputeAlertView.swift     # Alert dialog
    ├── SettingsView.swift         # Settings screen
    ├── Assets.xcassets/           # Images and colors
    ├── Models/
    │   └── DisputeModels.swift    # Data models
    └── Services/
        ├── APIClient.swift        # API communication
        ├── DisputeManager.swift   # Dispute data management
        └── NetworkMonitor.swift   # Network monitoring
```

## Key Components

### Models

#### LaborDispute
Represents a company involved in a labor dispute.

```swift
struct LaborDispute: Codable, Identifiable {
    let id: String
    let companyName: String
    let disputeDescription: String
    let affectedDomains: [String]
    let sourceURL: String?
    let startDate: Date?
    let tags: [String]?
}
```

### Services

#### APIClient
Handles all API communication with the Online Picket Line API.

**Key Methods:**
- `fetchDisputes()` - Fetches all active labor disputes
- `searchDisputesByDomain(_:)` - Searches for disputes affecting a specific domain

#### DisputeManager
Manages the dispute database, including fetching, caching, and querying.

**Key Methods:**
- `fetchDisputes()` - Updates the local dispute cache
- `findDispute(for:)` - Finds a dispute for a given URL
- `isDomainAffected(_:)` - Checks if a domain is affected
- `clearCache()` - Clears the local cache

#### NetworkMonitor
Monitors network activity and triggers alerts when disputed sites are accessed.

**Key Methods:**
- `startMonitoring()` - Begins monitoring
- `stopMonitoring()` - Stops monitoring
- `shouldBlockURL(_:)` - Checks if a URL should be blocked
- `allowCurrentURL()` - Allows the current blocked URL

### Views

#### ContentView
Main dashboard showing:
- Protection status
- Statistics (companies tracked, sites blocked)
- List of active labor disputes
- Settings and refresh buttons

#### DisputeAlertView
Alert dialog shown when a disputed site is detected:
- Company information
- Dispute details
- Affected domains
- Action buttons (Block/Allow)

#### SettingsView
Configuration screen with:
- Enable/disable protection
- Auto-block toggle
- Data refresh
- Statistics
- About information

## Development Workflow

### Setting Up Development Environment

1. **Install Xcode** (15.0 or later)
   ```bash
   # From Mac App Store or developer.apple.com
   ```

2. **Clone Repository**
   ```bash
   git clone https://github.com/oplfun/opl-for-apple.git
   cd opl-for-apple
   ```

3. **Open in Xcode**
   ```bash
   open OnlinePicketLine/OnlinePicketLine.xcodeproj
   ```

4. **Select Target**
   - Choose an iOS Simulator (iPhone 15, iOS 17+)
   - Or connect a physical device

5. **Build and Run**
   - Press ⌘R or click the Run button
   - The app will launch in the simulator/device

### Making Changes

#### Adding a New View

1. Create a new Swift file in the appropriate location
2. Add it to the Xcode project
3. Import SwiftUI
4. Create your view struct conforming to `View`
5. Add a preview for development

Example:
```swift
import SwiftUI

struct NewView: View {
    var body: some View {
        Text("New View")
    }
}

#Preview {
    NewView()
}
```

#### Adding a New Data Model

1. Create your model in `Models/DisputeModels.swift` or a new file
2. Make it `Codable` if it needs JSON serialization
3. Add appropriate initializers and coding keys

#### Modifying the API Client

1. Open `Services/APIClient.swift`
2. Add new methods for API endpoints
3. Update error handling as needed
4. Test with mock data first

### Testing

#### Manual Testing in Simulator

1. Launch the app
2. Verify UI appears correctly
3. Test navigation and user interactions
4. Check that mock data displays properly

#### Testing Domain Matching

```swift
// In DisputeManager or a test file
let testURL = URL(string: "https://example.com")!
if let dispute = DisputeManager.shared.findDispute(for: testURL) {
    print("Found dispute: \(dispute.companyName)")
}
```

#### Testing API Integration

1. Update `baseURL` in `APIClient.swift` to point to test API
2. Call `fetchDisputes()` from the UI
3. Verify data is fetched and displayed correctly

### Code Style Guidelines

#### Swift Style
- Use camelCase for variables and functions
- Use PascalCase for types and protocols
- Indent with 4 spaces
- Maximum line length: 120 characters
- Add documentation comments for public APIs

#### SwiftUI Best Practices
- Extract complex views into separate components
- Use `@State` for view-local state
- Use `@EnvironmentObject` for shared state
- Prefer declarative over imperative code
- Use view modifiers appropriately

#### Example:
```swift
// Good
struct ContentView: View {
    @EnvironmentObject var disputeManager: DisputeManager
    
    var body: some View {
        NavigationView {
            disputesList
                .navigationTitle("Disputes")
        }
    }
    
    private var disputesList: some View {
        List(disputeManager.disputes) { dispute in
            DisputeRow(dispute: dispute)
        }
    }
}

// Avoid deeply nested views in the body
```

### Common Tasks

#### Updating Mock Data

Edit the `getMockDisputes()` method in `APIClient.swift`:
```swift
private func getMockDisputes() -> [LaborDispute] {
    return [
        LaborDispute(
            id: "new-id",
            companyName: "New Company",
            disputeDescription: "New dispute details",
            affectedDomains: ["newcompany.com"],
            sourceURL: "https://source.com/article",
            tags: ["new-tag"]
        )
    ]
}
```

#### Adding a New Setting

1. Add a new `@State` or `@AppStorage` variable in `SettingsView`
2. Add a new `Toggle` or control in the Form
3. Update relevant services to use the new setting

#### Changing Color Scheme

Edit `Assets.xcassets/AccentColor.colorset/Contents.json` or add new color assets.

### Building for Distribution

#### Development Build

```bash
# Command line build
xcodebuild -project OnlinePicketLine.xcodeproj \
           -scheme OnlinePicketLine \
           -sdk iphonesimulator \
           -configuration Debug
```

#### Release Build

1. Update version in Xcode (General > Identity)
2. Archive the app (Product > Archive)
3. Export for distribution
4. Submit to App Store Connect (if applicable)

### Troubleshooting

#### Build Errors

**"Cannot find type 'LaborDispute'"**
- Make sure all files are added to the target
- Check file membership in File Inspector

**"Module not found"**
- Clean build folder (Shift+⌘K)
- Rebuild (⌘B)

**Preview crashes**
- Add mock data to preview
- Check for runtime errors in preview code

#### Runtime Issues

**Data not loading**
- Check network permissions in Info.plist
- Verify API endpoint URL
- Check for JSON decoding errors in console

**UI not updating**
- Ensure ObservableObject classes use `@Published`
- Verify views use `@EnvironmentObject` or `@StateObject`
- Check for main thread updates

### Performance Tips

1. **Lazy Loading**: Use `LazyVStack` for long lists
2. **Caching**: Cache images and data appropriately
3. **Background Tasks**: Use async/await for network calls
4. **Memory**: Use weak references to avoid retain cycles

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request with clear description

### Resources

- [Swift Documentation](https://docs.swift.org/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)

### Questions or Issues?

- Open an issue on GitHub
- Check existing documentation
- Review implementation guide (IMPLEMENTATION.md)

## License

See LICENSE file for details.

# Quick Start Guide

This guide will help you get the Online Picket Line iOS app up and running quickly.

## For Users

### What is This App?

Online Picket Line is an iOS application that helps you support workers' rights by alerting you when you attempt to access a company currently involved in a labor dispute. You can then choose to respect the digital picket line or proceed anyway.

### Features

- 🛡️ Real-time monitoring of sites you visit
- ⚠️ Alerts when accessing companies with labor disputes
- 📊 Statistics on blocked sites
- ⚙️ Customizable settings
- 🔄 Offline support with cached data

### Installation

**Note:** This app is currently in development and not yet available on the App Store.

To install from source:
1. You need a Mac with Xcode 15.0+
2. Clone this repository
3. Open the project in Xcode
4. Build and run on your device or simulator

### How It Works

1. **Launch**: Open the app - it automatically fetches the latest labor dispute data
2. **Browse**: Use your device normally
3. **Alert**: When you visit a disputed site, you'll see information about the labor dispute
4. **Choose**: 
   - Tap "Respect the Picket Line" to block access and support workers
   - Tap "Proceed Anyway" to continue to the site

### Settings

Access settings by tapping the gear icon in the top right:

- **Enable Protection**: Turn monitoring on/off
- **Auto-Block Disputes**: Automatically block all disputed sites
- **Refresh Disputes**: Manually update the dispute database
- **View Statistics**: See how many sites you've blocked

### Privacy

This app:
- ✅ Only checks site domains against the labor dispute database
- ✅ Stores dispute data locally on your device
- ✅ Does NOT collect or transmit your browsing history
- ✅ Does NOT share data with third parties

All processing happens on your device.

## For Developers

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 16.0+ device or simulator
- Basic knowledge of Swift and SwiftUI

### Quick Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/oplfun/opl-for-apple.git
   cd opl-for-apple
   ```

2. **Open in Xcode**
   ```bash
   open OnlinePicketLine/OnlinePicketLine.xcodeproj
   ```

3. **Select Target**
   - In Xcode, select a simulator or connected device from the target dropdown
   - Recommended: iPhone 15 simulator or later

4. **Build and Run**
   - Press ⌘R or click the Play button
   - The app will build and launch

### First Run

On first run, the app will:
- Display the main dashboard
- Load mock labor dispute data
- Show statistics (currently all zeros)
- Enable monitoring by default

### Testing Features

1. **View Disputes**: Check the main screen to see the list of labor disputes
2. **Settings**: Tap the gear icon to access settings
3. **Statistics**: View blocked site count and active disputes
4. **Refresh**: Tap the refresh icon to reload dispute data

### Mock Data

The app currently uses mock data in `APIClient.swift`. To test with real data:
1. Update `baseURL` in `Services/APIClient.swift`
2. Ensure the API returns data in the expected format (see `API_INTEGRATION.md`)

### Development Workflow

```bash
# Make your changes
# Build and test
⌘B          # Build
⌘R          # Run
⌘U          # Run tests (when available)

# Commit changes
git add .
git commit -m "Your change description"
git push
```

## Troubleshooting

### Build Errors

**Problem**: "Cannot find type 'LaborDispute'"
**Solution**: Clean build folder (Shift+⌘K) and rebuild

**Problem**: Preview crashes
**Solution**: Make sure all required data is provided in the preview

### Runtime Issues

**Problem**: App shows "Loading disputes..." indefinitely
**Solution**: Check console for errors. The mock data should load immediately.

**Problem**: UI not updating
**Solution**: Make sure you're using `@Published` properties in ObservableObject classes

### Common Questions

**Q: Why doesn't the app actually block traffic?**
A: iOS restricts network interception without VPN or Network Extension entitlements. See `IMPLEMENTATION.md` for production approaches.

**Q: How do I connect to the real API?**
A: See `API_INTEGRATION.md` for detailed instructions on integrating with the Online Picket Line API.

**Q: Can I use this on Android?**
A: This is an iOS-only implementation. A separate Android version would need to be developed.

**Q: Is this ready for the App Store?**
A: Not yet. Additional work is needed for network interception and App Store compliance. See `IMPLEMENTATION.md`.

## Next Steps

### For Users
- Wait for App Store release
- Follow the project for updates
- Provide feedback on the UI/UX

### For Developers
- Review the documentation:
  - `README.md` - Project overview
  - `DEVELOPER_GUIDE.md` - Development guide
  - `IMPLEMENTATION.md` - Production implementation
  - `API_INTEGRATION.md` - API integration
- Check open issues on GitHub
- Consider contributing improvements
- Help implement Network Extension support

## Support

### Getting Help

- **Issues**: Report bugs or request features on [GitHub Issues](https://github.com/oplfun/opl-for-apple/issues)
- **Documentation**: Check the README and guides
- **Discussions**: Join the conversation in GitHub Discussions

### Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

See `DEVELOPER_GUIDE.md` for coding standards and conventions.

## Resources

- [Online Picket Line Project](https://github.com/oplfun/online-picketline)
- [Swift Documentation](https://docs.swift.org/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [iOS Developer Documentation](https://developer.apple.com/documentation/)

## Solidarity

By using this app, you're standing in solidarity with workers fighting for:
- Fair wages
- Safe working conditions
- The right to organize
- Dignity and respect at work

Thank you for supporting workers' rights! ✊

---

**Version**: 1.0  
**Last Updated**: December 2024  
**License**: See LICENSE file

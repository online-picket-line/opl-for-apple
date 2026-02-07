import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoBlockEnabled") private var autoBlockEnabled = false
    @AppStorage("gpsTrackingEnabled") private var gpsTrackingEnabled = true
    @AppStorage("proximityRadiusMiles") private var proximityRadiusMiles = 100.0
    
    @State private var apiKey = ""
    @State private var showApiKeyField = false
    @State private var showClearConfirm = false
    @State private var showResetConfirm = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // Notifications
                Section("Notifications") {
                    Toggle("Strike Proximity Alerts", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Alert Radius")
                                Spacer()
                                Text("\(Int(proximityRadiusMiles)) miles")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $proximityRadiusMiles, in: 10...500, step: 10)
                        }
                    }
                }
                
                // Blocking
                Section("Content Blocking") {
                    Toggle("Auto-Block Employer Sites", isOn: $autoBlockEnabled)
                    Text("System-wide filtering ensures your device respects your user-defined ethical boundaries across all apps, not just your browser.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // GPS
                Section("Location Services") {
                    Toggle("GPS Strike Tracking", isOn: $gpsTrackingEnabled)
                    
                    if let location = locationManager.lastLocation {
                        HStack {
                            Text("Current Location")
                            Spacer()
                            Text(String(format: "%.4f, %.4f",
                                        location.coordinate.latitude,
                                        location.coordinate.longitude))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    switch locationManager.authorizationStatus {
                    case .denied, .restricted:
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Location access denied. Enable in system Settings.")
                                .font(.caption)
                        }
                    case .notDetermined:
                        Button("Grant Location Permission") {
                            locationManager.requestPermission()
                        }
                    default:
                        EmptyView()
                    }
                }
                
                // API Key
                Section("API Key") {
                    if SecureStorage.shared.apiKey != nil {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("API key configured")
                            Spacer()
                            Button("Change") {
                                showApiKeyField = true
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "xmark.shield.fill")
                                .foregroundColor(.red)
                            Text("No API key set")
                        }
                    }
                    
                    if showApiKeyField || SecureStorage.shared.apiKey == nil {
                        SecureField("Enter API Key (opl_...)", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        Button("Save API Key") {
                            guard !apiKey.isEmpty else { return }
                            SecureStorage.shared.apiKey = apiKey
                            APIClient.shared.setApiKey(apiKey)
                            apiKey = ""
                            showApiKeyField = false
                        }
                        .disabled(apiKey.isEmpty)
                    }
                    
                    if SecureStorage.shared.apiKey != nil {
                        Button("Remove API Key", role: .destructive) {
                            SecureStorage.shared.apiKey = nil
                            APIClient.shared.setApiKey(nil)
                        }
                    }
                }
                
                // Cache
                Section("Data") {
                    Button("Clear Cached Data") {
                        showClearConfirm = true
                    }
                    
                    Button("Force Refresh") {
                        Task { await appState.refreshData() }
                    }
                    
                    if let lastRefresh = appState.lastRefresh {
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(lastRefresh, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink("About Online Picket Line") {
                        AboutDetailView()
                    }
                    
                    Link("Project Website", destination: URL(string: "https://onlinepicketline.com")!)
                    Link("Source Code", destination: URL(string: "https://github.com/oplfun/opl-for-apple")!)
                    Link("Report an Issue", destination: URL(string: "https://github.com/oplfun/opl-for-apple/issues")!)
                    Link("Privacy Policy", destination: URL(string: "https://onlinepicketline.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://onlinepicketline.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .alert("Clear Cached Data?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    appState.clearCache()
                }
            } message: {
                Text("This will clear all locally cached strike data. Fresh data will be downloaded on the next refresh.")
            }
        }
    }
}

// MARK: - About Detail View

struct AboutDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Mission
                VStack(alignment: .leading, spacing: 8) {
                    Label("Our Mission", systemImage: "target")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Online Picket Line empowers workers and labor supporters in the digital age. When workers stand on a picket line, they're making a powerful statement. We help ensure that statement is heard everywhere — including the digital world.")
                        .foregroundColor(.secondary)
                    
                    Text("Your wallet is a picket line.")
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                    
                    Text("Every purchase is a vote, and we give you the tools to vote with your values. We believe in user-defined ethical boundaries — you decide where your digital picket line stands, and our tools help you hold it.")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Three Pillars
                VStack(alignment: .leading, spacing: 16) {
                    Label("Our Three Pillars", systemImage: "building.columns")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    PillarCard(
                        icon: "lock.shield",
                        title: "Privacy",
                        subtitle: "Data Sovereignty",
                        description: "We empower you to define your own 'secure borders' where your data cannot leave your device. All filtering decisions are made on-device — we never route your traffic through our servers."
                    )
                    
                    PillarCard(
                        icon: "shield.checkered",
                        title: "Safety",
                        subtitle: "Risk Mitigation",
                        description: "We reduce the risk of accidental digital scabbing by automating awareness and filtering based on verified labor action data from moderated sources."
                    )
                    
                    PillarCard(
                        icon: "eye",
                        title: "Control",
                        subtitle: "Transparency",
                        description: "We provide you with a clear view of which domains are associated with active disputes, so you can make informed choices — not blind ones."
                    )
                }
                
                Divider()
                
                // Network Sovereignty
                VStack(alignment: .leading, spacing: 8) {
                    Label("Network Sovereignty", systemImage: "network")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Modern economic activity doesn't just happen in web browsers. Delivery apps, gig-economy platforms, and background services all interact with employer infrastructure — often without your awareness.")
                        .foregroundColor(.secondary)
                    
                    Text("This app provides comprehensive, system-wide filtering that covers all network traffic on your device. Unlike browser-only solutions, we ensure that delivery apps, gig platforms, and background services also respect your ethical boundaries.")
                        .foregroundColor(.secondary)
                    
                    Text("All filtering is performed locally on your device. We do not log your browsing history, backhaul your traffic, or transmit your location data.")
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                // User-Defined Ethical Boundaries
                VStack(alignment: .leading, spacing: 8) {
                    Label("User-Defined Ethical Boundaries", systemImage: "slider.horizontal.3")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("You choose the level of engagement:")
                        .foregroundColor(.secondary)
                    
                    BoundaryRow(
                        icon: "info.circle",
                        title: "Informational Mode",
                        description: "Receive awareness alerts while retaining full access — you decide whether to proceed."
                    )
                    
                    BoundaryRow(
                        icon: "xmark.shield",
                        title: "Blocking Mode",
                        description: "System-wide filtering ensures your device does not interact with restricted employer infrastructure."
                    )
                    
                    BoundaryRow(
                        icon: "location.circle",
                        title: "Location-Aware Mode",
                        description: "Contextual filtering adapts based on your proximity to active picket lines."
                    )
                    
                    Text("These boundaries are entirely user-initiated and user-controlled. You define the rules. Our tools enforce them.")
                        .foregroundColor(.secondary)
                        .font(.callout)
                        .padding(.top, 4)
                }
                
                Divider()
                
                // Who We Are
                VStack(alignment: .leading, spacing: 8) {
                    Label("Who We Are", systemImage: "person.3")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Online Picket Line is a Utah Benefit LLC — a legal structure that emphasizes mission over money. Our tools are Movement-Owned Technology, designed to provide a pro-competitive, privacy-first alternative that restores the balance between employer interests and worker rights in the digital economy.")
                        .foregroundColor(.secondary)
                    
                    Text("We are funded by donations and grants from labor-friendly organizations, ensuring we remain independent and focused on serving workers.")
                        .foregroundColor(.secondary)
                }
                
                // IWW Quote
                VStack(spacing: 4) {
                    Text("\"An injury to one is an injury to all\"")
                        .font(.title3)
                        .fontWeight(.bold)
                        .italic()
                        .multilineTextAlignment(.center)
                    Text("— Industrial Workers of the World motto")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Supporting Views

struct PillarCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .fontWeight(.medium)
                Text(description)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BoundaryRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                    .font(.callout)
                Text(description)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

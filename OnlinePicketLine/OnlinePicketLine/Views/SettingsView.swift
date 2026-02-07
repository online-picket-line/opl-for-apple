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
                    Text("When enabled, sites of employers with active disputes will show a solidarity message.")
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
                    
                    Link("Project Website", destination: URL(string: "https://onlinepicketline.com")!)
                    Link("Source Code", destination: URL(string: "https://github.com/oplfun/opl-for-apple")!)
                    Link("Report an Issue", destination: URL(string: "https://github.com/oplfun/opl-for-apple/issues")!)
                    Link("Privacy Policy", destination: URL(string: "https://onlinepicketline.com/privacy")!)
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

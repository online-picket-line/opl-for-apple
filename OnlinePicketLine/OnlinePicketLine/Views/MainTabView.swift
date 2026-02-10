import SwiftUI

/// Main tab-based navigation for the app.
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "shield.checkered")
                }

            GpsSnapshotView()
                .tabItem {
                    Label("GPS Snapshot", systemImage: "location.circle")
                }

            SubmitStrikeView()
                .tabItem {
                    Label("Report", systemImage: "plus.circle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.red)
    }
}

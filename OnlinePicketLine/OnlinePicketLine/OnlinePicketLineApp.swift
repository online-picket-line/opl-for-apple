import SwiftUI

@main
struct OnlinePicketLineApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some Scene {
        WindowGroup {
            if appState.hasApiKey {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(locationManager)
                    .onAppear {
                        Task {
                            await appState.refreshData()
                            locationManager.startMonitoring()
                        }
                    }
            } else {
                ApiKeySetupView()
                    .environmentObject(appState)
            }
        }
    }
}

import SwiftUI

@main
struct OnlinePicketLineApp: App {
    @StateObject private var disputeManager = DisputeManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(disputeManager)
                .environmentObject(networkMonitor)
                .onAppear {
                    // Start monitoring and fetch initial data
                    Task {
                        await disputeManager.fetchDisputes()
                        networkMonitor.startMonitoring()
                    }
                }
        }
    }
}

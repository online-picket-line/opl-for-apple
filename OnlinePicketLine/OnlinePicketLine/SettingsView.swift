import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var disputeManager: DisputeManager
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = true
    @State private var autoBlockEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Monitoring")) {
                    Toggle("Enable Protection", isOn: Binding(
                        get: { networkMonitor.isMonitoring },
                        set: { enabled in
                            if enabled {
                                networkMonitor.startMonitoring()
                            } else {
                                networkMonitor.stopMonitoring()
                            }
                        }
                    ))
                    
                    Toggle("Auto-Block Disputes", isOn: $autoBlockEnabled)
                        .disabled(!networkMonitor.isMonitoring)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Alert on Detection", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("Data")) {
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        if let lastUpdate = disputeManager.lastUpdate {
                            Text(lastUpdate, style: .relative)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await disputeManager.fetchDisputes()
                        }
                    }) {
                        HStack {
                            Text("Refresh Disputes")
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    
                    Button(action: {
                        disputeManager.clearCache()
                    }) {
                        Text("Clear Cache")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Active Disputes")
                        Spacer()
                        Text("\(disputeManager.disputes.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sites Blocked")
                        Spacer()
                        Text("\(networkMonitor.blockedCount)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/oplfun/online-picketline")!) {
                        HStack {
                            Text("Online Picket Line Project")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                    
                    HStack {
                        Text("Purpose")
                        Spacer()
                    }
                    Text("This app helps you support workers' rights by alerting you when you're about to visit a company involved in a labor dispute.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NetworkMonitor.shared)
        .environmentObject(DisputeManager.shared)
}

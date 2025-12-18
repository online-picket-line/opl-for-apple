import SwiftUI

struct ContentView: View {
    @EnvironmentObject var disputeManager: DisputeManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showingSettings = false
    @State private var showingAlert = false
    @State private var currentDispute: LaborDispute?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                VStack(spacing: 10) {
                    Image(systemName: networkMonitor.isMonitoring ? "shield.checkered" : "shield.slash")
                        .font(.system(size: 60))
                        .foregroundColor(networkMonitor.isMonitoring ? .green : .gray)
                    
                    Text(networkMonitor.isMonitoring ? "Protection Active" : "Protection Inactive")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Monitoring outgoing traffic")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // Statistics
                VStack(alignment: .leading, spacing: 15) {
                    Text("Statistics")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        StatCard(
                            title: "Companies Tracked",
                            value: "\(disputeManager.disputes.count)",
                            icon: "building.2"
                        )
                        StatCard(
                            title: "Sites Blocked",
                            value: "\(networkMonitor.blockedCount)",
                            icon: "hand.raised.fill"
                        )
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Active Disputes List
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Labor Disputes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if disputeManager.disputes.isEmpty {
                        Text("Loading disputes...")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(disputeManager.disputes) { dispute in
                                    DisputeCard(dispute: dispute)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Online Picket Line")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await disputeManager.fetchDisputes()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAlert) {
                if let dispute = currentDispute {
                    DisputeAlertView(dispute: dispute, isPresented: $showingAlert)
                }
            }
            .onChange(of: networkMonitor.currentBlockedURL) { newURL in
                if let url = newURL {
                    currentDispute = disputeManager.findDispute(for: url)
                    if currentDispute != nil {
                        showingAlert = true
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DisputeCard: View {
    let dispute: LaborDispute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(dispute.companyName)
                    .font(.headline)
                Spacer()
            }
            
            Text(dispute.disputeDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !dispute.affectedDomains.isEmpty {
                HStack {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(dispute.affectedDomains.first ?? "")
                        .font(.caption)
                        .foregroundColor(.blue)
                    if dispute.affectedDomains.count > 1 {
                        Text("+\(dispute.affectedDomains.count - 1) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
        .environmentObject(DisputeManager.shared)
        .environmentObject(NetworkMonitor.shared)
}

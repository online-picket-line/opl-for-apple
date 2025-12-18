import SwiftUI

struct DisputeAlertView: View {
    let dispute: LaborDispute
    @Binding var isPresented: Bool
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.orange)
                    .padding(.top, 30)
                
                // Title
                Text("Labor Dispute Detected")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Company Info
                VStack(spacing: 15) {
                    HStack {
                        Text("Company:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(dispute.companyName)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dispute Details:")
                            .fontWeight(.semibold)
                        Text(dispute.disputeDescription)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if !dispute.affectedDomains.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Affected Domains:")
                                .fontWeight(.semibold)
                            ForEach(dispute.affectedDomains.prefix(5), id: \.self) { domain in
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.blue)
                                    Text(domain)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            if dispute.affectedDomains.count > 5 {
                                Text("... and \(dispute.affectedDomains.count - 5) more")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if let source = dispute.sourceURL {
                        Divider()
                        
                        HStack {
                            Text("Source:")
                                .fontWeight(.semibold)
                            Link("View Details", destination: URL(string: source)!)
                                .font(.footnote)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Text("This connection will be blocked to support workers' rights.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Block and close
                        isPresented = false
                    }) {
                        Text("Respect the Picket Line")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        // Allow this time
                        networkMonitor.allowCurrentURL()
                        isPresented = false
                    }) {
                        Text("Proceed Anyway")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
        }
    }
}

#Preview {
    DisputeAlertView(
        dispute: LaborDispute(
            id: "1",
            companyName: "Example Corp",
            disputeDescription: "Workers are striking for better wages and working conditions.",
            affectedDomains: ["example.com", "www.example.com"],
            sourceURL: "https://example.com/labor-dispute"
        ),
        isPresented: .constant(true)
    )
    .environmentObject(NetworkMonitor.shared)
}

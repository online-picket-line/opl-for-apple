import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingBlockAlert = false
    @State private var selectedEntry: BlocklistEntry?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Error Banner
                    if let error = appState.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(error)
                                .font(.caption)
                            Spacer()
                            Button("Dismiss") { appState.errorMessage = nil }
                                .font(.caption)
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)
                    }

                    // Status Card
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("Protection Active")
                            .font(.title2).bold()

                        Text("Monitoring traffic and GPS proximity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)

                    // Stats Row
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Sites",
                            value: "\(appState.mobileData?.blocklist.totalUrls ?? 0)",
                            icon: "globe",
                            color: .blue
                        )
                        StatCard(
                            title: "Employers",
                            value: "\(appState.mobileData?.blocklist.totalEmployers ?? 0)",
                            icon: "building.2",
                            color: .red
                        )
                        StatCard(
                            title: "Nearby",
                            value: "\(appState.mobileData?.geofences.total ?? 0)",
                            icon: "location",
                            color: .orange
                        )
                    }

                    // Nearby Strikes
                    if let geofences = appState.mobileData?.geofences.all, !geofences.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearby Strikes")
                                .font(.headline)

                            ForEach(geofences) { geofence in
                                GeofenceCard(geofence: geofence)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            Text("No active strikes nearby")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 30)
                    }
                }
                .padding()
            }
            .navigationTitle("Online Picket Line")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await appState.refreshData() }
                    }) {
                        if appState.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
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
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.title2).bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct GeofenceCard: View {
    let geofence: GeofenceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(geofence.employerName)
                    .font(.headline)
                Spacer()
                Text(geofence.actionType.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(8)
            }

            if let location = geofence.location {
                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(formatDistance(geofence.distance))
                .font(.subheadline).bold()
                .foregroundColor(.orange)

            if let desc = geofence.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private func formatDistance(_ meters: Int) -> String {
        if meters < 1000 {
            return "\(meters) m away"
        } else {
            let miles = Double(meters) / 1609.34
            return String(format: "%.1f mi away", miles)
        }
    }
}

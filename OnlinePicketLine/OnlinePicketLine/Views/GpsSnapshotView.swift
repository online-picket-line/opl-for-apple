import SwiftUI
import CoreLocation

struct GpsSnapshotView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager

    @State private var activeStrikes: [ActiveStrike] = []
    @State private var selectedStrikeIndex = 0
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var resolvedAddress = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                // Strike Selection
                Section("Select Strike") {
                    if activeStrikes.isEmpty && !isLoading {
                        Text("No active strikes found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Strike", selection: $selectedStrikeIndex) {
                            ForEach(activeStrikes.indices, id: \.self) { index in
                                Text(activeStrikes[index].displayName).tag(index)
                            }
                        }
                    }
                }

                // Location Capture
                Section("Location") {
                    Button(action: captureCurrentLocation) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use Current Location")
                        }
                    }

                    HStack {
                        TextField("Latitude", text: $latitude)
                            .keyboardType(.numbersAndPunctuation)
                        TextField("Longitude", text: $longitude)
                            .keyboardType(.numbersAndPunctuation)
                    }

                    HStack {
                        Button("Look Up") {
                            guard let lat = Double(latitude), let lng = Double(longitude) else { return }
                            Task { await reverseGeocode(lat: lat, lng: lng) }
                        }
                        .disabled(latitude.isEmpty || longitude.isEmpty)
                    }
                }

                // Address Lookup
                Section("Address Lookup") {
                    TextField("Street, City, State ZIP", text: $address)

                    Button("Geocode Address") {
                        guard !address.isEmpty else { return }
                        Task { await geocodeAddress() }
                    }
                    .disabled(address.isEmpty)

                    if !resolvedAddress.isEmpty {
                        Text(resolvedAddress)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                // Notes
                Section("Notes (optional)") {
                    TextField("Additional context about this location", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Error
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                // Submit
                Section {
                    Button(action: submitSnapshot) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Submit GPS Snapshot")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(latitude.isEmpty || longitude.isEmpty || activeStrikes.isEmpty || isLoading)
                }
            }
            .navigationTitle("GPS Snapshot")
            .alert("Snapshot Submitted!", isPresented: $showSuccess) {
                Button("OK") {}
            } message: {
                Text("Thank you for your solidarity! Your snapshot has been submitted for review.")
            }
            .onAppear { Task { await loadStrikes() } }
        }
    }

    // MARK: - Actions

    private func loadStrikes() async {
        isLoading = true
        do {
            activeStrikes = try await APIClient.shared.getActiveStrikes()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func captureCurrentLocation() {
        if let location = locationManager.lastLocation {
            latitude = String(location.coordinate.latitude)
            longitude = String(location.coordinate.longitude)
            Task {
                await reverseGeocode(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            }
        } else {
            locationManager.requestPermission()
            errorMessage = "Location not available. Please enable location services."
        }
    }

    private func geocodeAddress() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await APIClient.shared.geocode(address: address)
            latitude = String(result.latitude)
            longitude = String(result.longitude)
            resolvedAddress = result.displayName ?? address
        } catch {
            errorMessage = "Geocode failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func reverseGeocode(lat: Double, lng: Double) async {
        do {
            let result = try await APIClient.shared.reverseGeocode(latitude: lat, longitude: lng)
            resolvedAddress = result.displayName ?? [result.address, result.city, result.state]
                .compactMap { $0 }.joined(separator: ", ")
            if address.isEmpty {
                address = resolvedAddress
            }
        } catch {
            // Non-critical
        }
    }

    private func submitSnapshot() {
        guard let lat = Double(latitude), let lng = Double(longitude),
              selectedStrikeIndex < activeStrikes.count else { return }

        let strike = activeStrikes[selectedStrikeIndex]
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await APIClient.shared.submitGpsSnapshot(
                    GpsSnapshotRequest(
                        actionId: strike.id,
                        latitude: lat,
                        longitude: lng,
                        address: address.isEmpty ? nil : address,
                        notes: notes.isEmpty ? nil : notes
                    )
                )
                showSuccess = true
                // Reset form
                latitude = ""
                longitude = ""
                address = ""
                notes = ""
                resolvedAddress = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

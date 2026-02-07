import SwiftUI

struct SubmitStrikeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var employerName = ""
    @State private var unionName = ""
    @State private var actionType = "strike"
    @State private var description = ""
    @State private var startDate = Date()
    @State private var durationDays = "7"
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var sourceUrl = ""
    @State private var contactEmail = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    private let actionTypes = ["strike", "lockout", "picket", "boycott", "work_stoppage", "other"]
    
    var body: some View {
        NavigationView {
            Form {
                // Employer & Union
                Section("Organization Details") {
                    TextField("Employer Name *", text: $employerName)
                    TextField("Union Name *", text: $unionName)
                    Picker("Action Type", selection: $actionType) {
                        ForEach(actionTypes, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized).tag(type)
                        }
                    }
                }
                
                // Description
                Section("Description *") {
                    TextField("Describe the labor action...", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                // Timing
                Section("Timing") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    HStack {
                        Text("Duration (days)")
                        Spacer()
                        TextField("7", text: $durationDays)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Location
                Section("Location") {
                    TextField("Street Address", text: $address)
                    HStack {
                        TextField("City", text: $city)
                        TextField("State", text: $state)
                            .frame(width: 60)
                    }
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                    
                    Button(action: useCurrentLocation) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use Current Location")
                        }
                    }
                    
                    Button(action: geocodeEnteredAddress) {
                        HStack {
                            Image(systemName: "map")
                            Text("Geocode Address")
                        }
                    }
                    .disabled(address.isEmpty && city.isEmpty)
                    
                    if !latitude.isEmpty && !longitude.isEmpty {
                        HStack {
                            Text("Coordinates:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(latitude), \(longitude)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Source & Contact
                Section("Source (optional)") {
                    TextField("News/Source URL", text: $sourceUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField("Contact Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
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
                    Button(action: submitStrike) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Strike Report")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Report Strike")
            .alert("Strike Submitted!", isPresented: $showSuccess) {
                Button("Submit Another") { resetForm() }
                Button("Done", role: .cancel) {}
            } message: {
                Text("Your strike report has been submitted for moderator review. Thank you for standing in solidarity!")
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !employerName.isEmpty && !unionName.isEmpty && !description.isEmpty
    }
    
    // MARK: - Actions
    
    private func useCurrentLocation() {
        if let location = locationManager.lastLocation {
            latitude = String(location.coordinate.latitude)
            longitude = String(location.coordinate.longitude)
            Task {
                do {
                    let result = try await APIClient.shared.reverseGeocode(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    if let addr = result.address { address = addr }
                    if let c = result.city { city = c }
                    if let s = result.state { state = s }
                    if let z = result.zipCode { zipCode = z }
                } catch {
                    // Non-critical
                }
            }
        } else {
            locationManager.requestPermission()
            errorMessage = "Location not available. Please enable location services."
        }
    }
    
    private func geocodeEnteredAddress() {
        let fullAddress = [address, city, state, zipCode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        
        guard !fullAddress.isEmpty else { return }
        isLoading = true
        
        Task {
            do {
                let result = try await APIClient.shared.geocode(address: fullAddress)
                latitude = String(result.latitude)
                longitude = String(result.longitude)
            } catch {
                errorMessage = "Geocode failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func submitStrike() {
        isLoading = true
        errorMessage = nil
        
        let locationParts = [address, city, state, zipCode].filter { !$0.isEmpty }
        let locationString = locationParts.isEmpty ? "Unknown" : locationParts.joined(separator: ", ")
        
        var coords: GpsCoordinates? = nil
        if let lat = Double(latitude), let lng = Double(longitude) {
            coords = GpsCoordinates(latitude: lat, longitude: lng)
        }
        
        let request = StrikeSubmissionRequest(
            employer: EmployerSubmission(
                name: employerName,
                industry: nil,
                website: nil
            ),
            action: ActionSubmission(
                organization: unionName,
                actionType: actionType,
                location: locationString,
                startDate: ISO8601DateFormatter().string(from: startDate),
                durationDays: Int(durationDays) ?? 7,
                description: description,
                demands: nil,
                contactInfo: contactEmail.isEmpty ? nil : contactEmail,
                learnMoreUrl: sourceUrl.isEmpty ? nil : sourceUrl,
                coordinates: coords
            )
        )
        
        Task {
            do {
                _ = try await APIClient.shared.submitStrike(request)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func resetForm() {
        employerName = ""
        unionName = ""
        actionType = "strike"
        description = ""
        startDate = Date()
        durationDays = "7"
        address = ""
        city = ""
        state = ""
        zipCode = ""
        latitude = ""
        longitude = ""
        sourceUrl = ""
        contactEmail = ""
        errorMessage = nil
    }
}

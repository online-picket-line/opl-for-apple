import SwiftUI

struct ApiKeySetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 64))
                .foregroundColor(.red)

            // Title
            Text("Online Picket Line")
                .font(.largeTitle)
                .bold()

            Text("Enter your API key to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // API Key Input
            VStack(spacing: 12) {
                SecureField("API Key (opl_...)", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 32)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                }

                Button(action: validateAndSave) {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isValidating ? "Validating..." : "Connect")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(apiKey.isEmpty ? Color.gray : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(apiKey.isEmpty || isValidating)
                .padding(.horizontal, 32)
            }

            Spacer()

            // Help text
            VStack(spacing: 8) {
                Text("Don't have an API key?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Contact your union organizer or visit onlinepicketline.com")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 32)
        }
    }

    private func validateAndSave() {
        guard !apiKey.isEmpty else { return }

        // Basic format check
        guard apiKey.hasPrefix("opl_") && apiKey.count == 68 else {
            errorMessage = "Invalid API key format. Must start with 'opl_' and be 68 characters."
            return
        }

        isValidating = true
        errorMessage = nil

        // Save the key and attempt a data fetch to validate
        SecureStorage.shared.apiKey = apiKey
        APIClient.shared.setApiKey(apiKey)

        Task {
            do {
                // Try to fetch data to validate the key
                _ = try await APIClient.shared.getMobileData()
                await MainActor.run {
                    appState.hasApiKey = true
                    Task { await appState.refreshData() }
                }
            } catch {
                await MainActor.run {
                    SecureStorage.shared.apiKey = nil
                    APIClient.shared.setApiKey(nil)
                    errorMessage = "Invalid API key or server unreachable."
                    isValidating = false
                }
                return
            }
            await MainActor.run {
                isValidating = false
            }
        }
    }
}

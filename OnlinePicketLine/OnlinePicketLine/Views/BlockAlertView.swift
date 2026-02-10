import SwiftUI

struct BlockAlertView: View {
    let domain: String
    let employerName: String?
    let actionType: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Dark header
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)

                Text("SOLIDARITY ALERT")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color(white: 0.12))

            // Content
            VStack(spacing: 20) {
                if let employer = employerName {
                    VStack(spacing: 8) {
                        Text(employer)
                            .font(.title3)
                            .bold()

                        if let action = actionType {
                            Text("Active \(action.replacingOccurrences(of: "_", with: " "))")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .bold()
                        }
                    }
                }

                Divider()

                VStack(spacing: 12) {
                    Label {
                        Text("This employer has an active labor dispute.")
                    } icon: {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(.red)
                    }

                    Label {
                        Text("Workers are asking for solidarity by avoiding this site.")
                    } icon: {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.orange)
                    }

                    Label {
                        Text("Domain: \(domain)")
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                .padding(.horizontal)

                Divider()

                // Actions
                VStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("Stand in Solidarity")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: { dismiss() }) {
                        Text("Continue Anyway")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(white: 0.9))
                            .foregroundColor(.secondary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)

            Spacer()
        }
    }
}

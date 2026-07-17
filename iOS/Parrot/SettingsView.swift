import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProStore.self) private var pro

    private let websiteURL = URL(string: "https://shimondeitel.github.io/parrotlog-app/")!
    private let privacyURL = URL(string: "https://shimondeitel.github.io/parrotlog-app/privacy.html")!
    private let termsURL = URL(string: "https://shimondeitel.github.io/parrotlog-app/terms.html")!
    private let supportURL = URL(string: "https://shimondeitel.github.io/parrotlog-app/support.html")!

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if pro.isPro {
                        Label("Parrot Pro is active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Theme.leaf)
                    } else {
                        Button("Upgrade to Parrot Pro") {
                            dismiss()
                        }
                        .accessibilityIdentifier("upgradeButton")
                    }
                    Button("Restore purchases") {
                        Task { await pro.restore() }
                    }
                    .accessibilityIdentifier("restoreButton")
                } header: {
                    Text("Subscription")
                }

                Section {
                    Link(destination: websiteURL) {
                        Label("Website", systemImage: "globe")
                    }
                    Link(destination: privacyURL) {
                        Label("Privacy policy", systemImage: "hand.raised")
                    }
                    Link(destination: termsURL) {
                        Label("Terms of use", systemImage: "doc.text")
                    }
                    Link(destination: supportURL) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Parrot keeps every session on this device. Nothing is uploaded, tracked, or shared. Version 1.0")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settingsDoneButton")
                }
            }
        }
    }
}

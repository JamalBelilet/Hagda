import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacyPolicy = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                // App Information
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppEnvironment.fullVersion)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Environment")
                        Spacer()
                        Text(AppEnvironment.current.name)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Privacy Section
                Section("Privacy") {
                    Button {
                        showingPrivacyPolicy = true
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Manage Data", systemImage: "externaldrive")
                    }
                }
                
                // Legal Section
                Section("Legal") {
                    Link(destination: URL(string: "https://github.com/JamalBelilet/Hagda/blob/main/Hagda/Documentation/TermsOfService.md")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    NavigationLink {
                        Text("Third-party licenses will be displayed here")
                            .padding()
                    } label: {
                        Label("Third-Party Licenses", systemImage: "doc.on.doc")
                    }
                }
                
                // Support Section
                Section("Support") {
                    Link(destination: URL(string: "https://github.com/JamalBelilet/Hagda/issues")!) {
                        Label("Report an Issue", systemImage: "exclamationmark.bubble")
                    }
                    
                    Link(destination: URL(string: "mailto:support@hagda.app")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("This will delete all your preferences, selected sources, and cached content.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .alert("Clear All Data?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will delete all your preferences, selected sources, and cached content. This action cannot be undone.")
            }
        }
    }
    
    private func clearAllData() {
        // Clear UserDefaults
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
            UserDefaults.standard.synchronize()
        }
        
        // Clear any cached data
        URLCache.shared.removeAllCachedResponses()
        
        // In a real app, you might want to:
        // - Clear Core Data
        // - Clear Keychain items
        // - Reset app to initial state
        // - Show onboarding again
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("All data stored locally", systemImage: "iphone")
                        .font(.headline)
                    
                    Text("Hagda stores all your data on this device. We don't have servers and cannot access your information.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("What's Stored") {
                DataItemRow(
                    icon: "checkmark.circle",
                    title: "Selected Sources",
                    description: "Your chosen Reddit communities, Bluesky feeds, etc."
                )
                
                DataItemRow(
                    icon: "clock",
                    title: "Reading Progress",
                    description: "Which articles you've read and how far"
                )
                
                DataItemRow(
                    icon: "gear",
                    title: "Preferences",
                    description: "Daily brief time, display settings"
                )
                
                DataItemRow(
                    icon: "arrow.down.circle",
                    title: "Cached Content",
                    description: "Temporarily stored for offline reading"
                )
            }
            
            Section("Your Rights") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You have complete control over your data:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• **Access**: View all data in the app")
                    Text("• **Modify**: Change any setting anytime")
                    Text("• **Delete**: Remove the app to delete all data")
                    Text("• **Export**: No export needed - data never leaves your device")
                    
                    Text("\nWe cannot access, modify, or delete your data because it never leaves your device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataItemRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Settings") {
    SettingsView()
}

#Preview("Data Management") {
    NavigationStack {
        DataManagementView()
    }
}
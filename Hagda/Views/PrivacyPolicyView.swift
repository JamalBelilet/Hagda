import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Last Updated: May 23, 2025")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom)
                    
                    // Key Points Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Label("We don't collect any personal data", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        
                        Label("All settings stored locally on your device", systemImage: "iphone")
                            .foregroundStyle(.blue)
                        
                        Label("No tracking or analytics", systemImage: "eye.slash.fill")
                            .foregroundStyle(.purple)
                        
                        Label("Content fetched from public APIs only", systemImage: "network")
                            .foregroundStyle(.orange)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Sections
                    privacySection(
                        title: "What We Don't Collect",
                        content: """
                        Hagda is designed with privacy in mind. We do NOT collect, store, or transmit:
                        • Personal identification information
                        • Device identifiers or tracking data
                        • Location information
                        • Contact information
                        • Usage analytics or behavior data
                        • Crash reports (unless you explicitly opt-in)
                        """
                    )
                    
                    privacySection(
                        title: "Your Data Stays on Your Device",
                        content: """
                        All your preferences and settings are stored locally:
                        • Selected content sources
                        • Reading preferences and progress
                        • Daily brief settings
                        • Cached content for offline reading
                        
                        This data never leaves your device and is not accessible to us or any third party.
                        """
                    )
                    
                    privacySection(
                        title: "Third-Party Services",
                        content: """
                        Hagda fetches content from public APIs of the services you choose:
                        • Reddit, Bluesky, and Mastodon public posts
                        • RSS feeds for news and podcasts
                        
                        When fetching content:
                        • We only access publicly available content
                        • No authentication or personal credentials are used
                        • Your IP address may be visible to these services
                        • We identify ourselves as "Hagda/1.0" user agent
                        """
                    )
                    
                    privacySection(
                        title: "Security",
                        content: """
                        Your security is important to us:
                        • All network requests use secure HTTPS connections
                        • Minimum TLS 1.2 encryption is enforced
                        • No sensitive data is ever transmitted
                        • Local data is protected by iOS security features
                        • We follow Apple's best practices for iOS apps
                        """
                    )
                    
                    privacySection(
                        title: "Your Control",
                        content: """
                        You have complete control over your data:
                        • Access: View all your data directly in the app
                        • Deletion: Delete the app to remove all data
                        • Modification: Change preferences anytime
                        • No account or sign-up required
                        """
                    )
                    
                    // Contact Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Questions?")
                            .font(.headline)
                        
                        Text("If you have any questions about our privacy practices, please contact us:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Link(destination: URL(string: "mailto:privacy@hagda.app")!) {
                            Label("privacy@hagda.app", systemImage: "envelope")
                        }
                        
                        Link(destination: URL(string: "https://github.com/JamalBelilet/Hagda/issues")!) {
                            Label("GitHub Issues", systemImage: "link")
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
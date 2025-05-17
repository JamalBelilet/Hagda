import SwiftUI

/// First screen of the onboarding flow
struct WelcomeView: View {
    // MARK: - Properties
    
    @ObservedObject var coordinator: OnboardingCoordinator
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "newspaper")
                .font(.system(size: 80))
                .foregroundColor(.primary)
                .accessibilityIdentifier("welcomeIcon")
            
            Text("Welcome to Hagda")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("welcomeTitle")
            
            Text("Your personalized content aggregator for news, social media, and more.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("welcomeDescription")
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    coordinator.advance()
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Get Started")
                .accessibilityIdentifier("getStartedButton")
                
                Text("Get Started")
                    .font(.headline)
            }
            
            Button(action: {
                coordinator.skipToCompletion()
            }) {
                Text("Skip Setup")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.bottom, 40) // Add bottom padding to ensure button is above page indicator
            .accessibilityIdentifier("skipButton")
        }
        .padding()
        .accessibilityIdentifier("welcomeScreen")
    }
}
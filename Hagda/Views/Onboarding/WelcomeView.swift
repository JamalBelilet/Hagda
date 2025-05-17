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
                .foregroundColor(.accentColor)
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
            
            Button("Get Started") {
                coordinator.advance()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .accessibilityIdentifier("getStartedButton")
            
            Button("Skip Setup") {
                coordinator.skipToCompletion()
            }
            .font(.subheadline)
            .padding(.top)
            .padding(.bottom, 40) // Add bottom padding to ensure button is above page indicator
            .accessibilityIdentifier("skipButton")
        }
        .padding()
        .accessibilityIdentifier("welcomeScreen")
    }
}
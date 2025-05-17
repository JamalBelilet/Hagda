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
                .foregroundStyle(.accent)
                .accessibilityIdentifier("welcomeIcon")
            
            Text("Welcome to Hagda")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("welcomeTitle")
            
            Text("Your personalized content aggregator for news, social media, and more.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("welcomeDescription")
            
            Spacer()
            
            Button("Get Started") {
                coordinator.advance()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("getStartedButton")
            
            Button("Skip Setup") {
                coordinator.skipToCompletion()
            }
            .font(.subheadline)
            .padding(.top)
            .accessibilityIdentifier("skipButton")
        }
        .padding()
        .accessibilityIdentifier("welcomeScreen")
    }
}
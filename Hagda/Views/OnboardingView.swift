import SwiftUI

/// Main view for the onboarding flow
struct OnboardingView: View {
    // MARK: - Properties
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var coordinator: OnboardingCoordinator
    
    // MARK: - Initialization
    
    init() {
        // Create coordinator with reference to app model
        _coordinator = State(initialValue: OnboardingCoordinator(appModel: AppModel.shared))
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $coordinator.currentStep) {
            // Welcome screen
            WelcomeView(coordinator: coordinator)
                .tag(OnboardingCoordinator.OnboardingStep.welcome)
            
            // Source selection screen
            SourceSelectionView(coordinator: coordinator)
                .tag(OnboardingCoordinator.OnboardingStep.sourceSelection)
            
            // Daily brief setup screen
            DailyBriefSetupView(coordinator: coordinator)
                .tag(OnboardingCoordinator.OnboardingStep.dailyBriefSetup)
            
            // Completion screen
            CompletionView(coordinator: coordinator)
                .tag(OnboardingCoordinator.OnboardingStep.completion)
        }
        #if os(iOS) || os(visionOS)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        #else
        .tabViewStyle(.automatic)
        #endif
        .animation(.easeInOut, value: coordinator.currentStep)
        .onChange(of: coordinator.isOnboardingComplete) { _, isComplete in
            if isComplete {
                // When onboarding is complete, exit the view
                dismiss()
            }
        }
        .accessibilityIdentifier("onboardingView")
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AppModel())
}
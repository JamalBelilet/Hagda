import SwiftUI

/// Main view for the onboarding flow
struct OnboardingView: View {
    // MARK: - Properties
    
    @Environment(AppModel.self) private var appModel
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
            NavigationStack {
                SourceSelectionView(coordinator: coordinator)
                    .navigationTitle("Choose Your Content Sources")
                    #if os(iOS) || os(visionOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
            }
            .tag(OnboardingCoordinator.OnboardingStep.sourceSelection)
            
            // Daily brief setup screen
            NavigationStack {
                DailyBriefSetupView(coordinator: coordinator)
                    .navigationTitle("Customize Your Daily Brief")
                    #if os(iOS) || os(visionOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
            }
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
                // Directly update the appModel's isOnboardingComplete
                // This will trigger HagdaApp to switch to ContentView
                appModel.saveOnboardingComplete(true)
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
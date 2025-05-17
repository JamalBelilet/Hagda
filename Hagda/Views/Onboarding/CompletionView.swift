import SwiftUI

/// Final screen of the onboarding flow
struct CompletionView: View {
    // MARK: - Properties
    
    @ObservedObject var coordinator: OnboardingCoordinator
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .accessibilityIdentifier("completionIcon")
            
            Text("You're all set!")
                .font(.largeTitle.bold())
                .accessibilityIdentifier("completionTitle")
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text("\(coordinator.selectedSources.count) sources added to your feed")
                }
                
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text("\(coordinator.dailyBriefCategories.count) categories in your daily brief")
                }
                
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text("Daily brief scheduled for \(formattedTime(coordinator.dailyBriefTime))")
                }
            }
            .font(.headline)
            .accessibilityIdentifier("completionSummary")
            
            Spacer()
            
            Button("Start Exploring") {
                coordinator.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("startExploringButton")
        }
        .padding()
        .accessibilityIdentifier("completionScreen")
    }
    
    // MARK: - Helper Methods
    
    /// Format time for display
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
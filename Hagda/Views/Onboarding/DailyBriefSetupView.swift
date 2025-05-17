import SwiftUI

/// Third screen of the onboarding flow for customizing the daily brief
struct DailyBriefSetupView: View {
    // MARK: - Properties
    
    @ObservedObject var coordinator: OnboardingCoordinator
    
    // Available categories for daily brief
    let availableCategories = [
        "Technology", "Business", "World News", 
        "Politics", "Science", "Health", 
        "Entertainment", "Sports"
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            // Title is now in the navigation bar
            
            Text("Your daily brief will be generated with content from these categories")
                .padding(.top, 20)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityIdentifier("dailyBriefDescription")
            
            List {
                // Categories section
                Section(header: Text("Categories")) {
                    ForEach(availableCategories, id: \.self) { category in
                        Button(action: { coordinator.toggleCategory(category) }) {
                            HStack {
                                Text(category)
                                Spacer()
                                if coordinator.dailyBriefCategories.contains(category) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(category) \(coordinator.dailyBriefCategories.contains(category) ? "selected" : "not selected")")
                        .accessibilityHint("Tap to \(coordinator.dailyBriefCategories.contains(category) ? "remove from" : "add to") daily brief categories")
                    }
                }
                
                // Delivery time section
                Section(header: Text("Delivery Time")) {
                    DatePicker("Time", selection: $coordinator.dailyBriefTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .accessibilityIdentifier("briefTimeSelector")
                }
            }
            #if os(iOS) || os(visionOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .accessibilityIdentifier("briefSettingsList")
            
            Spacer()
            
            // Navigation buttons
            HStack {
                Button(action: {
                    coordinator.goTo(step: .sourceSelection)
                }) {
                    Image(systemName: "chevron.backward.circle.fill")
                        .font(.system(size: 32))
                }
                .buttonStyle(.plain)
                .foregroundColor(.gray.opacity(0.8))
                .accessibilityLabel("Back")
                .accessibilityIdentifier("backButton")
                
                Spacer()
                
                Button(action: {
                    coordinator.advance()
                }) {
                    Image(systemName: "chevron.forward.circle.fill")
                        .font(.system(size: 32))
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
                .opacity(coordinator.dailyBriefCategories.isEmpty ? 0.5 : 1.0)
                .disabled(coordinator.dailyBriefCategories.isEmpty)
                .accessibilityLabel("Continue")
                .accessibilityIdentifier("continueButton")
            }
            .padding()
            .padding(.bottom, 40) // Add bottom padding to ensure buttons are above page indicator
        }
        .accessibilityIdentifier("dailyBriefSetupScreen")
    }
}
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
        ZStack {
            List {
            // Description text in its own section
            Section {
                Text("Your daily brief will be generated with content from these categories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("dailyBriefDescription")
            }
            
            // Categories section
            Section(header: Text("Categories")) {
                ForEach(availableCategories, id: \.self) { category in
                    Button(action: { coordinator.toggleCategory(category) }) {
                        HStack {
                            Text(category)
                            Spacer()
                            if coordinator.dailyBriefCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primary)
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
            
            // Empty spacer at the bottom of the list for padding
            Section {
                Color.clear.frame(height: 80)
            }
            .listRowBackground(Color.clear)
        }
        #if os(iOS) || os(visionOS)
        .listStyle(.inset)
        .scrollContentBackground(.visible)
//        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.visible)
        #else
        .listStyle(.inset)
        .scrollContentBackground(.visible)
        .background(Color.gray.opacity(0.1))
        #endif
        .accessibilityIdentifier("dailyBriefSetupScreen")
            
            // Sticky navigation buttons at the bottom
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        coordinator.goTo(step: .sourceSelection)
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.gray.opacity(0.8))
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("backButton")
                    
                    Spacer()
                    
                    Button(action: {
                        coordinator.advance()
                    }) {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                    .opacity(coordinator.dailyBriefCategories.isEmpty ? 0.5 : 1.0)
                    .disabled(coordinator.dailyBriefCategories.isEmpty)
                    .accessibilityLabel("Continue")
                    .accessibilityIdentifier("continueButton")
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.thinMaterial)
                .cornerRadius(16)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
            }
        }
    }
}

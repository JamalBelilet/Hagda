import SwiftUI

@Observable
class OnboardingCoordinator {
    var currentStep: OnboardingStep = .welcome
    var selectedSources: [Source] = []
    var dailyBriefCategories: Set<String> = ["Technology", "World News"]
    var dailyBriefTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var searchText: String = ""
    var isOnboardingComplete: Bool = false
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case sourceSelection
        case dailyBriefSetup
        case completion
        
        var title: String {
            switch self {
            case .welcome: return "Welcome to Hagda"
            case .sourceSelection: return "Select Your Sources"
            case .dailyBriefSetup: return "Customize Your Daily Brief"
            case .completion: return "You're All Set!"
            }
        }
    }
    
    func advance() {
        if let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep)?.advanced(by: 1),
           nextIndex < OnboardingStep.allCases.count {
            currentStep = OnboardingStep.allCases[nextIndex]
        } else {
            completeOnboarding()
        }
    }
    
    func completeOnboarding() {
        // Save selected sources to AppModel
        // Configure daily brief settings
        // Mark onboarding as complete
        isOnboardingComplete = true
    }
    
    func skipToCompletion() {
        // If skipping, add some default sources
        if selectedSources.isEmpty {
            // Add some sensible defaults
            selectedSources = Source.recommendedDefaults
        }
        
        currentStep = .completion
    }
}

struct OnboardingView: View {
    @State private var coordinator = OnboardingCoordinator()
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        TabView(selection: $coordinator.currentStep) {
            WelcomeView(coordinator: coordinator)
                .tag(OnboardingCoordinator.OnboardingStep.welcome)
            
            SourceSelectionView(coordinator: coordinator)
                .tag(OnboardingCoordinator.OnboardingStep.sourceSelection)
            
            DailyBriefSetupView(coordinator: coordinator)
                .tag(OnboardingCoordinator.OnboardingStep.dailyBriefSetup)
            
            CompletionView(coordinator: coordinator)
                .tag(OnboardingCoordinator.OnboardingStep.completion)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .animation(.easeInOut, value: coordinator.currentStep)
        .onChange(of: coordinator.isOnboardingComplete) { _, isComplete in
            if isComplete {
                // Apply settings to app model
                appModel.sources.append(contentsOf: coordinator.selectedSources)
                appModel.dailyBriefCategories = coordinator.dailyBriefCategories
                appModel.dailyBriefTime = coordinator.dailyBriefTime
                appModel.isOnboardingComplete = true
                
                // Dismiss the onboarding view
                dismiss()
            }
        }
    }
}

// MARK: - Onboarding Step Views

struct WelcomeView: View {
    var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "newspaper")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
            
            Text("Welcome to Hagda")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            Text("Your personalized content aggregator for news, social media, and more.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Get Started") {
                coordinator.advance()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Skip Setup") {
                coordinator.skipToCompletion()
            }
            .font(.subheadline)
            .padding(.top)
        }
        .padding()
        .accessibilityIdentifier("welcomeScreen")
    }
}

struct SourceSelectionView: View {
    var coordinator: OnboardingCoordinator
    
    // Sample source categories for the prototype
    let sourceCategories = [
        "News": [
            Source(name: "New York Times", type: .news, url: URL(string: "https://nytimes.com")!),
            Source(name: "BBC", type: .news, url: URL(string: "https://bbc.com")!),
            Source(name: "The Verge", type: .news, url: URL(string: "https://theverge.com")!)
        ],
        "Social": [
            Source(name: "Reddit r/technology", type: .reddit, url: URL(string: "https://reddit.com/r/technology")!),
            Source(name: "Reddit r/worldnews", type: .reddit, url: URL(string: "https://reddit.com/r/worldnews")!)
        ],
        "Bluesky": [
            Source(name: "Tech News", type: .bluesky, url: URL(string: "https://bsky.app/profile/technews")!)
        ]
    ]
    
    var body: some View {
        VStack {
            Text("Choose Your Content Sources")
                .font(.title2.bold())
                .padding(.top)
            
            Text("Select at least 3 sources to personalize your feed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            SearchBar(text: $coordinator.searchText)
                .padding()
            
            List {
                ForEach(sourceCategories.keys.sorted(), id: \.self) { category in
                    Section(header: Text(category)) {
                        ForEach(sourceCategories[category] ?? [], id: \.id) { source in
                            SourceRowView(source: source, isSelected: coordinator.selectedSources.contains(where: { $0.id == source.id }))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSource(source)
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            HStack {
                Button("Back") {
                    coordinator.currentStep = .welcome
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Continue") {
                    coordinator.advance()
                }
                .buttonStyle(.borderedProminent)
                .disabled(coordinator.selectedSources.count < 1) // Typically would be 3, but reduced for demo
            }
            .padding()
        }
        .accessibilityIdentifier("sourceSelectionScreen")
    }
    
    private func toggleSource(_ source: Source) {
        if let index = coordinator.selectedSources.firstIndex(where: { $0.id == source.id }) {
            coordinator.selectedSources.remove(at: index)
        } else {
            coordinator.selectedSources.append(source)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search sources...", text: $text)
                .textFieldStyle(.roundedBorder)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct DailyBriefSetupView: View {
    var coordinator: OnboardingCoordinator
    
    let availableCategories = [
        "Technology", "Business", "World News", 
        "Politics", "Science", "Health", 
        "Entertainment", "Sports"
    ]
    
    var body: some View {
        VStack {
            Text("Customize Your Daily Brief")
                .font(.title2.bold())
                .padding(.top)
            
            Text("Your daily brief will be generated with content from these categories")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            List {
                Section(header: Text("Categories")) {
                    ForEach(availableCategories, id: \.self) { category in
                        Button(action: { toggleCategory(category) }) {
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
                    }
                }
                
                Section(header: Text("Delivery Time")) {
                    DatePicker("Time", selection: $coordinator.dailyBriefTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                }
            }
            .listStyle(.insetGrouped)
            
            HStack {
                Button("Back") {
                    coordinator.currentStep = .sourceSelection
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Continue") {
                    coordinator.advance()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .accessibilityIdentifier("dailyBriefSetupScreen")
    }
    
    private func toggleCategory(_ category: String) {
        if coordinator.dailyBriefCategories.contains(category) {
            coordinator.dailyBriefCategories.remove(category)
        } else {
            coordinator.dailyBriefCategories.insert(category)
        }
    }
}

struct CompletionView: View {
    var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("You're all set!")
                .font(.largeTitle.bold())
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                    Text("\(coordinator.selectedSources.count) sources added to your feed")
                }
                
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                    Text("\(coordinator.dailyBriefCategories.count) categories in your daily brief")
                }
                
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                    Text("Daily brief scheduled for \(formattedTime(coordinator.dailyBriefTime))")
                }
            }
            .font(.headline)
            
            Spacer()
            
            Button("Start Exploring") {
                coordinator.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .accessibilityIdentifier("completionScreen")
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Placeholder for Source struct - would use actual app model in implementation
extension Source {
    static var recommendedDefaults: [Source] {
        [
            Source(name: "New York Times", type: .news, url: URL(string: "https://nytimes.com")!),
            Source(name: "BBC", type: .news, url: URL(string: "https://bbc.com")!),
            Source(name: "Reddit r/all", type: .reddit, url: URL(string: "https://reddit.com/r/all")!)
        ]
    }
}
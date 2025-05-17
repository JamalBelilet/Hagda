import SwiftUI

/// Coordinator class to manage the onboarding flow and state
@Observable
class OnboardingCoordinator: ObservableObject {
    // MARK: - Properties
    
    /// Current step in the onboarding process
    var currentStep: OnboardingStep = .welcome
    
    /// Sources selected during onboarding
    var selectedSources: [Source] = []
    
    /// Categories selected for daily brief
    var dailyBriefCategories: Set<String> = ["Technology", "World News"]
    
    /// Time for daily brief delivery
    var dailyBriefTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
    /// Search text for source search
    var searchText: String = ""
    
    /// Flag indicating if onboarding is complete
    var isOnboardingComplete: Bool = false
    
    /// Search results from the API
    var searchResults: [Source] = []
    
    /// Flag indicating if a search is in progress
    var isSearching: Bool = false
    
    /// Error message for search failures
    var errorMessage: String? = nil
    
    /// Currently selected source type for search
    var selectedSourceType: SourceType = .article
    
    // MARK: - Reference to App Model
    
    /// Reference to the shared app model
    private let appModel: AppModel
    
    // MARK: - Initialization
    
    /// Initialize with app model
    init(appModel: AppModel) {
        self.appModel = appModel
    }
    
    // MARK: - Onboarding Steps
    
    /// Enum defining the steps in the onboarding flow
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
    
    // MARK: - Navigation Methods
    
    /// Move to the next step in the onboarding flow
    func advance() {
        if let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep)?.advanced(by: 1),
           nextIndex < OnboardingStep.allCases.count {
            currentStep = OnboardingStep.allCases[nextIndex]
        } else {
            completeOnboarding()
        }
    }
    
    /// Move to a specific step in the onboarding flow
    func goTo(step: OnboardingStep) {
        currentStep = step
    }
    
    /// Skip the onboarding flow and complete with default settings
    func skipToCompletion() {
        // If skipping without selecting any sources, add some default sources
        if selectedSources.isEmpty {
            // Add one of each type to demonstrate all section types
            let typesToInclude: [SourceType] = [.article, .reddit, .bluesky, .podcast]
            
            for type in typesToInclude {
                if let source = appModel.sources.first(where: { $0.type == type }) {
                    selectedSources.append(source)
                }
            }
            
            // Add one more reddit source to show multiple items in a section
            if let secondReddit = appModel.sources.filter({ $0.type == .reddit }).dropFirst().first {
                selectedSources.append(secondReddit)
            }
        }
        
        // Go to completion step and then complete the onboarding
        // This will save all the selections to UserDefaults
        currentStep = .completion
        completeOnboarding()
    }
    
    // MARK: - Source Management
    
    /// Toggle selection of a source in the onboarding flow
    func toggleSource(_ source: Source) {
        if let index = selectedSources.firstIndex(where: { $0.id == source.id }) {
            selectedSources.remove(at: index)
        } else {
            selectedSources.append(source)
        }
    }
    
    /// Check if a source is selected in the onboarding flow
    func isSourceSelected(_ source: Source) -> Bool {
        return selectedSources.contains(where: { $0.id == source.id })
    }
    
    /// Toggle selection of a category for the daily brief
    func toggleCategory(_ category: String) {
        if dailyBriefCategories.contains(category) {
            dailyBriefCategories.remove(category)
        } else {
            dailyBriefCategories.insert(category)
        }
    }
    
    // MARK: - Search Methods
    
    /// Search for sources based on the current query and selected type
    func searchSources() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                var results: [Source] = []
                
                switch selectedSourceType {
                case .podcast:
                    results = try await appModel.searchPodcasts(query: searchText)
                case .reddit:
                    results = try await appModel.searchSubreddits(query: searchText)
                case .mastodon:
                    results = try await appModel.searchMastodonAccounts(query: searchText)
                case .bluesky:
                    results = try await appModel.searchBlueSkyAccounts(query: searchText)
                case .article:
                    results = try await appModel.searchNewsSources(query: searchText)
                }
                
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    self.errorMessage = "Failed to search \(selectedSourceType.displayName.lowercased()): \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
    
    // MARK: - Completion
    
    /// Complete the onboarding process and save settings to the app model
    func completeOnboarding() {
        // Create a set of selected source IDs
        let selectedSourceIds = Set(selectedSources.map { $0.id })
        
        // Add any new sources from search to the app model's source catalog
        for source in selectedSources {
            if !appModel.sources.contains(where: { $0.id == source.id }) {
                appModel.sources.append(source)
            }
        }
        
        // Save selected sources to UserDefaults
        appModel.saveSelectedSources(selectedSourceIds)
        
        // Save daily brief settings
        appModel.saveDailyBriefCategories(dailyBriefCategories)
        appModel.saveDailyBriefTime(dailyBriefTime)
        
        // Mark onboarding as complete
        isOnboardingComplete = true
        appModel.saveOnboardingComplete(true)
    }
}
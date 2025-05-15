import Foundation
import SwiftUI

/// Settings for the daily summary view
struct DailySummarySettings {
    var showWeather: Bool = true
    var includeTodayEvents: Bool = true
    var summarizeSource: Bool = true
    var summaryLength: SummaryLength = .medium
    var sortingOrder: SummarySort = .newest
    
    enum SummaryLength: String, CaseIterable, Identifiable {
        case short = "Short"
        case medium = "Medium"
        case long = "Long"
        
        var id: String { rawValue }
    }
    
    enum SummarySort: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case trending = "Trending"
        case priority = "Priority Sources"
        
        var id: String { rawValue }
    }
}

/// The main application model that manages sources and user selections
@Observable
class AppModel {
    // MARK: - Properties
    
    /// All available sources
    var sources: [Source] = Source.sampleSources
    
    /// IDs of sources selected by the user to appear in their feed
    var selectedSources: Set<UUID> = []
    
    /// IDs of sources prioritized by the user in daily summary
    var prioritizedSources: Set<UUID> = []
    
    /// Daily summary settings
    var dailySummarySettings = DailySummarySettings()
    
    /// Flag for UI testing mode
    var isTestingMode: Bool = false
    
    // MARK: - Computed Properties
    
    /// Sources that appear in the feed (only those selected by the user)
    var feedSources: [Source] {
        return sources
            .filter { selectedSources.contains($0.id) }
            .sorted { $0.name < $1.name }
    }
    
    /// Categorized sources for display in the library view
    var categories: [String: [Source]] {
        var result: [String: [Source]] = [:]
        
        // Articles category
        let articleSources = sources.filter { $0.type == .article }
        if !articleSources.isEmpty {
            result["Top Tech Articles"] = articleSources
        }
        
        // Reddit category
        let redditSources = sources.filter { $0.type == .reddit }
        if !redditSources.isEmpty {
            result["Popular Subreddits"] = redditSources
        }
        
        // Podcasts category
        let podcastSources = sources.filter { $0.type == .podcast }
        if !podcastSources.isEmpty {
            result["Tech Podcasts"] = podcastSources
        }
        
        // Social media category (bluesky and mastodon)
        let socialSources = sources.filter { $0.type == .bluesky || $0.type == .mastodon }
        if !socialSources.isEmpty {
            result["Tech Influencers"] = socialSources
        }
        
        return result
    }
    
    // MARK: - Shared Instance
    
    /// Shared instance for the app model
    static let shared = AppModel()
    
    // MARK: - Initialization
    
    init(isTestingMode: Bool = false) {
        self.isTestingMode = isTestingMode
        
        // Select some default sources to populate the feed
        if !isTestingMode && selectedSources.isEmpty {
            // Select one of each type to demonstrate all section types
            let typesToInclude: [SourceType] = [.article, .reddit, .bluesky, .podcast]
            
            for type in typesToInclude {
                if let source = sources.first(where: { $0.type == type }) {
                    selectedSources.insert(source.id)
                }
            }
            
            // Add one more reddit source to show multiple items in a section
            if let secondReddit = sources.filter({ $0.type == .reddit }).dropFirst().first {
                selectedSources.insert(secondReddit.id)
            }
        }
    }
    
    // MARK: - Setting Updates
    
    /// Update the daily summary settings
    func updateDailySummarySettings(
        showWeather: Bool? = nil,
        includeTodayEvents: Bool? = nil,
        summarizeSource: Bool? = nil,
        summaryLength: DailySummarySettings.SummaryLength? = nil,
        sortingOrder: DailySummarySettings.SummarySort? = nil
    ) {
        if let showWeather = showWeather {
            dailySummarySettings.showWeather = showWeather
        }
        if let includeTodayEvents = includeTodayEvents {
            dailySummarySettings.includeTodayEvents = includeTodayEvents
        }
        if let summarizeSource = summarizeSource {
            dailySummarySettings.summarizeSource = summarizeSource
        }
        if let summaryLength = summaryLength {
            dailySummarySettings.summaryLength = summaryLength
        }
        if let sortingOrder = sortingOrder {
            dailySummarySettings.sortingOrder = sortingOrder
        }
    }
    
    // MARK: - Source Management
    
    /// Toggle a source's selection state
    func toggleSourceSelection(_ source: Source) {
        if selectedSources.contains(source.id) {
            selectedSources.remove(source.id)
        } else {
            selectedSources.insert(source.id)
        }
    }
    
    /// Check if a source is currently selected
    func isSourceSelected(_ source: Source) -> Bool {
        selectedSources.contains(source.id)
    }
    
    /// Add a new custom source
    func addSource(_ source: Source) {
        sources.append(source)
        // Automatically select the newly added source
        selectedSources.insert(source.id)
    }
    
    // MARK: - Search
    
    /// iTunes Search API service for podcast searches
    private let itunesSearchService = ITunesSearchService()
    
    /// Search for sources by query and type (with real iTunes API for podcasts)
    func searchSources(query: String, type: SourceType) -> [Source] {
        // For podcasts, we return an empty array since search will be handled asynchronously
        if type == .podcast {
            return []
        }
        
        // For other types, use mock implementation
        switch type {
        case .article:
            return [
                Source(name: "Tech News Daily", type: .article, description: "Your daily dose of tech news and analysis.", handle: nil),
                Source(name: "Ars Technica", type: .article, description: "Technology news, reviews, and analysis.", handle: nil)
            ]
        case .reddit:
            return [
                Source(name: "r/AskScience", type: .reddit, description: "Ask questions about science and get answers from experts.", handle: "r/AskScience"),
                Source(name: "r/TechSupport", type: .reddit, description: "Community for technical support questions.", handle: "r/TechSupport")
            ]
        case .bluesky:
            return [
                Source(name: "Tech Insider", type: .bluesky, description: "Breaking tech news and insider perspectives.", handle: "techinsider.bsky.social"),
                Source(name: "Dev Journal", type: .bluesky, description: "A developer's journey in tech.", handle: "devjournal.bsky.social")
            ]
        case .mastodon:
            return [
                Source(name: "Open Source News", type: .mastodon, description: "Updates from the open source community.", handle: "@opensource@mastodon.social"),
                Source(name: "Tech Policy", type: .mastodon, description: "Analysis of tech policy and regulations.", handle: "@techpolicy@mastodon.social")
            ]
        case .podcast:
            // This should never be reached as we handle this case above
            return []
        }
    }
    
    /// Search for podcasts using the iTunes Search API
    /// - Parameters:
    ///   - query: The search term
    ///   - completion: Closure that will be called with the results or error
    func searchPodcasts(query: String, completion: @escaping (Result<[Source], Error>) -> Void) {
        itunesSearchService.searchPodcasts(query: query, limit: 20, completion: completion)
    }
    
    /// Search for podcasts using the iTunes Search API with async/await
    /// - Parameter query: The search term
    /// - Returns: Array of Source objects representing podcasts
    func searchPodcasts(query: String) async throws -> [Source] {
        return try await itunesSearchService.searchPodcasts(query: query, limit: 20)
    }
    
    /// Toggle a source's prioritized state in the daily summary
    func toggleSourcePrioritization(_ source: Source) {
        if prioritizedSources.contains(source.id) {
            prioritizedSources.remove(source.id)
        } else {
            prioritizedSources.insert(source.id)
        }
    }
    
    /// Check if a source is currently prioritized
    func isSourcePrioritized(_ source: Source) -> Bool {
        prioritizedSources.contains(source.id)
    }
    
// MARK: - Content Management
    
    /// Fetch content for a specific source (mocked implementation)
    func getContentForSource(_ source: Source) -> [ContentItem] {
        return ContentItem.samplesForSource(source)
    }
}
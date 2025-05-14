import Foundation
import SwiftUI

/// The main application model that manages sources and user selections
@Observable
class AppModel {
    // MARK: - Properties
    
    /// All available sources
    var sources: [Source] = Source.sampleSources
    
    /// IDs of sources selected by the user to appear in their feed
    var selectedSources: Set<UUID> = []
    
    /// Flag for UI testing mode
    var isTestingMode: Bool = false
    
    // MARK: - Computed Properties
    
    /// Sources that appear in the feed
    var feedSources: [Source] {
        // For mock/demo purposes, we're showing all sources regardless of selection
        // In a real app, this would filter by selectedSources
        return sources.sorted { $0.name < $1.name }
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
    
    // MARK: - Initialization
    
    init(isTestingMode: Bool = false) {
        self.isTestingMode = isTestingMode
        
        // For testing purposes, select a few sources by default
        if !isTestingMode && selectedSources.isEmpty {
            if let firstSource = sources.first, let lastSource = sources.last {
                selectedSources.insert(firstSource.id)
                selectedSources.insert(lastSource.id)
            }
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
    
    /// Search for sources by query and type (mocked implementation)
    func searchSources(query: String, type: SourceType) -> [Source] {
        // This is a mock implementation that returns predefined sources based on type
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
            return [
                Source(name: "Code Stories", type: .podcast, description: "Stories from developers about their coding journeys.", handle: "by Code Media"),
                Source(name: "Tech This Week", type: .podcast, description: "Weekly roundup of tech news and discussions.", handle: "by Tech Media Network")
            ]
        }
    }
    
    // MARK: - Content Management
    
    /// Fetch content for a specific source (mocked implementation)
    func getContentForSource(_ source: Source) -> [ContentItem] {
        return ContentItem.samplesForSource(source)
    }
}
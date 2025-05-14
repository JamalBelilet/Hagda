import Foundation
import SwiftUI

@Observable
class AppModel {
    var sources: [Source] = Source.sampleSources
    var selectedSources: Set<UUID> = []
    
    // Sources that appear in the feed - now showing all sources as mock data
    var feedSources: [Source] {
        // Instead of filtering by selectedSources, we'll show all sources
        // This is just a mock, in a real app we'd still filter by selectedSources
        return sources.sorted { $0.name < $1.name }
    }
    
    // Toggle source selection for feed
    func toggleSourceSelection(_ source: Source) {
        if selectedSources.contains(source.id) {
            selectedSources.remove(source.id)
        } else {
            selectedSources.insert(source.id)
        }
    }
    
    // Check if a source is selected
    func isSourceSelected(_ source: Source) -> Bool {
        selectedSources.contains(source.id)
    }
    
    // Add a new custom source
    func addSource(_ source: Source) {
        sources.append(source)
        // Automatically select the newly added source
        selectedSources.insert(source.id)
    }
    
    // Search for sources by URL or text (mocked for now)
    func searchSources(query: String, type: SourceType) -> [Source] {
        // For a mock implementation, we'll return different predefined sources based on type
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
    
    // Categories for organizing sources in the library
    var categories: [String: [Source]] {
        let articleSources = sources.filter { $0.type == .article }
        let redditSources = sources.filter { $0.type == .reddit }
        let podcastSources = sources.filter { $0.type == .podcast }
        
        var result: [String: [Source]] = [:]
        
        if !articleSources.isEmpty {
            result["Top Tech Articles"] = articleSources
        }
        
        if !redditSources.isEmpty {
            result["Popular Subreddits"] = redditSources
        }
        
        if !podcastSources.isEmpty {
            result["Tech Podcasts"] = podcastSources
        }
        
        // Social media sources (combining bluesky and mastodon)
        let socialSources = sources.filter { $0.type == .bluesky || $0.type == .mastodon }
        if !socialSources.isEmpty {
            result["Tech Influencers"] = socialSources
        }
        
        return result
    }
}
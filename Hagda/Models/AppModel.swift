import Foundation
import SwiftUI

/// Settings for the daily summary view
struct DailySummarySettings {
    var showWeather: Bool = true
    var includeTodayEvents: Bool = true
    var summarizeSource: Bool = true
    var summaryLength: SummaryLength = .short
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
    
    /// Flag to track if onboarding has been completed
    var isOnboardingComplete: Bool = false
    
    /// Daily brief categories selected during onboarding
    var dailyBriefCategories: Set<String> = ["Technology", "World News"]
    
    /// Daily brief time selected during onboarding
    var dailyBriefTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
    /// UserDefaults access for persistence
    private let defaults = UserDefaults.standard
    
    /// Daily brief generator
    private var _dailyBriefGenerator: DailyBriefGenerator?
    var dailyBriefGenerator: DailyBriefGenerator {
        if _dailyBriefGenerator == nil {
            _dailyBriefGenerator = DailyBriefGenerator(appModel: self)
        }
        return _dailyBriefGenerator!
    }
    
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
        
        // Load saved values from UserDefaults
        if !isTestingMode {
            loadFromUserDefaults()
        }
        
        // We don't add mock data anymore since we'll either:
        // 1. Show the onboarding flow which will let users select sources
        // 2. Have previously saved source selections from onboarding
        
        // For testing purposes only
        if isTestingMode && selectedSources.isEmpty {
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
        } else if isTestingMode {
            // Ensure selectedSources is empty for tests
            selectedSources.removeAll()
        }
    }
    
    /// Load saved values from UserDefaults
    private func loadFromUserDefaults() {
        isOnboardingComplete = defaults.bool(forKey: "isOnboardingComplete")
        
        if let categoriesArray = defaults.stringArray(forKey: "dailyBriefCategories") {
            dailyBriefCategories = Set(categoriesArray)
        }
        
        if let timeInterval = defaults.object(forKey: "dailyBriefTime") as? TimeInterval {
            dailyBriefTime = Date(timeIntervalSince1970: timeInterval)
        }
        
        // Load selected sources
        if let selectedSourceIdStrings = defaults.array(forKey: "selectedSources") as? [String] {
            let sourceIds = selectedSourceIdStrings.compactMap { UUID(uuidString: $0) }
            selectedSources = Set(sourceIds)
        }
    }
    
    /// Save onboarding completion status to UserDefaults
    func saveOnboardingComplete(_ completed: Bool) {
        isOnboardingComplete = completed
        defaults.set(completed, forKey: "isOnboardingComplete")
    }
    
    /// Save daily brief categories to UserDefaults
    func saveDailyBriefCategories(_ categories: Set<String>) {
        dailyBriefCategories = categories
        defaults.set(Array(categories), forKey: "dailyBriefCategories")
    }
    
    /// Save daily brief time to UserDefaults
    func saveDailyBriefTime(_ time: Date) {
        dailyBriefTime = time
        defaults.set(time.timeIntervalSince1970, forKey: "dailyBriefTime")
    }
    
    /// Save selected sources to UserDefaults
    func saveSelectedSources(_ sourceIds: Set<UUID>) {
        selectedSources = sourceIds
        // Convert UUIDs to strings for storage
        let sourceIdStrings = sourceIds.map { $0.uuidString }
        defaults.set(sourceIdStrings, forKey: "selectedSources")
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
        // Check if the source already exists by name and type
        if let existingSource = findSource(name: source.name, type: source.type) {
            // If it exists, select it instead of adding a duplicate
            selectedSources.insert(existingSource.id)
        } else {
            // If it's a new source, add it and select it
            sources.append(source)
            selectedSources.insert(source.id)
        }
    }
    
    /// Find a source by name and type
    func findSource(name: String, type: SourceType) -> Source? {
        return sources.first { $0.name == name && $0.type == type }
    }
    
    /// Get content for a specific source
    func getContent(for source: Source) -> [ContentItem] {
        // For MVP, return sample content
        // In the future, this will fetch real content from the source
        return ContentItem.samplesForSource(source)
    }
    
    // MARK: - API Services
    
    /// Get the Bluesky API service
    public func getBlueSkyAPIService() -> BlueSkyAPIService {
        return blueSkyAPIService
    }
    
    /// Get the Mastodon API service
    public func getMastodonAPIService() -> MastodonAPIService {
        return mastodonAPIService
    }
    
    /// Get the Reddit API service
    public func getRedditAPIService() -> RedditAPIService {
        return redditAPIService
    }
    
    /// Get the News API service
    public func getNewsAPIService() -> NewsAPIService {
        return newsAPIService
    }
    
    /// Get the iTunes Search API service
    public func getITunesSearchService() -> ITunesSearchService {
        return itunesSearchService
    }
    
    // MARK: - Search
    
    /// iTunes Search API service for podcast searches
    private let itunesSearchService = ITunesSearchService()
    
    /// Reddit API service for subreddit searches
    private let redditAPIService = RedditAPIService()
    
    /// Mastodon API service for account searches and fetching statuses
    private let mastodonAPIService = MastodonAPIService()
    
    /// Bluesky API service for account searches and fetching posts
    private let blueSkyAPIService = BlueSkyAPIService()
    
    /// News API service for RSS feed searches and article fetching
    private let newsAPIService = NewsAPIService()
    
    /// Search for sources by query and type (with real APIs for podcasts, Reddit, Mastodon, Bluesky, and news)
    func searchSources(query: String, type: SourceType) -> [Source] {
        // For podcasts, Reddit, Mastodon, Bluesky, and news we return an empty array since search will be handled asynchronously
        if type == .podcast || type == .reddit || type == .mastodon || type == .bluesky || type == .article {
            return []
        }
        
        // For other types, use mock implementation
        switch type {
        case .article:
            // News sources are now handled asynchronously via NewsAPIService
            return []
        case .bluesky:
            // Bluesky sources are now handled asynchronously via BlueSkyAPIService
            return []
        case .mastodon:
            // Mastodon sources are now handled asynchronously via MastodonAPIService
            return []
        case .reddit, .podcast:
            // This should never be reached as we handle these cases above
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
    
    /// Search for subreddits using the Reddit API
    /// - Parameters:
    ///   - query: The search term
    ///   - completion: Closure that will be called with the results or error
    func searchSubreddits(query: String, completion: @escaping (Result<[Source], Error>) -> Void) {
        redditAPIService.searchSubreddits(query: query, limit: 20, completion: completion)
    }
    
    /// Search for subreddits using the Reddit API with async/await
    /// - Parameter query: The search term
    /// - Returns: Array of Source objects representing subreddits
    func searchSubreddits(query: String) async throws -> [Source] {
        return try await redditAPIService.searchSubreddits(query: query, limit: 20)
    }
    
    /// Search for Mastodon accounts using the Mastodon API
    /// - Parameters:
    ///   - query: The search term
    ///   - completion: Closure that will be called with the results or error
    func searchMastodonAccounts(query: String, completion: @escaping (Result<[Source], Error>) -> Void) {
        mastodonAPIService.searchAccounts(query: query, limit: 20, completion: completion)
    }
    
    /// Search for Mastodon accounts using the Mastodon API with async/await
    /// - Parameter query: The search term
    /// - Returns: Array of Source objects representing Mastodon accounts
    func searchMastodonAccounts(query: String) async throws -> [Source] {
        return try await mastodonAPIService.searchAccounts(query: query, limit: 20)
    }
    
    /// Search for Bluesky accounts using the Bluesky API
    /// - Parameters:
    ///   - query: The search term
    ///   - completion: Closure that will be called with the results or error
    func searchBlueSkyAccounts(query: String, completion: @escaping (Result<[Source], Error>) -> Void) {
        blueSkyAPIService.searchAccounts(query: query, limit: 20, completion: completion)
    }
    
    /// Search for Bluesky accounts using the Bluesky API with async/await
    /// - Parameter query: The search term
    /// - Returns: Array of Source objects representing Bluesky accounts
    func searchBlueSkyAccounts(query: String) async throws -> [Source] {
        return try await blueSkyAPIService.searchAccounts(query: query, limit: 20)
    }
    
    /// Fetch content for a subreddit
    /// - Parameters:
    ///   - subreddit: The subreddit source
    /// - Returns: Array of ContentItem objects representing posts
    func fetchSubredditContent(subreddit: Source) async throws -> [ContentItem] {
        // Extract the subreddit name from the handle
        guard let handle = subreddit.handle, handle.starts(with: "r/") else {
            // If no handle or wrong format, return empty array
            return []
        }
        
        do {
            // Try to fetch content from the API
            return try await redditAPIService.fetchSubredditContent(subredditName: handle)
        } catch {
            print("Error fetching Reddit content: \(error.localizedDescription)")
            
            // Always rethrow the error - no fallback to sample data
            throw error
        }
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
    
    /// Fetch content for a specific source
    func getContentForSource(_ source: Source) -> [ContentItem] {
        // For now, we'll use sample data for all sources
        // In a real app, we would make API calls here based on source type
        return ContentItem.samplesForSource(source)
    }
    
    /// Fetch content for a specific source with async/await support
    /// - Parameter source: The source to fetch content for
    /// - Returns: Array of ContentItem objects
    func getContentForSource(_ source: Source) async throws -> [ContentItem] {
        // Based on source type, fetch from appropriate API
        switch source.type {
        case .reddit:
            // For Reddit sources, use the Reddit API
            return try await fetchSubredditContent(subreddit: source)
        case .podcast:
            // For podcast sources, fetch episodes
            return try await fetchPodcastEpisodes(podcast: source)
        case .mastodon:
            // For Mastodon sources, fetch statuses
            return try await fetchMastodonContent(mastodonSource: source)
        case .bluesky:
            // For Bluesky sources, fetch posts
            return try await fetchBlueSkyContent(blueSkySource: source)
        case .article:
            // For news sources, fetch articles
            return try await fetchNewsContent(newsSource: source)
        default:
            // For other types, use sample data for now
            return ContentItem.samplesForSource(source)
        }
    }
    
    /// Fetch podcast episodes
    /// - Parameter podcast: The podcast source
    /// - Returns: Array of ContentItem objects representing episodes
    func fetchPodcastEpisodes(podcast: Source) async throws -> [ContentItem] {
        // Check if the source has a feed URL
        guard let feedUrl = podcast.feedUrl, !feedUrl.isEmpty else {
            // If no feed URL is available, use sample data for development
            print("No feed URL found for podcast, using sample data")
            return ContentItem.samplesForSource(podcast)
        }
        
        do {
            // Try to fetch episodes from the feed
            return try await itunesSearchService.fetchPodcastEpisodes(from: feedUrl, source: podcast)
        } catch {
            print("Error fetching podcast episodes: \(error.localizedDescription)")
            
            // If we're in DEBUG mode, return some sample content for testing
            #if DEBUG
            print("Returning sample content for podcast in DEBUG mode")
            return ContentItem.samplesForSource(podcast)
            #else
            // In production, rethrow the error
            throw error
            #endif
        }
    }
    
    /// Fetch Mastodon statuses
    /// - Parameter mastodonSource: The Mastodon source
    /// - Returns: Array of ContentItem objects representing statuses
    func fetchMastodonContent(mastodonSource: Source) async throws -> [ContentItem] {
        do {
            // Try to fetch content from the API
            return try await mastodonAPIService.fetchContentForSource(mastodonSource)
        } catch {
            print("Error fetching Mastodon content: \(error.localizedDescription)")
            
            // If we're in DEBUG mode, return some sample content for testing
            #if DEBUG
            print("Returning sample content for Mastodon in DEBUG mode")
            return ContentItem.samplesForSource(mastodonSource)
            #else
            // In production, rethrow the error
            throw error
            #endif
        }
    }
    
    /// Fetch Bluesky posts
    /// - Parameter blueSkySource: The Bluesky source
    /// - Returns: Array of ContentItem objects representing posts
    func fetchBlueSkyContent(blueSkySource: Source) async throws -> [ContentItem] {
        do {
            // Try to fetch content from the API
            return try await blueSkyAPIService.fetchContentForSource(blueSkySource)
        } catch {
            print("Error fetching Bluesky content: \(error.localizedDescription)")
            
            // Always rethrow the error - no fallback to sample data
            throw error
        }
    }
    
    /// Search for news sources using the News API
    /// - Parameters:
    ///   - query: The search term or website URL
    ///   - completion: Closure that will be called with the results or error
    func searchNewsSources(query: String, completion: @escaping (Result<[Source], Error>) -> Void) {
        newsAPIService.searchSources(query: query, limit: 20, completion: completion)
    }
    
    /// Search for news sources using the News API with async/await
    /// - Parameter query: The search term or website URL
    /// - Returns: Array of Source objects representing news sources
    func searchNewsSources(query: String) async throws -> [Source] {
        return try await newsAPIService.searchSources(query: query, limit: 20)
    }
    
    /// Fetch news articles
    /// - Parameter newsSource: The news source
    /// - Returns: Array of ContentItem objects representing articles
    func fetchNewsContent(newsSource: Source) async throws -> [ContentItem] {
        do {
            // Try to fetch content from the API
            return try await newsAPIService.fetchArticles(for: newsSource)
        } catch {
            print("Error fetching news content: \(error.localizedDescription)")
            
            // If we're in DEBUG mode, return some sample content for testing
            #if DEBUG
            print("Returning sample content for news in DEBUG mode")
            return ContentItem.samplesForSource(newsSource)
            #else
            // In production, rethrow the error
            throw error
            #endif
        }
    }
}

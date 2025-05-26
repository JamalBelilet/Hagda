import Foundation
import SwiftUI

struct TrendingScore {
    let engagement: Double    // 0-1 normalized
    let recency: Double      // 0-1 based on age
    let sourceWeight: Double // User preference weight
    
    var totalScore: Double {
        return (engagement * 0.6) + (recency * 0.3) + (sourceWeight * 0.1)
    }
}

struct TrendingContentItem: Identifiable {
    let id = UUID()
    let contentItem: ContentItem
    let score: TrendingScore
}

@Observable
class TrendingManager {
    private let newsAPI: NewsAPIService
    private let redditAPI: RedditAPIService
    private let blueSkyAPI: BlueSkyAPIService
    private let mastodonAPI: MastodonAPIService
    private let iTunesAPI: ITunesSearchService
    
    private var cachedTrendingItems: [TrendingContentItem] = []
    private var lastFetchTime: Date?
    private let cacheExpirationMinutes: TimeInterval = 15
    
    var isLoading = false
    var error: Error?
    
    init(newsAPI: NewsAPIService, redditAPI: RedditAPIService, blueSkyAPI: BlueSkyAPIService, 
         mastodonAPI: MastodonAPIService, iTunesAPI: ITunesSearchService) {
        self.newsAPI = newsAPI
        self.redditAPI = redditAPI
        self.blueSkyAPI = blueSkyAPI
        self.mastodonAPI = mastodonAPI
        self.iTunesAPI = iTunesAPI
    }
    
    func fetchTrendingContent(sources: [Source], forceRefresh: Bool = false) async -> [ContentItem] {
        // Check cache
        if !forceRefresh, let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpirationMinutes * 60,
           !cachedTrendingItems.isEmpty {
            return cachedTrendingItems.map { $0.contentItem }
        }
        
        isLoading = true
        error = nil
        
        var allTrendingItems: [TrendingContentItem] = []
        
        // Fetch from each source type
        await withTaskGroup(of: [TrendingContentItem].self) { group in
            for source in sources {
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    return await self.fetchTrendingForSource(source)
                }
            }
            
            for await items in group {
                allTrendingItems.append(contentsOf: items)
            }
        }
        
        // Sort by score
        allTrendingItems.sort { $0.score.totalScore > $1.score.totalScore }
        
        // Take top items (limit to prevent overwhelming the UI)
        cachedTrendingItems = Array(allTrendingItems.prefix(20))
        lastFetchTime = Date()
        isLoading = false
        
        return cachedTrendingItems.map { $0.contentItem }
    }
    
    private func fetchTrendingForSource(_ source: Source) async -> [TrendingContentItem] {
        switch source.type {
        case .reddit:
            return await fetchRedditTrending(source: source)
        case .article:
            return await fetchNewsTrending(source: source)
        case .bluesky:
            return await fetchBlueSkyTrending(source: source)
        case .mastodon:
            return await fetchMastodonTrending(source: source)
        case .podcast:
            return await fetchPodcastTrending(source: source)
        }
    }
    
    private func fetchRedditTrending(source: Source) async -> [TrendingContentItem] {
        // Extract subreddit name from handle or name
        let subreddit = source.handle ?? source.name
        
        do {
            let posts = try await redditAPI.fetchHotPosts(subreddit: subreddit, limit: 10)
            return posts.map { post in
                let engagementScore = normalizeEngagement(
                    value: Double(post.score ?? 0),
                    maxValue: 10000 // Assuming 10k is high engagement for Reddit
                )
                let recencyScore = calculateRecencyScore(date: post.date)
                let score = TrendingScore(
                    engagement: engagementScore,
                    recency: recencyScore,
                    sourceWeight: 1.0
                )
                return TrendingContentItem(contentItem: post, score: score)
            }
        } catch {
            self.error = error
            return []
        }
    }
    
    private func fetchNewsTrending(source: Source) async -> [TrendingContentItem] {
        do {
            let articles = try await newsAPI.fetchRecentArticles(source: source, limit: 10)
            return articles.map { article in
                // For news, recency is more important than engagement
                let recencyScore = calculateRecencyScore(date: article.date)
                let score = TrendingScore(
                    engagement: 0.5, // Default medium engagement for news
                    recency: recencyScore,
                    sourceWeight: 1.0
                )
                return TrendingContentItem(contentItem: article, score: score)
            }
        } catch {
            self.error = error
            return []
        }
    }
    
    private func fetchBlueSkyTrending(source: Source) async -> [TrendingContentItem] {
        do {
            let posts = try await blueSkyAPI.fetchPopularPosts(limit: 10)
            return posts.map { post in
                let engagementScore = normalizeEngagement(
                    value: Double((post.likeCount ?? 0) + (post.repostCount ?? 0) * 2),
                    maxValue: 1000 // Assuming 1k is high engagement for BlueSky
                )
                let recencyScore = calculateRecencyScore(date: post.date)
                let score = TrendingScore(
                    engagement: engagementScore,
                    recency: recencyScore,
                    sourceWeight: 1.0
                )
                return TrendingContentItem(contentItem: post, score: score)
            }
        } catch {
            self.error = error
            return []
        }
    }
    
    private func fetchMastodonTrending(source: Source) async -> [TrendingContentItem] {
        // Extract server from handle (e.g., "@user@mastodon.social" -> "mastodon.social")
        let server: String
        if let handle = source.handle, handle.contains("@") {
            let components = handle.split(separator: "@")
            server = components.count > 2 ? String(components.last!) : "mastodon.social"
        } else {
            server = "mastodon.social" // Default server
        }
        
        do {
            let posts = try await mastodonAPI.fetchTrendingPosts(server: server, limit: 10)
            return posts.map { post in
                let likes = post.likeCount ?? 0
                let reposts = post.repostCount ?? 0
                let engagementScore = normalizeEngagement(
                    value: Double(likes + reposts * 2),
                    maxValue: 500 // Assuming 500 is high engagement for Mastodon
                )
                let recencyScore = calculateRecencyScore(date: post.date)
                let score = TrendingScore(
                    engagement: engagementScore,
                    recency: recencyScore,
                    sourceWeight: 1.0
                )
                return TrendingContentItem(contentItem: post, score: score)
            }
        } catch {
            self.error = error
            return []
        }
    }
    
    private func fetchPodcastTrending(source: Source) async -> [TrendingContentItem] {
        // For podcasts, we'll use iTunes top charts
        do {
            let topPodcasts = try await iTunesAPI.fetchTopPodcasts(limit: 10)
            return topPodcasts.enumerated().map { index, podcast in
                // Higher chart position = higher engagement score
                let engagementScore = 1.0 - (Double(index) / 10.0)
                let score = TrendingScore(
                    engagement: engagementScore,
                    recency: 0.7, // Top charts are relatively recent
                    sourceWeight: 1.0
                )
                return TrendingContentItem(contentItem: podcast, score: score)
            }
        } catch {
            self.error = error
            return []
        }
    }
    
    private func normalizeEngagement(value: Double, maxValue: Double) -> Double {
        return min(value / maxValue, 1.0)
    }
    
    private func calculateRecencyScore(date: Date) -> Double {
        let hoursAgo = Date().timeIntervalSince(date) / 3600
        
        // Score based on hours ago
        if hoursAgo <= 1 { return 1.0 }
        else if hoursAgo <= 6 { return 0.9 }
        else if hoursAgo <= 12 { return 0.8 }
        else if hoursAgo <= 24 { return 0.7 }
        else if hoursAgo <= 48 { return 0.5 }
        else if hoursAgo <= 72 { return 0.3 }
        else if hoursAgo <= 168 { return 0.1 } // 1 week
        else { return 0.0 }
    }
}
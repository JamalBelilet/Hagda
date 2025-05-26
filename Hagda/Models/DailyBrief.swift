import Foundation
import SwiftUI

// MARK: - Daily Brief Models

/// Represents a daily brief with curated content
struct DailyBrief: Identifiable {
    let id: UUID
    let date: Date
    let items: [BriefItem]
    let readTime: TimeInterval
    let mode: BriefMode
    let generatedAt: Date
    
    init(id: UUID = UUID(), date: Date = Date(), items: [BriefItem], readTime: TimeInterval, mode: BriefMode) {
        self.id = id
        self.date = date
        self.items = items
        self.readTime = readTime
        self.mode = mode
        self.generatedAt = Date()
    }
    
    /// Estimated read time in minutes
    var readTimeMinutes: Int {
        Int(ceil(readTime / 60))
    }
    
    /// Check if brief is for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

/// Individual item in the brief
struct BriefItem: Identifiable {
    let id: UUID
    let content: ContentItem
    let reason: String // Why this was included
    let context: String? // Personal relevance
    let summary: String // 2-3 sentence summary
    let category: BriefCategory
    let priority: Int // Display order
    
    init(
        id: UUID = UUID(),
        content: ContentItem,
        reason: String,
        context: String? = nil,
        summary: String,
        category: BriefCategory,
        priority: Int = 0
    ) {
        self.id = id
        self.content = content
        self.reason = reason
        self.context = context
        self.summary = summary
        self.category = category
        self.priority = priority
    }
}

/// Brief display modes based on context
enum BriefMode: String, Codable, CaseIterable {
    case rush = "rush"
    case standard = "standard"
    case leisurely = "leisurely"
    case commute = "commute"
    case weekend = "weekend"
    
    var displayName: String {
        switch self {
        case .rush: return "Quick Brief"
        case .standard: return "Standard Brief"
        case .leisurely: return "Extended Brief"
        case .commute: return "Commute Brief"
        case .weekend: return "Weekend Brief"
        }
    }
    
    var icon: String {
        switch self {
        case .rush: return "bolt.fill"
        case .standard: return "newspaper.fill"
        case .leisurely: return "book.fill"
        case .commute: return "tram.fill"
        case .weekend: return "cup.and.saucer.fill"
        }
    }
    
    var targetReadTime: TimeInterval {
        switch self {
        case .rush: return 120 // 2 minutes
        case .standard: return 300 // 5 minutes
        case .leisurely: return 900 // 15 minutes
        case .commute: return 600 // 10 minutes
        case .weekend: return 1200 // 20 minutes
        }
    }
    
    var maxItems: Int {
        switch self {
        case .rush: return 5
        case .standard: return 10
        case .leisurely: return 15
        case .commute: return 8
        case .weekend: return 12
        }
    }
    
    var color: Color {
        switch self {
        case .rush: return .orange
        case .standard: return .blue
        case .leisurely: return .purple
        case .commute: return .green
        case .weekend: return .indigo
        }
    }
}

/// Categories for organizing brief content
enum BriefCategory: String, Codable, CaseIterable {
    case topStories = "top_stories"
    case updates = "updates"
    case trending = "trending"
    case podcasts = "podcasts"
    case social = "social"
    case discovery = "discovery"
    
    var displayName: String {
        switch self {
        case .topStories: return "Top Stories"
        case .updates: return "Updates"
        case .trending: return "Trending"
        case .podcasts: return "Audio"
        case .social: return "Social"
        case .discovery: return "Discover"
        }
    }
    
    var icon: String {
        switch self {
        case .topStories: return "star.fill"
        case .updates: return "arrow.triangle.2.circlepath"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .podcasts: return "headphones"
        case .social: return "person.2.fill"
        case .discovery: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .topStories: return .blue
        case .updates: return .orange
        case .trending: return .purple
        case .podcasts: return .green
        case .social: return .pink
        case .discovery: return .indigo
        }
    }
}

/// Selection reason for transparency
enum SelectionReason: String, Codable {
    case topStory = "top_story"
    case trending = "trending"
    case followUp = "follow_up"
    case fromTrustedSource = "trusted_source"
    case highEngagement = "high_engagement"
    case recentlyPublished = "recently_published"
    case diversityPick = "diversity_pick"
    case userInterest = "user_interest"
    
    var explanation: String {
        switch self {
        case .topStory: return "Top story from your sources"
        case .trending: return "Trending in your network"
        case .followUp: return "Update on story you followed"
        case .fromTrustedSource: return "From a source you read often"
        case .highEngagement: return "Getting lots of discussion"
        case .recentlyPublished: return "Just published"
        case .diversityPick: return "Different perspective"
        case .userInterest: return "Matches your interests"
        }
    }
}

/// User behavior tracking for personalization
struct BriefUserBehavior {
    var preferredReadingTimes: [Date] = []
    var averageReadTime: TimeInterval = 300 // 5 minutes default
    var preferredCategories: [BriefCategory: Double] = [:]
    var engagementHistory: [BriefEngagement] = []
    var lastBriefDate: Date?
    
    mutating func recordEngagement(_ engagement: BriefEngagement) {
        engagementHistory.append(engagement)
        // Keep only last 30 days of history
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        engagementHistory = engagementHistory.filter { $0.date > cutoffDate }
    }
}

/// Track how users interact with brief items
struct BriefEngagement {
    let briefItemId: UUID
    let contentId: UUID
    let date: Date
    let timeSpent: TimeInterval
    let action: EngagementAction
    
    enum EngagementAction: String, Codable {
        case viewed = "viewed"
        case clicked = "clicked"
        case shared = "shared"
        case saved = "saved"
        case dismissed = "dismissed"
    }
}
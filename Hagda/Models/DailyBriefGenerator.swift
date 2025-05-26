import Foundation
import SwiftUI

/// Generates daily briefs based on user sources and behavior
class DailyBriefGenerator: ObservableObject {
    @Published var currentBrief: DailyBrief?
    @Published var isGenerating = false
    @Published var lastError: Error?
    
    private let appModel: AppModel
    private var userBehavior = BriefUserBehavior()
    
    init(appModel: AppModel) {
        self.appModel = appModel
        loadUserBehavior()
    }
    
    // MARK: - Public Methods
    
    /// Generate a new daily brief
    func generateBrief(mode: BriefMode? = nil) async {
        isGenerating = true
        lastError = nil
        
        // Determine the appropriate mode
        let briefMode = mode ?? determineBestMode()
        
        // Fetch recent content from all sources
        let recentContent = await fetchRecentContent()
        
        // Score and select content
        let selectedItems = selectContent(from: recentContent, mode: briefMode)
        
        // Create brief items with context
        let briefItems = createBriefItems(from: selectedItems, mode: briefMode)
        
        // Calculate total read time
        let readTime = calculateReadTime(for: briefItems)
        
        // Create the brief
        let brief = DailyBrief(
            date: Date(),
            items: briefItems,
            readTime: readTime,
            mode: briefMode
        )
        
        currentBrief = brief
        userBehavior.lastBriefDate = Date()
        saveUserBehavior()
        
        isGenerating = false
    }
    
    /// Refresh the daily brief (useful when sources change)
    func refreshBrief() async {
        // Clear current brief to show loading state
        currentBrief = nil
        // Generate new brief with current mode or determine best mode
        await generateBrief()
    }
    
    /// Record user engagement with a brief item
    func recordEngagement(
        briefItemId: UUID,
        contentId: UUID,
        timeSpent: TimeInterval,
        action: BriefEngagement.EngagementAction
    ) {
        let engagement = BriefEngagement(
            briefItemId: briefItemId,
            contentId: contentId,
            date: Date(),
            timeSpent: timeSpent,
            action: action
        )
        
        userBehavior.recordEngagement(engagement)
        updateCategoryPreferences(for: briefItemId)
        saveUserBehavior()
    }
    
    // MARK: - Private Methods
    
    /// Fetch recent content from all selected sources
    private func fetchRecentContent() async -> [ContentItem] {
        let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // Last 24 hours
        
        var allContent: [ContentItem] = []
        
        // Get sources to fetch from
        let sourcesToFetch = appModel.feedSources.isEmpty ? appModel.sources.prefix(3).map { $0 } : appModel.feedSources
        
        // Fetch from each source type
        for source in sourcesToFetch {
            do {
                let content = try await appModel.getContentForSource(source)
                    .filter { $0.date > cutoffDate }
                allContent.append(contentsOf: content)
            } catch {
                // If fetching fails for a source, continue with others
                print("Failed to fetch content from \(source.name): \(error)")
            }
        }
        
        // If no content was fetched, create some sample content
        if allContent.isEmpty {
            // Get a few different source types for variety
            let sampleSources = appModel.sources.prefix(3)
            for source in sampleSources {
                let sampleItems = ContentItem.samplesForSource(source, count: 2)
                allContent.append(contentsOf: sampleItems)
            }
        }
        
        return allContent
    }
    
    /// Score and select content based on various factors
    private func selectContent(from content: [ContentItem], mode: BriefMode) -> [ScoredContent] {
        var selectedItems: [ScoredContent] = []
        var selectedSources: Set<UUID> = []
        var selectedTypes: [SourceType: Int] = [:]
        
        // Score all content
        let scoredContent = content.map { item in
            let score = calculateScore(
                for: item,
                selectedSources: selectedSources,
                selectedTypes: selectedTypes
            )
            return ScoredContent(content: item, score: score)
        }.sorted { $0.score > $1.score }
        
        // Select top items based on mode constraints
        let maxItems = mode.maxItems
        
        for scored in scoredContent {
            if selectedItems.count >= maxItems { break }
            
            // Ensure diversity
            let sourceCount = selectedSources.filter { $0 == scored.content.source.id }.count
            let typeCount = selectedTypes[scored.content.type, default: 0]
            
            // Skip if we have too many from same source or type
            if sourceCount >= 2 || typeCount >= maxItems / 2 { continue }
            
            selectedItems.append(scored)
            selectedSources.insert(scored.content.source.id)
            selectedTypes[scored.content.type, default: 0] += 1
        }
        
        return selectedItems
    }
    
    /// Calculate score for a content item
    private func calculateScore(
        for item: ContentItem,
        selectedSources: Set<UUID>,
        selectedTypes: [SourceType: Int]
    ) -> Double {
        var score = 0.0
        
        // Recency score (0-0.4)
        let hoursSincePublished = Date().timeIntervalSince(item.date) / 3600
        if hoursSincePublished < 6 {
            score += 0.4
        } else if hoursSincePublished < 12 {
            score += 0.3
        } else if hoursSincePublished < 18 {
            score += 0.2
        } else {
            score += 0.1
        }
        
        // Diversity bonus (0-0.3)
        if !selectedSources.contains(item.source.id) {
            score += 0.2
        }
        let typeCount = selectedTypes[item.type, default: 0]
        if typeCount == 0 {
            score += 0.1
        }
        
        // User preference score (0-0.2)
        if let categoryPref = userBehavior.preferredCategories[categoryForType(item.type)] {
            score += categoryPref * 0.2
        }
        
        // Random factor for discovery (0-0.1)
        score += Double.random(in: 0...0.1)
        
        return score
    }
    
    /// Create brief items with summaries and context
    private func createBriefItems(from scored: [ScoredContent], mode: BriefMode) -> [BriefItem] {
        return scored.enumerated().map { index, scoredContent in
            let content = scoredContent.content
            let category = categoryForType(content.type)
            
            // Generate summary based on content type
            let summary = generateSummary(for: content, mode: mode)
            
            // Determine selection reason
            let reason = determineReason(for: scoredContent, index: index)
            
            // Add personal context if available
            let context = generateContext(for: content)
            
            return BriefItem(
                content: content,
                reason: reason.explanation,
                context: context,
                summary: summary,
                category: category,
                priority: index
            )
        }
    }
    
    /// Generate a summary for content based on mode
    private func generateSummary(for content: ContentItem, mode: BriefMode) -> String {
        // For MVP, use subtitle or truncated description
        let baseText = content.subtitle.isEmpty ? content.description : content.subtitle
        
        let maxLength: Int
        switch mode {
        case .rush: maxLength = 50
        case .standard: maxLength = 100
        case .leisurely: maxLength = 150
        case .commute: maxLength = 80
        case .weekend: maxLength = 120
        }
        
        if baseText.count <= maxLength {
            return baseText
        } else {
            let truncated = String(baseText.prefix(maxLength))
            return truncated + "..."
        }
    }
    
    /// Determine why this content was selected
    private func determineReason(for scored: ScoredContent, index: Int) -> SelectionReason {
        if index < 3 {
            return .topStory
        } else if scored.score > 0.8 {
            return .highEngagement
        } else if Date().timeIntervalSince(scored.content.date) < 6 * 3600 {
            return .recentlyPublished
        } else {
            return .diversityPick
        }
    }
    
    /// Generate personal context for content
    private func generateContext(for content: ContentItem) -> String? {
        // For MVP, return nil. In future, this will analyze user history
        return nil
    }
    
    /// Calculate total read time for brief items
    private func calculateReadTime(for items: [BriefItem]) -> TimeInterval {
        return items.reduce(0) { total, item in
            // Estimate based on content type
            switch item.content.type {
            case .article:
                return total + 180 // 3 minutes
            case .reddit:
                return total + 120 // 2 minutes
            case .podcast:
                return total + 60 // 1 minute (just to see description)
            case .mastodon, .bluesky:
                return total + 60 // 1 minute
            }
        }
    }
    
    /// Determine the best mode based on current context
    private func determineBestMode() -> BriefMode {
        let hour = Calendar.current.component(.hour, from: Date())
        let isWeekend = Calendar.current.isDateInWeekend(Date())
        
        if isWeekend {
            return .weekend
        } else if hour >= 6 && hour < 9 {
            return .rush
        } else if hour >= 17 && hour < 19 {
            return .commute
        } else {
            return .standard
        }
    }
    
    /// Map content type to brief category
    private func categoryForType(_ type: SourceType) -> BriefCategory {
        switch type {
        case .article:
            return .topStories
        case .reddit:
            return .trending
        case .podcast:
            return .podcasts
        case .mastodon, .bluesky:
            return .social
        }
    }
    
    /// Update category preferences based on engagement
    private func updateCategoryPreferences(for briefItemId: UUID) {
        guard let brief = currentBrief,
              let item = brief.items.first(where: { $0.id == briefItemId }) else { return }
        
        let category = item.category
        let currentPref = userBehavior.preferredCategories[category, default: 0.5]
        userBehavior.preferredCategories[category] = min(currentPref + 0.1, 1.0)
        
        // Normalize preferences
        let total = userBehavior.preferredCategories.values.reduce(0, +)
        if total > 0 {
            for (key, value) in userBehavior.preferredCategories {
                userBehavior.preferredCategories[key] = value / total
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadUserBehavior() {
        // For MVP, we don't persist user behavior
        // In future, implement proper persistence
    }
    
    private func saveUserBehavior() {
        // For MVP, we don't persist user behavior
        // In future, implement proper persistence
    }
}

// MARK: - Supporting Types

private struct ScoredContent {
    let content: ContentItem
    let score: Double
}
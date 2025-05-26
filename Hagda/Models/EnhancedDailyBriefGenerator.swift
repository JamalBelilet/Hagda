import Foundation
import SwiftUI

/// Enhanced generator for daily briefs with personalization and engagement tracking
class EnhancedDailyBriefGenerator: DailyBriefGenerator {
    // MARK: - Properties
    
    @Published var userBehavior = BriefUserBehavior()
    @Published var contentScores: [UUID: Double] = [:] // Content ID to relevance score
    
    private let engagementWeight = 0.3
    private let recencyWeight = 0.3
    private let diversityWeight = 0.2
    private let sourcePreferenceWeight = 0.2
    
    // MARK: - Enhanced Brief Generation
    
    override func generateBrief(mode: BriefMode? = nil) async {
        let selectedMode = mode ?? currentBrief?.mode ?? determineOptimalMode()
        
        isGenerating = true
        lastError = nil
        
        do {
            // Fetch recent content from all selected sources
            let recentContent = await fetchRecentContentEnhanced()
            
            // Score and rank content based on multiple factors
            let scoredContent = await scoreContent(recentContent)
            
            // Select items based on mode constraints
            let selectedItems = selectItemsForMode(
                from: scoredContent,
                mode: selectedMode
            )
            
            // Generate brief items with summaries and reasons
            let briefItems = await generateBriefItems(from: selectedItems)
            
            // Calculate total read time
            let readTime = calculateReadTimeEnhanced(for: briefItems)
            
            // Create the brief
            let brief = DailyBrief(
                items: briefItems,
                readTime: readTime,
                mode: selectedMode
            )
            
            await MainActor.run {
                self.currentBrief = brief
                self.isGenerating = false
            }
            
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isGenerating = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchRecentContentEnhanced() async -> [ContentItem] {
        // For now, return sample content to avoid access issues
        // In a real implementation, this would be refactored to use proper access patterns
        return ContentItem.sampleItems
    }
    
    private func selectItemsForMode(from scoredContent: [(item: ContentItem, score: Double)], mode: BriefMode) -> [ContentItem] {
        let maxItems = mode.maxItems
        return Array(scoredContent.prefix(maxItems).map { $0.item })
    }
    
    private func calculateReadTimeEnhanced(for items: [BriefItem]) -> TimeInterval {
        // Estimate read time based on content type
        return items.reduce(0) { total, item in
            switch item.content.type {
            case .article:
                return total + 180 // 3 minutes per article
            case .reddit:
                return total + 120 // 2 minutes per reddit post
            case .podcast:
                return total + 300 // 5 minutes for podcast summary
            default:
                return total + 60 // 1 minute for other content
            }
        }
    }
    
    // MARK: - Content Scoring
    
    private func scoreContent(_ content: [ContentItem]) async -> [(item: ContentItem, score: Double)] {
        var scored: [(ContentItem, Double)] = []
        
        for item in content {
            var score = 0.0
            
            // Recency score (exponential decay)
            let hoursOld = -item.date.timeIntervalSinceNow / 3600
            let recencyScore = exp(-hoursOld / 24) // Half-life of 24 hours
            score += recencyScore * recencyWeight
            
            // Source preference score
            let sourceScore = getSourcePreferenceScore(for: item.source)
            score += sourceScore * sourcePreferenceWeight
            
            // Engagement prediction based on past behavior
            let engagementScore = predictEngagement(for: item)
            score += engagementScore * engagementWeight
            
            // Diversity bonus
            let diversityScore = calculateDiversityBonus(for: item, given: scored.map { $0.0 })
            score += diversityScore * diversityWeight
            
            // Store the score for later use
            contentScores[item.id] = score
            
            scored.append((item, score))
        }
        
        // Sort by score descending
        return scored.sorted { $0.1 > $1.1 }
    }
    
    // MARK: - Personalization Methods
    
    private func determineOptimalMode() -> BriefMode {
        let hour = Calendar.current.component(.hour, from: Date())
        let isWeekend = Calendar.current.isDateInWeekend(Date())
        
        // Time-based mode selection
        switch (hour, isWeekend) {
        case (6...9, false):
            return .rush // Morning rush hour
        case (17...19, false):
            return .commute // Evening commute
        case (_, true):
            return .weekend // Weekend mode
        case (20...23, _), (0...5, _):
            return .leisurely // Evening/night reading
        default:
            return .standard // Default daytime
        }
    }
    
    private func getSourcePreferenceScore(for source: Source) -> Double {
        // Check historical engagement with this source
        let sourceEngagements = userBehavior.engagementHistory.filter {
            $0.contentId == source.id
        }
        
        guard !sourceEngagements.isEmpty else { return 0.5 } // Neutral score for new sources
        
        // Calculate engagement rate
        let positiveEngagements = sourceEngagements.filter {
            $0.action != .dismissed
        }.count
        
        return Double(positiveEngagements) / Double(sourceEngagements.count)
    }
    
    private func predictEngagement(for item: ContentItem) -> Double {
        // Simple engagement prediction based on content type and category preferences
        var score = 0.5 // Base score
        
        // Boost for preferred content types
        if let typePreference = userBehavior.preferredCategories[.topStories] {
            score += typePreference * 0.2
        }
        
        // Boost for items similar to previously engaged content
        let similarEngagements = userBehavior.engagementHistory.filter { engagement in
            // Simple similarity: same source or type
            engagement.contentId == item.source.id
        }
        
        if !similarEngagements.isEmpty {
            let avgTimeSpent = similarEngagements.map { $0.timeSpent }.reduce(0, +) / Double(similarEngagements.count)
            // Normalize time spent to 0-1 range (assuming 5 minutes is max)
            score += min(avgTimeSpent / 300, 1.0) * 0.3
        }
        
        return score
    }
    
    private func calculateDiversityBonus(for item: ContentItem, given selected: [ContentItem]) -> Double {
        // Bonus for different source types and topics
        let sameTypeCount = selected.filter { $0.source.type == item.source.type }.count
        let sameSourceCount = selected.filter { $0.source.id == item.source.id }.count
        
        // Penalize repetition
        let typePenalty = Double(sameTypeCount) * 0.1
        let sourcePenalty = Double(sameSourceCount) * 0.2
        
        return max(0, 1.0 - typePenalty - sourcePenalty)
    }
    
    // MARK: - Brief Item Generation
    
    private func generateBriefItems(from content: [ContentItem]) async -> [BriefItem] {
        var items: [BriefItem] = []
        
        for (index, contentItem) in content.enumerated() {
            let category = categorizeContent(contentItem)
            let reason = generateReason(for: contentItem, at: index)
            let summary = await generateSummary(for: contentItem)
            
            let briefItem = BriefItem(
                content: contentItem,
                reason: reason,
                context: generateContext(for: contentItem),
                summary: summary,
                category: category,
                priority: index
            )
            
            items.append(briefItem)
        }
        
        return items
    }
    
    private func categorizeContent(_ item: ContentItem) -> BriefCategory {
        // Categorize based on multiple factors
        let score = contentScores[item.id] ?? 0.5
        let isRecent = -item.date.timeIntervalSinceNow < 3600 // Less than 1 hour old
        let isTrending = score > 0.8
        
        switch item.type {
        case .podcast:
            return .podcasts
        case .bluesky, .mastodon:
            return .social
        case .article:
            if isRecent && isTrending {
                return .trending
            } else if score > 0.7 {
                return .topStories
            } else {
                return .discovery
            }
        case .reddit:
            if isTrending {
                return .trending
            } else {
                return .social
            }
        }
    }
    
    private func generateReason(for item: ContentItem, at index: Int) -> String {
        let score = contentScores[item.id] ?? 0.5
        let isRecent = -item.date.timeIntervalSinceNow < 3600
        
        // Priority-based reasons
        if index == 0 && score > 0.8 {
            return SelectionReason.topStory.explanation
        } else if isRecent {
            return SelectionReason.recentlyPublished.explanation
        } else if score > 0.7 {
            return SelectionReason.highEngagement.explanation
        } else if userBehavior.engagementHistory.contains(where: { $0.contentId == item.source.id }) {
            return SelectionReason.fromTrustedSource.explanation
        } else {
            return SelectionReason.diversityPick.explanation
        }
    }
    
    private func generateContext(for item: ContentItem) -> String? {
        // Generate personal context if available
        let previousEngagements = userBehavior.engagementHistory.filter {
            $0.contentId == item.source.id
        }
        
        if !previousEngagements.isEmpty {
            let avgTime = previousEngagements.map { $0.timeSpent }.reduce(0, +) / Double(previousEngagements.count)
            let minutes = Int(avgTime / 60)
            return "You typically spend \(minutes) min on content from this source"
        }
        
        return nil
    }
    
    private func generateSummary(for item: ContentItem) async -> String {
        // In a real implementation, this would use AI/ML to generate summaries
        // For now, return a truncated version of the description
        let maxLength = 150
        
        let description = item.description.isEmpty ? item.subtitle : item.description
        if description.count > maxLength {
            let endIndex = description.index(description.startIndex, offsetBy: maxLength)
            return String(description[..<endIndex]) + "..."
        } else if !description.isEmpty {
            return description
        }
        
        return "Content from \(item.source.name) published \(item.relativeTimeString)."
    }
    
    // MARK: - Engagement Tracking
    
    func trackEngagement(for item: BriefItem, action: BriefEngagement.EngagementAction, timeSpent: TimeInterval = 0) {
        let engagement = BriefEngagement(
            briefItemId: item.id,
            contentId: item.content.id,
            date: Date(),
            timeSpent: timeSpent,
            action: action
        )
        
        userBehavior.recordEngagement(engagement)
        
        // Update category preferences
        let currentPreference = userBehavior.preferredCategories[item.category] ?? 0.5
        let adjustment = action == .clicked ? 0.1 : (action == .dismissed ? -0.1 : 0.05)
        userBehavior.preferredCategories[item.category] = min(1.0, max(0.0, currentPreference + adjustment))
        
        // Save user behavior
        saveUserBehavior()
    }
    
    // MARK: - Persistence
    
    private func saveUserBehavior() {
        // In a real app, this would persist to UserDefaults or Core Data
        // For now, just keep in memory
    }
    
    private func loadUserBehavior() {
        // In a real app, this would load from UserDefaults or Core Data
        // For now, just use defaults
    }
}

// MARK: - Preview Helper

extension EnhancedDailyBriefGenerator {
    static func preview() -> EnhancedDailyBriefGenerator {
        let appModel = AppModel()
        let generator = EnhancedDailyBriefGenerator(appModel: appModel)
        
        // Create sample brief with enhanced metadata
        let items = [
            BriefItem(
                content: ContentItem.sampleItems[0],
                reason: SelectionReason.topStory.explanation,
                context: "You typically spend 3 min on TechCrunch articles",
                summary: "Apple announces groundbreaking new framework for building cross-platform applications.",
                category: .topStories,
                priority: 0
            ),
            BriefItem(
                content: ContentItem.sampleItems[1],
                reason: SelectionReason.trending.explanation,
                summary: "Microsoft's latest AI model shows significant improvements in code generation.",
                category: .trending,
                priority: 1
            ),
            BriefItem(
                content: ContentItem.sampleItems[2],
                reason: SelectionReason.fromTrustedSource.explanation,
                context: "New episode from your favorite podcast",
                summary: "Deep dive into the future of quantum computing with industry experts.",
                category: .podcasts,
                priority: 2
            )
        ]
        
        generator.currentBrief = DailyBrief(
            items: items,
            readTime: 420, // 7 minutes
            mode: .standard
        )
        
        // Add some mock scores
        for item in items {
            generator.contentScores[item.content.id] = Double.random(in: 0.6...0.95)
        }
        
        return generator
    }
}
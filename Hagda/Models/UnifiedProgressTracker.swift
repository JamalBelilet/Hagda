import Foundation

/// Protocol for content that can be tracked for progress
protocol ProgressTrackable {
    var id: String { get }
    var contentType: SourceType { get }
}

/// Represents progress data for any content type
struct ProgressData: Codable {
    let itemId: String
    let contentType: SourceType
    let progressPercentage: Double
    let lastAccessedDate: Date
    let scrollPosition: CGFloat?
    let readingTime: TimeInterval?
    let currentTime: TimeInterval?
    let metadata: [String: String]
    
    var isInProgress: Bool {
        return progressPercentage > 0 && progressPercentage < 0.9
    }
    
    enum CodingKeys: String, CodingKey {
        case itemId
        case contentType
        case progressPercentage
        case lastAccessedDate
        case scrollPosition
        case readingTime
        case currentTime
        case metadata
    }
}

/// Unified progress tracking system for all content types
@MainActor
class UnifiedProgressTracker {
    static let shared = UnifiedProgressTracker()
    
    private let userDefaults = UserDefaults.standard
    private let progressPrefix = "unified_progress_"
    private let maxItems = 50
    private let cleanupThresholdDays = 30
    
    private init() {
        // Perform cleanup on init
        Task {
            await performCleanup()
        }
    }
    
    // MARK: - Save Progress
    
    func saveProgress(for item: ContentItem, progressPercentage: Double, scrollPosition: CGFloat? = nil, readingTime: TimeInterval? = nil) {
        let progress = ProgressData(
            itemId: item.id.uuidString,
            contentType: item.type,
            progressPercentage: progressPercentage,
            lastAccessedDate: Date(),
            scrollPosition: scrollPosition,
            readingTime: readingTime,
            currentTime: nil,
            metadata: extractMetadata(from: item)
        )
        
        saveProgress(progress)
    }
    
    func saveProgress(_ progress: ProgressData) {
        let key = progressPrefix + progress.itemId
        
        if let encoded = try? JSONEncoder().encode(progress) {
            userDefaults.set(encoded, forKey: key)
        }
        
        // Enforce max items limit
        enforceMaxItemsLimit()
    }
    
    // MARK: - Load Progress
    
    func loadProgress(for itemId: String) -> ProgressData? {
        let key = progressPrefix + itemId
        
        guard let data = userDefaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(ProgressData.self, from: data) else {
            return nil
        }
        
        return progress
    }
    
    func getAllInProgressItems() -> [ProgressData] {
        let keys = userDefaults.dictionaryRepresentation().keys
        let progressKeys = keys.filter { $0.hasPrefix(progressPrefix) }
        
        let items = progressKeys.compactMap { key -> ProgressData? in
            guard let data = userDefaults.data(forKey: key),
                  let progress = try? JSONDecoder().decode(ProgressData.self, from: data) else {
                return nil
            }
            return progress.isInProgress ? progress : nil
        }
        
        // Sort by last accessed date, most recent first
        return items.sorted { $0.lastAccessedDate > $1.lastAccessedDate }
    }
    
    // MARK: - Clear Progress
    
    func clearProgress(for itemId: String) {
        let key = progressPrefix + itemId
        userDefaults.removeObject(forKey: key)
    }
    
    func clearAllProgress() {
        let keys = userDefaults.dictionaryRepresentation().keys
        let progressKeys = keys.filter { $0.hasPrefix(progressPrefix) }
        
        progressKeys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }
    
    // MARK: - Cleanup
    
    @MainActor
    private func performCleanup() async {
        await cleanupOldProgress()
        await cleanupCompletedItems()
    }
    
    private func cleanupOldProgress() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -cleanupThresholdDays, to: Date()) ?? Date()
        
        let keys = userDefaults.dictionaryRepresentation().keys
        let progressKeys = keys.filter { $0.hasPrefix(progressPrefix) }
        
        for key in progressKeys {
            guard let data = userDefaults.data(forKey: key),
                  let progress = try? JSONDecoder().decode(ProgressData.self, from: data) else {
                continue
            }
            
            if progress.lastAccessedDate < cutoffDate {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    private func cleanupCompletedItems() async {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let keys = userDefaults.dictionaryRepresentation().keys
        let progressKeys = keys.filter { $0.hasPrefix(progressPrefix) }
        
        for key in progressKeys {
            guard let data = userDefaults.data(forKey: key),
                  let progress = try? JSONDecoder().decode(ProgressData.self, from: data) else {
                continue
            }
            
            // Remove items that are >90% complete and older than 7 days
            if progress.progressPercentage > 0.9 && progress.lastAccessedDate < sevenDaysAgo {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    private func enforceMaxItemsLimit() {
        let allProgress = getAllProgressItems()
        
        if allProgress.count > maxItems {
            // Sort by last accessed date and remove oldest
            let sorted = allProgress.sorted { $0.lastAccessedDate > $1.lastAccessedDate }
            let toRemove = sorted.suffix(from: maxItems)
            
            toRemove.forEach { progress in
                clearProgress(for: progress.itemId)
            }
        }
    }
    
    private func getAllProgressItems() -> [ProgressData] {
        let keys = userDefaults.dictionaryRepresentation().keys
        let progressKeys = keys.filter { $0.hasPrefix(progressPrefix) }
        
        return progressKeys.compactMap { key -> ProgressData? in
            guard let data = userDefaults.data(forKey: key),
                  let progress = try? JSONDecoder().decode(ProgressData.self, from: data) else {
                return nil
            }
            return progress
        }
    }
    
    // MARK: - ContentItem Conversion
    
    func createContentItem(from progress: ProgressData) -> ContentItem {
        let title = progress.metadata["title"] ?? "Unknown"
        let subtitle = createSubtitle(for: progress)
        
        return ContentItem(
            id: UUID(uuidString: progress.itemId) ?? UUID(),
            title: title,
            subtitle: subtitle,
            date: progress.lastAccessedDate,
            type: progress.contentType,
            contentPreview: progress.metadata["contentPreview"] ?? "",
            progressPercentage: progress.progressPercentage,
            metadata: Dictionary(uniqueKeysWithValues: progress.metadata.map { ($0.key, $0.value as Any) })
        )
    }
    
    private func createSubtitle(for progress: ProgressData) -> String {
        switch progress.contentType {
        case .article:
            if let readingTime = progress.readingTime {
                let remainingTime = estimateRemainingTime(progress: progress.progressPercentage, totalTime: readingTime)
                return "\(Int(remainingTime / 60)) min left • \(progress.metadata["source"] ?? "Unknown source")"
            }
            return "\(Int(progress.progressPercentage * 100))% read • \(progress.metadata["source"] ?? "Unknown source")"
            
        case .podcast:
            if let duration = Double(progress.metadata["duration"] ?? "0") {
                let remainingTime = duration * (1 - progress.progressPercentage)
                return "\(Int(remainingTime / 60)) min left • \(progress.metadata["podcastName"] ?? "Unknown podcast")"
            }
            return progress.metadata["subtitle"] ?? "Podcast episode"
            
        case .reddit:
            let commentCount = progress.metadata["commentCount"] ?? "0"
            return "r/\(progress.metadata["subreddit"] ?? "unknown") • \(commentCount) comments"
            
        case .bluesky, .mastodon:
            return "@\(progress.metadata["author"] ?? "unknown") • \(progress.metadata["source"] ?? "")"
        }
    }
    
    private func estimateRemainingTime(progress: Double, totalTime: TimeInterval) -> TimeInterval {
        guard progress > 0 else { return totalTime }
        let estimatedTotal = totalTime / progress
        return estimatedTotal * (1 - progress)
    }
    
    private func extractMetadata(from item: ContentItem) -> [String: String] {
        var metadata: [String: String] = [:]
        
        // Extract common metadata
        metadata["title"] = item.title
        metadata["subtitle"] = item.subtitle
        metadata["contentPreview"] = item.contentPreview
        
        // Extract from item metadata
        for (key, value) in item.metadata {
            if let stringValue = value as? String {
                metadata[key] = stringValue
            } else if let numberValue = value as? NSNumber {
                metadata[key] = numberValue.stringValue
            }
        }
        
        return metadata
    }
}
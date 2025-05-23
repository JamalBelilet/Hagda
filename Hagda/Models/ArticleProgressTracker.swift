import Foundation
import SwiftUI

/// Specialized progress tracker for articles with reading-specific features
@MainActor
class ArticleProgressTracker: ObservableObject {
    static let shared = ArticleProgressTracker()
    
    @Published var currentProgress: Double = 0
    @Published var scrollPosition: CGFloat = 0
    @Published var isTracking: Bool = false
    
    private var readingStartTime: Date?
    private var totalReadingTime: TimeInterval = 0
    private var lastSaveTime: Date?
    private let saveDebounceInterval: TimeInterval = 3.0 // Save every 3 seconds
    private let unifiedTracker = UnifiedProgressTracker.shared
    
    private init() {}
    
    // MARK: - Start/Stop Tracking
    
    func startTracking(for item: ContentItem) {
        guard item.type == .article else { return }
        
        isTracking = true
        readingStartTime = Date()
        
        // Load existing progress if any
        if let existingProgress = unifiedTracker.loadProgress(for: item.id.uuidString) {
            currentProgress = existingProgress.progressPercentage
            scrollPosition = existingProgress.scrollPosition ?? 0
            totalReadingTime = existingProgress.readingTime ?? 0
        } else {
            currentProgress = 0
            scrollPosition = 0
            totalReadingTime = 0
        }
    }
    
    func stopTracking(for item: ContentItem) {
        guard isTracking else { return }
        
        // Save final progress
        saveProgress(for: item, force: true)
        
        // Reset state
        isTracking = false
        readingStartTime = nil
        currentProgress = 0
        scrollPosition = 0
        totalReadingTime = 0
    }
    
    // MARK: - Progress Updates
    
    func updateScrollProgress(for item: ContentItem, scrollOffset: CGFloat, contentHeight: CGFloat, viewHeight: CGFloat) {
        guard isTracking, contentHeight > viewHeight else { return }
        
        // Calculate progress based on scroll position
        let maxScroll = contentHeight - viewHeight
        let progress = min(max(scrollOffset / maxScroll, 0), 1)
        
        currentProgress = progress
        scrollPosition = scrollOffset
        
        // Debounced save
        saveProgressDebounced(for: item)
    }
    
    func updateReadingProgress(for item: ContentItem, visibleText: String, totalText: String) {
        guard isTracking else { return }
        
        // Alternative progress calculation based on visible text
        if let visibleRange = totalText.range(of: visibleText) {
            let visibleLocation = totalText.distance(from: totalText.startIndex, to: visibleRange.lowerBound)
            let progress = Double(visibleLocation) / Double(totalText.count)
            currentProgress = max(currentProgress, progress) // Never decrease progress
        }
        
        saveProgressDebounced(for: item)
    }
    
    // MARK: - Progress Saving
    
    private func saveProgressDebounced(for item: ContentItem) {
        guard let lastSave = lastSaveTime else {
            saveProgress(for: item)
            return
        }
        
        if Date().timeIntervalSince(lastSave) >= saveDebounceInterval {
            saveProgress(for: item)
        }
    }
    
    private func saveProgress(for item: ContentItem, force: Bool = false) {
        guard isTracking || force else { return }
        
        // Calculate total reading time
        if let startTime = readingStartTime {
            let sessionTime = Date().timeIntervalSince(startTime)
            totalReadingTime += sessionTime
            readingStartTime = Date() // Reset for next interval
        }
        
        // Create progress data
        let progress = ProgressData(
            itemId: item.id.uuidString,
            contentType: .article,
            progressPercentage: currentProgress,
            lastAccessedDate: Date(),
            scrollPosition: scrollPosition,
            readingTime: totalReadingTime,
            currentTime: nil,
            metadata: extractArticleMetadata(from: item)
        )
        
        unifiedTracker.saveProgress(progress)
        lastSaveTime = Date()
    }
    
    // MARK: - Progress Restoration
    
    func restoreProgress(for item: ContentItem) -> (scrollPosition: CGFloat, progress: Double)? {
        guard let progress = unifiedTracker.loadProgress(for: item.id.uuidString) else {
            return nil
        }
        
        return (progress.scrollPosition ?? 0, progress.progressPercentage)
    }
    
    // MARK: - Reading Time Estimation
    
    func estimateRemainingReadingTime(for item: ContentItem, currentProgress: Double) -> TimeInterval? {
        guard currentProgress > 0, currentProgress < 1 else { return nil }
        
        if let progress = unifiedTracker.loadProgress(for: item.id.uuidString),
           let readingTime = progress.readingTime, readingTime > 0 {
            // Estimate based on actual reading speed
            let estimatedTotalTime = readingTime / currentProgress
            return estimatedTotalTime * (1 - currentProgress)
        }
        
        // Fallback: estimate based on word count (200 words per minute average)
        if let wordCountString = item.metadata["wordCount"] as? String,
           let wordCount = Int(wordCountString) {
            let totalMinutes = Double(wordCount) / 200.0
            let remainingMinutes = totalMinutes * (1 - currentProgress)
            return remainingMinutes * 60
        }
        
        return nil
    }
    
    // MARK: - Metadata Extraction
    
    private func extractArticleMetadata(from item: ContentItem) -> [String: String] {
        var metadata: [String: String] = [
            "title": item.title,
            "source": item.subtitle,
            "contentPreview": item.contentPreview
        ]
        
        // Add article-specific metadata
        if let author = item.metadata["author"] as? String {
            metadata["author"] = author
        }
        if let wordCount = item.metadata["wordCount"] {
            metadata["wordCount"] = "\(wordCount)"
        }
        if let url = item.metadata["url"] as? String {
            metadata["url"] = url
        }
        if let imageUrl = item.metadata["imageUrl"] as? String {
            metadata["imageUrl"] = imageUrl
        }
        
        return metadata
    }
    
    // MARK: - Cleanup
    
    func markAsRead(item: ContentItem) {
        let progress = ProgressData(
            itemId: item.id.uuidString,
            contentType: .article,
            progressPercentage: 1.0, // 100% complete
            lastAccessedDate: Date(),
            scrollPosition: nil,
            readingTime: totalReadingTime,
            currentTime: nil,
            metadata: extractArticleMetadata(from: item)
        )
        
        unifiedTracker.saveProgress(progress)
    }
}
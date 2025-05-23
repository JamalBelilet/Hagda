import Testing
import Foundation
@testable import Hagda

@Suite("ArticleProgressTracker Tests")
@MainActor
struct ArticleProgressTrackerTests {
    
    @Test("Track article reading progress")
    func testArticleProgressTracking() throws {
        let tracker = ArticleProgressTracker.shared
        let unifiedTracker = UnifiedProgressTracker.shared
        
        // Create test article
        let article = ContentItem(
            id: UUID(),
            title: "Test Article",
            subtitle: "Tech News • 5 min read",
            date: Date(),
            type: .article,
            contentPreview: "Article preview",
            progressPercentage: 0,
            metadata: [
                "author": "Jane Smith",
                "wordCount": "1000",
                "url": "https://example.com/article"
            ]
        )
        
        // Start tracking
        tracker.startTracking(for: article)
        #expect(tracker.isTracking == true)
        
        // Update scroll progress
        tracker.updateScrollProgress(
            for: article,
            scrollOffset: 500,
            contentHeight: 2000,
            viewHeight: 800
        )
        
        // Calculate expected progress: 500 / (2000 - 800) = 0.417
        #expect(tracker.currentProgress > 0.4)
        #expect(tracker.currentProgress < 0.45)
        #expect(tracker.scrollPosition == 500)
        
        // Stop tracking
        tracker.stopTracking(for: article)
        #expect(tracker.isTracking == false)
        
        // Verify progress was saved
        let savedProgress = unifiedTracker.loadProgress(for: article.id.uuidString)
        #expect(savedProgress != nil)
        #expect(savedProgress?.progressPercentage ?? 0 > 0.4)
        #expect(savedProgress?.scrollPosition == 500)
        
        // Cleanup
        unifiedTracker.clearProgress(for: article.id.uuidString)
    }
    
    @Test("Restore article progress")
    func testArticleProgressRestoration() throws {
        let tracker = ArticleProgressTracker.shared
        let unifiedTracker = UnifiedProgressTracker.shared
        
        // Create test article
        let article = ContentItem(
            id: UUID(),
            title: "Test Article for Restoration",
            subtitle: "News Source",
            date: Date(),
            type: .article,
            progressPercentage: 0
        )
        
        // Save some progress directly
        let progressData = ProgressData(
            itemId: article.id.uuidString,
            contentType: .article,
            progressPercentage: 0.75,
            lastAccessedDate: Date(),
            scrollPosition: 1500,
            readingTime: 240,
            currentTime: nil,
            metadata: ["title": article.title]
        )
        unifiedTracker.saveProgress(progressData)
        
        // Restore progress
        let restored = tracker.restoreProgress(for: article)
        #expect(restored != nil)
        #expect(restored?.scrollPosition == 1500)
        #expect(restored?.progress == 0.75)
        
        // Cleanup
        unifiedTracker.clearProgress(for: article.id.uuidString)
    }
    
    @Test("Estimate remaining reading time")
    func testRemainingTimeEstimation() throws {
        let tracker = ArticleProgressTracker.shared
        let unifiedTracker = UnifiedProgressTracker.shared
        
        // Create article with word count
        let article = ContentItem(
            id: UUID(),
            title: "Long Article",
            subtitle: "Magazine",
            date: Date(),
            type: .article,
            metadata: ["wordCount": "2000"] // 10 minutes at 200 wpm
        )
        
        // Test with no saved progress (word count based)
        let estimatedTime1 = tracker.estimateRemainingReadingTime(for: article, currentProgress: 0.3)
        #expect(estimatedTime1 != nil)
        if let time = estimatedTime1 {
            let minutes = time / 60
            #expect(minutes > 6 && minutes < 8) // ~7 minutes remaining
        }
        
        // Save some actual reading time
        let progressData = ProgressData(
            itemId: article.id.uuidString,
            contentType: .article,
            progressPercentage: 0.3,
            lastAccessedDate: Date(),
            scrollPosition: 300,
            readingTime: 180, // 3 minutes to read 30%
            currentTime: nil,
            metadata: ["wordCount": "2000"]
        )
        unifiedTracker.saveProgress(progressData)
        
        // Test with saved reading time
        let estimatedTime2 = tracker.estimateRemainingReadingTime(for: article, currentProgress: 0.3)
        #expect(estimatedTime2 != nil)
        if let time = estimatedTime2 {
            let minutes = time / 60
            #expect(minutes > 6 && minutes < 8) // Should estimate ~7 minutes based on actual speed
        }
        
        // Cleanup
        unifiedTracker.clearProgress(for: article.id.uuidString)
    }
    
    @Test("Mark article as read")
    func testMarkAsRead() throws {
        let tracker = ArticleProgressTracker.shared
        let unifiedTracker = UnifiedProgressTracker.shared
        
        // Create test article
        let article = ContentItem(
            id: UUID(),
            title: "Completed Article",
            subtitle: "Blog Post",
            date: Date(),
            type: .article,
            progressPercentage: 0
        )
        
        // Mark as read
        tracker.markAsRead(item: article)
        
        // Verify it's saved with 100% progress
        let savedProgress = unifiedTracker.loadProgress(for: article.id.uuidString)
        #expect(savedProgress != nil)
        #expect(savedProgress?.progressPercentage == 1.0)
        
        // Verify it's not in "in progress" items
        let inProgressItems = unifiedTracker.getAllInProgressItems()
        #expect(!inProgressItems.contains { $0.itemId == article.id.uuidString })
        
        // Cleanup
        unifiedTracker.clearProgress(for: article.id.uuidString)
    }
}
import Testing
import Foundation
@testable import Hagda

@Suite("UnifiedProgressTracker Tests")
@MainActor
struct UnifiedProgressTrackerTests {
    
    @Test("Save and load progress for different content types")
    func testSaveAndLoadProgress() throws {
        let tracker = UnifiedProgressTracker.shared
        
        // Create test content items
        let articleItem = ContentItem(
            id: UUID(),
            title: "Test Article",
            subtitle: "Test Source",
            date: Date(),
            type: .article,
            contentPreview: "Article content",
            progressPercentage: 0,
            metadata: ["author": "Test Author", "wordCount": "500"]
        )
        
        let redditItem = ContentItem(
            id: UUID(),
            title: "Test Reddit Post",
            subtitle: "r/test • 42 comments",
            date: Date(),
            type: .reddit,
            contentPreview: "Reddit content",
            progressPercentage: 0,
            metadata: ["subreddit": "test", "commentCount": "42"]
        )
        
        // Save progress
        tracker.saveProgress(for: articleItem, progressPercentage: 0.45, scrollPosition: 250.0, readingTime: 120.0)
        tracker.saveProgress(for: redditItem, progressPercentage: 0.3, scrollPosition: 100.0)
        
        // Load progress
        let articleProgress = tracker.loadProgress(for: articleItem.id.uuidString)
        let redditProgress = tracker.loadProgress(for: redditItem.id.uuidString)
        
        // Verify article progress
        #expect(articleProgress != nil)
        #expect(articleProgress?.progressPercentage == 0.45)
        #expect(articleProgress?.scrollPosition == 250.0)
        #expect(articleProgress?.readingTime == 120.0)
        #expect(articleProgress?.contentType == .article)
        
        // Verify reddit progress
        #expect(redditProgress != nil)
        #expect(redditProgress?.progressPercentage == 0.3)
        #expect(redditProgress?.scrollPosition == 100.0)
        #expect(redditProgress?.contentType == .reddit)
        
        // Cleanup
        tracker.clearProgress(for: articleItem.id.uuidString)
        tracker.clearProgress(for: redditItem.id.uuidString)
    }
    
    @Test("Get all in-progress items")
    func testGetAllInProgressItems() throws {
        let tracker = UnifiedProgressTracker.shared
        
        // Clear any existing progress
        tracker.clearAllProgress()
        
        // Create test items
        let items = (0..<5).map { index in
            ContentItem(
                id: UUID(),
                title: "Test Item \(index)",
                subtitle: "Test Source",
                date: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                type: index % 2 == 0 ? .article : .reddit,
                contentPreview: "Content \(index)",
                progressPercentage: 0
            )
        }
        
        // Save progress for items with different percentages
        tracker.saveProgress(for: items[0], progressPercentage: 0.5)  // In progress
        tracker.saveProgress(for: items[1], progressPercentage: 0.2)  // In progress
        tracker.saveProgress(for: items[2], progressPercentage: 0.95) // Completed (>90%)
        tracker.saveProgress(for: items[3], progressPercentage: 0.7)  // In progress
        tracker.saveProgress(for: items[4], progressPercentage: 0)    // Not started
        
        // Get in-progress items
        let inProgressItems = tracker.getAllInProgressItems()
        
        // Should only get items with 0 < progress < 0.9
        #expect(inProgressItems.count == 3)
        
        // Verify items are sorted by last accessed date (most recent first)
        if inProgressItems.count >= 2 {
            #expect(inProgressItems[0].lastAccessedDate >= inProgressItems[1].lastAccessedDate)
        }
        
        // Cleanup
        items.forEach { tracker.clearProgress(for: $0.id.uuidString) }
    }
    
    @Test("Create ContentItem from ProgressData")
    func testCreateContentItem() throws {
        let tracker = UnifiedProgressTracker.shared
        
        // Create progress data
        let progressData = ProgressData(
            itemId: UUID().uuidString,
            contentType: .article,
            progressPercentage: 0.6,
            lastAccessedDate: Date(),
            scrollPosition: 300,
            readingTime: 180,
            currentTime: nil,
            metadata: [
                "title": "Test Article Title",
                "source": "Tech News",
                "author": "John Doe",
                "wordCount": "1200"
            ]
        )
        
        // Create ContentItem
        let contentItem = tracker.createContentItem(from: progressData)
        
        // Verify conversion
        #expect(contentItem.title == "Test Article Title")
        #expect(contentItem.type == .article)
        #expect(contentItem.progressPercentage == 0.6)
        #expect(contentItem.subtitle.contains("min left"))
        #expect(contentItem.metadata?["author"] as? String == "John Doe")
    }
    
    @Test("Progress cleanup")
    func testProgressCleanup() throws {
        let tracker = UnifiedProgressTracker.shared
        
        // This test would require mocking Date or waiting for actual time to pass
        // For now, just verify the methods exist and don't crash
        tracker.clearAllProgress()
        
        // Create a test item
        let item = ContentItem(
            id: UUID(),
            title: "Test Cleanup Item",
            subtitle: "Test",
            date: Date(),
            type: .article,
            progressPercentage: 0
        )
        
        // Save and clear progress
        tracker.saveProgress(for: item, progressPercentage: 0.5)
        #expect(tracker.loadProgress(for: item.id.uuidString) != nil)
        
        tracker.clearProgress(for: item.id.uuidString)
        #expect(tracker.loadProgress(for: item.id.uuidString) == nil)
    }
}
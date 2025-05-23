# Continue Section Implementation Brainstorm

## Overview
Transform the Continue section from mock data to real progress tracking across all content types.

## Architecture Design

### 1. Unified Progress Tracking System
Create a general-purpose progress tracker that can handle all content types:

```swift
protocol ProgressTrackable {
    var id: String { get }
    var contentType: SourceType { get }
    var progressPercentage: Double { get }
    var lastAccessedDate: Date { get }
    var metadata: [String: Any] { get }
}

class UnifiedProgressTracker {
    static let shared = UnifiedProgressTracker()
    
    func saveProgress(for item: ContentItem, progress: ProgressData)
    func loadProgress(for itemId: String) -> ProgressData?
    func getAllInProgressItems() -> [ProgressData]
    func cleanupOldProgress(olderThan days: Int)
}

struct ProgressData {
    let itemId: String
    let contentType: SourceType
    let progressPercentage: Double
    let lastAccessedDate: Date
    let scrollPosition: CGFloat? // For articles
    let readingTime: TimeInterval? // For articles
    let currentTime: TimeInterval? // For podcasts
    let metadata: [String: Any]
}
```

### 2. Article Progress Tracking

#### Implementation Steps:
1. **Track Scroll Position**: Monitor ScrollView offset in ArticleDetailView
2. **Calculate Reading Progress**: Based on scroll position vs content height
3. **Estimate Reading Time**: Track time spent with article open and active
4. **Save Progress Points**: 
   - On scroll stop (debounced)
   - On navigation away
   - On app background
   - Every 30 seconds while reading

#### Code Structure:
```swift
extension ArticleDetailView {
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var readingStartTime: Date?
    
    func saveArticleProgress() {
        let progress = ProgressData(
            itemId: article.id,
            contentType: .article,
            progressPercentage: scrollOffset / contentHeight,
            lastAccessedDate: Date(),
            scrollPosition: scrollOffset,
            readingTime: Date().timeIntervalSince(readingStartTime ?? Date()),
            currentTime: nil,
            metadata: [
                "title": article.title,
                "source": article.source,
                "wordCount": article.wordCount
            ]
        )
        UnifiedProgressTracker.shared.saveProgress(for: article, progress: progress)
    }
}
```

### 3. Reddit Post Progress Tracking

#### Approach:
- Track if post content was expanded/read
- Monitor comments section scroll
- Save thread position if reading comments

#### Implementation:
```swift
struct RedditProgressData {
    let postId: String
    let hasReadPost: Bool
    let hasOpenedComments: Bool
    let commentScrollPosition: CGFloat?
    let lastCommentId: String? // To resume at specific comment
}
```

### 4. Social Media Progress Tracking

#### Considerations:
- Mastodon/Bluesky posts are typically short
- Track thread reading for multi-post threads
- Mark as "seen" rather than percentage-based progress

### 5. Data Persistence Strategy

#### Options Comparison:

**Option A: Enhanced UserDefaults (Current for Podcasts)**
- Pros: Simple, already implemented for podcasts
- Cons: Limited query capabilities, not ideal for complex data

**Option B: Core Data**
- Pros: Powerful queries, relationships, migration support
- Cons: More complex, might be overkill

**Option C: JSON File Storage**
- Pros: Simple, portable, easy to debug
- Cons: Need to manage file I/O, potential performance issues

**Option D: SQLite (via SQLite.swift)**
- Pros: Lightweight, fast, good query support
- Cons: Additional dependency

**Recommendation**: Start with enhanced UserDefaults (like PodcastProgressTracker) and migrate to Core Data if needed.

### 6. Implementation Priority

1. **Phase 1**: Article progress tracking (most valuable)
   - Scroll position tracking
   - Reading time estimation
   - Progress persistence
   
2. **Phase 2**: Reddit post tracking
   - Post read status
   - Comment thread position
   
3. **Phase 3**: Unified progress system
   - Merge podcast and article trackers
   - Add cleanup functionality
   
4. **Phase 4**: Social media tracking (if needed)

### 7. UI/UX Considerations

- Show progress as a visual indicator (progress bar/circle)
- Display "X min left" for articles based on reading speed
- Add "Remove from Continue" swipe action
- Sort by last accessed (most recent first)
- Limit Continue section to 10-15 items max

### 8. Progress Calculation Methods

**For Articles:**
```swift
// Method 1: Scroll-based (simple)
progressPercentage = scrollOffset / (contentHeight - viewHeight)

// Method 2: Word-based (more accurate)
progressPercentage = wordsRead / totalWords

// Method 3: Hybrid approach
// Use scroll position but adjust for actual content distribution
```

**For Reddit:**
```swift
// Binary for post (read/unread)
// Percentage for comments based on scroll
progressPercentage = hasReadPost ? 0.3 + (0.7 * commentScrollProgress) : 0
```

### 9. Automatic Cleanup Strategy

```swift
class ProgressCleanupManager {
    func performCleanup() {
        // Remove items older than 30 days
        // Remove items with >90% completion older than 7 days
        // Keep max 50 items, remove oldest when exceeding
        // Run cleanup on app launch and daily
    }
}
```

### 10. Migration Path

1. Keep existing mock data as fallback
2. Gradually replace with real data as it's collected
3. Remove mock data generation once sufficient real data exists

## Next Steps

1. Create ArticleProgressTracker similar to PodcastProgressTracker
2. Update ArticleDetailView to track and save progress
3. Modify ContinueReadingView to use real article progress
4. Implement progress restoration when opening articles
5. Add tests for article progress tracking
6. Plan unified progress system for future iteration
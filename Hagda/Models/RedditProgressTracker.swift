import Foundation
import SwiftUI

/// Progress tracking for Reddit posts and comment threads
@MainActor
class RedditProgressTracker: ObservableObject {
    static let shared = RedditProgressTracker()
    
    @Published var hasReadPost: Bool = false
    @Published var hasOpenedComments: Bool = false
    @Published var commentScrollPosition: CGFloat = 0
    @Published var lastViewedCommentId: String?
    
    private let unifiedTracker = UnifiedProgressTracker.shared
    private var currentPostId: String?
    
    private init() {}
    
    // MARK: - Post Tracking
    
    func markPostAsRead(item: ContentItem) {
        guard item.type == .reddit else { return }
        
        hasReadPost = true
        currentPostId = item.id.uuidString
        
        // Save progress
        saveProgress(for: item)
    }
    
    func markCommentsOpened(item: ContentItem) {
        guard item.type == .reddit else { return }
        
        hasOpenedComments = true
        saveProgress(for: item)
    }
    
    // MARK: - Comment Tracking
    
    func updateCommentScroll(for item: ContentItem, scrollOffset: CGFloat, contentHeight: CGFloat, viewHeight: CGFloat) {
        guard item.type == .reddit, contentHeight > viewHeight else { return }
        
        commentScrollPosition = scrollOffset
        
        // Calculate progress: 30% for reading post, 70% for comments
        let baseProgress = hasReadPost ? 0.3 : 0.0
        let maxScroll = contentHeight - viewHeight
        let commentProgress = min(max(scrollOffset / maxScroll, 0), 1) * 0.7
        let totalProgress = baseProgress + commentProgress
        
        saveProgress(for: item, progressPercentage: totalProgress)
    }
    
    func setLastViewedComment(commentId: String, for item: ContentItem) {
        lastViewedCommentId = commentId
        saveProgress(for: item)
    }
    
    // MARK: - Progress Management
    
    func startTracking(for item: ContentItem) {
        guard item.type == .reddit else { return }
        
        currentPostId = item.id.uuidString
        
        // Load existing progress
        if let progress = unifiedTracker.loadProgress(for: item.id.uuidString) {
            // Restore state from progress
            hasReadPost = progress.progressPercentage > 0
            hasOpenedComments = progress.progressPercentage > 0.3
            commentScrollPosition = progress.scrollPosition ?? 0
            lastViewedCommentId = progress.metadata["lastCommentId"]
        } else {
            // Reset state
            hasReadPost = false
            hasOpenedComments = false
            commentScrollPosition = 0
            lastViewedCommentId = nil
        }
    }
    
    func stopTracking() {
        currentPostId = nil
        hasReadPost = false
        hasOpenedComments = false
        commentScrollPosition = 0
        lastViewedCommentId = nil
    }
    
    // MARK: - Progress Saving
    
    private func saveProgress(for item: ContentItem, progressPercentage: Double? = nil) {
        let progress: Double
        if let provided = progressPercentage {
            progress = provided
        } else {
            // Calculate progress based on current state
            progress = hasReadPost ? (hasOpenedComments ? 0.35 : 0.3) : 0
        }
        
        let progressData = ProgressData(
            itemId: item.id.uuidString,
            contentType: .reddit,
            progressPercentage: progress,
            lastAccessedDate: Date(),
            scrollPosition: commentScrollPosition,
            readingTime: nil,
            currentTime: nil,
            metadata: extractRedditMetadata(from: item)
        )
        
        unifiedTracker.saveProgress(progressData)
    }
    
    // MARK: - Progress Restoration
    
    func restoreProgress(for item: ContentItem) -> (hasRead: Bool, scrollPosition: CGFloat, lastCommentId: String?)? {
        guard let progress = unifiedTracker.loadProgress(for: item.id.uuidString) else {
            return nil
        }
        
        let hasRead = progress.progressPercentage > 0
        let scrollPos = progress.scrollPosition ?? 0
        let lastComment = progress.metadata["lastCommentId"]
        
        return (hasRead, scrollPos, lastComment)
    }
    
    // MARK: - Metadata
    
    private func extractRedditMetadata(from item: ContentItem) -> [String: String] {
        var metadata: [String: String] = [
            "title": item.title,
            "subreddit": extractSubreddit(from: item.subtitle) ?? "unknown"
        ]
        
        // Add Reddit-specific metadata
        if let author = item.metadata["author"] as? String {
            metadata["author"] = author
        }
        if let commentCount = item.metadata["commentCount"] {
            metadata["commentCount"] = "\(commentCount)"
        }
        if let score = item.metadata["score"] {
            metadata["score"] = "\(score)"
        }
        if let postId = item.metadata["postId"] as? String {
            metadata["postId"] = postId
        }
        
        // Add tracking metadata
        if let lastComment = lastViewedCommentId {
            metadata["lastCommentId"] = lastComment
        }
        
        return metadata
    }
    
    private func extractSubreddit(from subtitle: String) -> String? {
        // Extract subreddit from subtitle like "r/programming • 42 comments"
        if subtitle.hasPrefix("r/") {
            let components = subtitle.split(separator: "•")
            if let first = components.first {
                return String(first.trimmingCharacters(in: .whitespaces).dropFirst(2))
            }
        }
        return nil
    }
}
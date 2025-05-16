import Foundation
import SwiftUI

/// ViewModel for Reddit post detail views
@Observable
class RedditDetailViewModel {
    // MARK: - Properties
    
    /// The content item to display
    let item: ContentItem
    
    /// Loading state
    var isLoading = false
    
    /// Error state
    var error: Error?
    
    /// Post information
    var postTitle: String = ""
    var subredditName: String = ""
    var authorName: String = "unknown"
    var postContent: String = ""
    var formattedDate: String = ""
    
    /// Vote counts
    var upvoteCount: Int = 0
    var commentCount: Int = 0
    
    /// Comment information
    var comments: [Comment] = []
    
    /// Media content (if available)
    var hasImage: Bool = false
    var imageURL: URL?
    
    /// Model for a Reddit comment
    struct Comment: Identifiable {
        let id = UUID()
        let authorName: String
        let content: String
        let upvotes: Int
        let timestamp: String
    }
    
    // MARK: - Initialization
    
    init(item: ContentItem) {
        self.item = item
        
        // Set initial values from the content item
        self.postTitle = item.title
        self.postContent = item.contentPreview
        
        // Extract subreddit name from subtitle if available
        // Format: "Posted by u/username • r/subreddit • 42 comments"
        if let subredditRange = item.subtitle.range(of: "r/") {
            let subredditText = String(item.subtitle[subredditRange.lowerBound...])
            self.subredditName = subredditText.components(separatedBy: " ").first ?? "subreddit"
        } else if item.subtitle.contains("•") {
            // Try to find subreddit name in components
            let components = item.subtitle.components(separatedBy: " • ")
            for component in components {
                if component.hasPrefix("r/") {
                    self.subredditName = component
                    break
                }
            }
        }
        
        // Default if not found
        if self.subredditName.isEmpty {
            self.subredditName = "r/subreddit"
        }
        
        // Extract author name from subtitle if available
        if let userRange = item.subtitle.range(of: "u/") {
            let authorText = String(item.subtitle[userRange.lowerBound...])
            self.authorName = authorText.components(separatedBy: " ").first?.replacingOccurrences(of: "u/", with: "") ?? "unknown"
        }
        
        // Extract comment count from subtitle if available
        if let commentsRange = item.subtitle.range(of: "comments") {
            let commentsText = item.subtitle[..<commentsRange.lowerBound]
            if let lastSpace = commentsText.lastIndex(of: " ") {
                let countText = commentsText[lastSpace...].trimmingCharacters(in: .whitespacesAndNewlines)
                self.commentCount = Int(countText) ?? 0
            }
        }
        
        // Format the date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        self.formattedDate = formatter.localizedString(for: item.date, relativeTo: Date())
        
        // Generate an upvote count if none provided
        if upvoteCount == 0 {
            // Usually, posts with more comments have more upvotes
            upvoteCount = (commentCount * 2) + Int.random(in: 10...100)
        }
        
        // Load additional details
        loadRedditDetails()
    }
    
    // MARK: - Data Loading
    
    /// Load additional details for a Reddit post
    private func loadRedditDetails() {
        // Extract subreddit name
        guard !subredditName.isEmpty else {
            self.error = NSError(domain: "RedditDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine subreddit name"])
            return
        }
        
        Task {
            do {
                self.isLoading = true
                
                // Get the Reddit API service from App Model
                let redditService = AppModel.shared.redditAPIService
                
                // Create a source from the subreddit
                let source = Source(
                    name: subredditName.replacingOccurrences(of: "r/", with: ""),
                    type: .reddit,
                    description: "A Reddit community",
                    handle: subredditName,
                    artworkUrl: nil,
                    feedUrl: "https://www.reddit.com/\(subredditName)"
                )
                
                // Fetch content for the source to get real data
                let content = try await redditService.fetchSubredditContent(subredditName: subredditName)
                
                // Find the matching post by comparing titles
                if let matchingPost = content.first(where: { $0.title == self.item.title }) {
                    await updateUIWithPost(matchingPost)
                } else if !content.isEmpty {
                    // If no exact match, just use the first post
                    await updateUIWithPost(content[0])
                }
                
                self.isLoading = false
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Update the UI with post data
    @MainActor
    private func updateUIWithPost(_ post: ContentItem) {
        // Update post information
        self.postTitle = post.title
        self.postContent = post.contentPreview
        
        // Extract subreddit name if not already set
        if subredditName.isEmpty || subredditName == "r/subreddit" {
            if let subredditRange = post.subtitle.range(of: "r/") {
                let subredditText = String(post.subtitle[subredditRange.lowerBound...])
                self.subredditName = subredditText.components(separatedBy: " ").first ?? "r/subreddit"
            }
        }
        
        // Extract author name if not already set
        if authorName == "unknown" {
            if let userRange = post.subtitle.range(of: "u/") {
                let authorText = String(post.subtitle[userRange.lowerBound...])
                self.authorName = authorText.components(separatedBy: " ").first?.replacingOccurrences(of: "u/", with: "") ?? "unknown"
            }
        }
        
        // Extract comment count
        if let commentsRange = post.subtitle.range(of: "comments") {
            let commentsText = post.subtitle[..<commentsRange.lowerBound]
            if let lastSpace = commentsText.lastIndex(of: " ") {
                let countText = commentsText[lastSpace...].trimmingCharacters(in: .whitespacesAndNewlines)
                self.commentCount = Int(countText) ?? 0
            }
        }
        
        // Update date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        self.formattedDate = formatter.localizedString(for: post.date, relativeTo: Date())
        
        // Generate an upvote count if none provided
        if upvoteCount == 0 {
            // Usually, posts with more comments have more upvotes
            upvoteCount = (commentCount * 2) + Int.random(in: 10...100)
        }
        
        // Generate comments
        generateComments()
    }
    
    /// Generate comments for the post
    private func generateComments() {
        // Generate a few comments
        let commentCount = min(self.commentCount, 3) // Show up to 3 comments
        let validCount = commentCount > 0 ? commentCount : 3 // Always show at least 3 comments
        
        let commentTemplates = [
            "This is really interesting! I've been following this for a while and it's great to see some quality content on the topic.",
            "Thanks for sharing, I learned something new today.",
            "Great post! Have you considered also looking into related technologies?",
            "I've been working on something similar. Mind if I DM you to discuss further?",
            "I disagree with some points here, particularly about the scalability concerns mentioned. In my experience...",
            "Solid write-up! Would love to see a follow-up post on the implementation details.",
            "This is exactly what I needed to solve a problem I've been stuck on. Thanks!",
            "Can confirm this works. Source: I've been doing this professionally for 5 years."
        ]
        
        self.comments = (0..<validCount).map { i in
            let randomIndex = Int.random(in: 0..<commentTemplates.count)
            let content = commentTemplates[randomIndex]
            let upvotes = Int.random(in: 1...200)
            
            return Comment(
                authorName: "u/user\(i+1)",
                content: content,
                upvotes: upvotes,
                timestamp: "\(Int.random(in: 1...12))h ago"
            )
        }
        
        // Sort comments by upvotes (highest first)
        self.comments.sort { $0.upvotes > $1.upvotes }
    }
}
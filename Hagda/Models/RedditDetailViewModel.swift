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
        let depth: Int
        let replies: [Comment]
    }
    
    // MARK: - Initialization
    
    init(item: ContentItem) {
        self.item = item
        
        // Set initial values from the content item
        self.postTitle = item.title
        self.postContent = item.contentPreview
        
        // Extract metadata if available
        if let metadata = item.metadata as? [String: Any] {
            self.subredditName = metadata["subredditPrefixed"] as? String ?? "r/subreddit"
            self.authorName = metadata["author"] as? String ?? "unknown"
            self.upvoteCount = metadata["ups"] as? Int ?? 0
            self.commentCount = metadata["numComments"] as? Int ?? 0
            self.postContent = metadata["selftext"] as? String ?? item.contentPreview
            
            // Check for media URL
            if let urlString = metadata["url"] as? String,
               let url = URL(string: urlString),
               urlString.hasSuffix(".jpg") || urlString.hasSuffix(".png") || urlString.hasSuffix(".gif") {
                self.imageURL = url
                self.hasImage = true
            }
        } else {
            // Fallback to parsing from subtitle
            // Extract subreddit name from subtitle if available
            if let subredditRange = item.subtitle.range(of: "r/") {
                let subredditText = String(item.subtitle[subredditRange.lowerBound...])
                self.subredditName = subredditText.components(separatedBy: " ").first ?? "subreddit"
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
        }
        
        // Format the date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        self.formattedDate = formatter.localizedString(for: item.date, relativeTo: Date())
        
        // Load additional details including comments
        loadRedditDetails()
    }
    
    // MARK: - Data Loading
    
    /// Load additional details for a Reddit post
    private func loadRedditDetails() {
        // Extract post ID and subreddit from metadata
        guard let metadata = item.metadata as? [String: Any],
              let postId = metadata["postId"] as? String,
              !subredditName.isEmpty else {
            self.error = NSError(domain: "RedditDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing post metadata"])
            return
        }
        
        Task {
            do {
                self.isLoading = true
                
                // Get the Reddit API service from App Model
                let redditService = AppModel.shared.getRedditAPIService()
                
                // Fetch comments for this specific post
                let redditComments = try await redditService.fetchPostComments(
                    subreddit: subredditName,
                    postId: postId,
                    limit: 50
                )
                
                // Convert Reddit comments to view model comments
                await MainActor.run {
                    self.comments = self.convertRedditComments(redditComments)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                    // Show at least a few placeholder comments on error
                    self.comments = self.generatePlaceholderComments()
                }
            }
        }
    }
    
    /// Convert Reddit API comments to view model comments
    private func convertRedditComments(_ redditComments: [RedditAPIService.RedditComment]) -> [Comment] {
        return redditComments.compactMap { redditComment in
            guard let author = redditComment.author,
                  let body = redditComment.body,
                  author != "[deleted]" else {
                return nil
            }
            
            // Format timestamp
            let date = Date(timeIntervalSince1970: redditComment.created_utc)
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let timestamp = formatter.localizedString(for: date, relativeTo: Date())
            
            // Convert nested replies recursively
            let replies = convertRedditComments(redditComment.replies)
            
            return Comment(
                authorName: "u/\(author)",
                content: body,
                upvotes: redditComment.ups,
                timestamp: timestamp,
                depth: redditComment.depth,
                replies: replies
            )
        }
    }
    
    /// Generate placeholder comments for error states
    private func generatePlaceholderComments() -> [Comment] {
        return [
            Comment(
                authorName: "u/AutoModerator",
                content: "Unable to load comments. Please check your connection and try again.",
                upvotes: 1,
                timestamp: "now",
                depth: 0,
                replies: []
            )
        ]
    }
}
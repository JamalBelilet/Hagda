import Foundation
import SwiftUI

/// ViewModel for social media detail views (BlueSky and Mastodon)
@Observable
class SocialDetailViewModel {
    // MARK: - Properties
    
    /// The content item to display
    let item: ContentItem
    
    /// Loading state
    var isLoading = false
    
    /// Error state
    var error: Error?
    
    /// Author information
    var authorName: String = ""
    var authorHandle: String = ""
    var authorAvatarURL: URL?
    
    /// Post information
    var postContent: String = ""
    var formattedDate: String = ""
    
    /// Interaction stats
    var likeCount: Int = 0
    var repostCount: Int = 0
    var replyCount: Int = 0
    
    /// Reply information
    var replies: [Reply] = []
    
    /// Media content (if available)
    var hasImage: Bool = false
    var imageURL: URL?
    
    /// Model for a reply to a social media post
    struct Reply: Identifiable {
        let id = UUID()
        let authorName: String
        let authorHandle: String
        let authorAvatarURL: URL?
        let content: String
        let timestamp: String
    }
    
    // MARK: - Initialization
    
    init(item: ContentItem) {
        self.item = item
        
        // Set initial values from the content item
        self.postContent = item.title
        
        // Extract metadata if available
        if let metadata = item.metadata as? [String: Any] {
            if item.type == .bluesky {
                self.authorHandle = metadata["authorHandle"] as? String ?? ""
                self.authorName = metadata["authorDisplayName"] as? String ?? ""
                self.replyCount = metadata["replyCount"] as? Int ?? 0
                self.repostCount = metadata["repostCount"] as? Int ?? 0
                self.likeCount = metadata["likeCount"] as? Int ?? 0
                
                if let avatarUrl = metadata["authorAvatar"] as? String, !avatarUrl.isEmpty {
                    self.authorAvatarURL = URL(string: avatarUrl)
                }
                
                self.postContent = metadata["text"] as? String ?? item.title
            } else if item.type == .mastodon {
                self.authorHandle = metadata["accountAcct"] as? String ?? ""
                self.authorName = metadata["accountDisplayName"] as? String ?? ""
                self.replyCount = metadata["repliesCount"] as? Int ?? 0
                self.repostCount = metadata["reblogsCount"] as? Int ?? 0
                self.likeCount = metadata["favouritesCount"] as? Int ?? 0
                
                if let avatarUrl = metadata["accountAvatar"] as? String, !avatarUrl.isEmpty {
                    self.authorAvatarURL = URL(string: avatarUrl)
                }
                
                self.postContent = metadata["content"] as? String ?? item.title
            }
        } else {
            // Fallback to parsing from subtitle
            if let atSymbolRange = item.subtitle.range(of: "@") {
                self.authorHandle = String(item.subtitle[atSymbolRange.lowerBound...])
                    .components(separatedBy: " ").first ?? ""
            }
        }
        
        // Format the date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        self.formattedDate = formatter.localizedString(for: item.date, relativeTo: Date())
        
        // Load additional details based on the item type
        if item.type == .bluesky {
            loadBlueSkyDetails()
        } else if item.type == .mastodon {
            loadMastodonDetails()
        }
    }
    
    // MARK: - Data Loading
    
    /// Load additional details for a BlueSky post
    private func loadBlueSkyDetails() {
        // Extract URI from metadata for thread fetching
        guard let metadata = item.metadata as? [String: Any],
              let uri = metadata["uri"] as? String else {
            // If no metadata, generate placeholder replies
            generatePlaceholderReplies()
            return
        }
        
        Task {
            do {
                self.isLoading = true
                
                // Get the BlueSky API service from App Model
                let blueSkyService = AppModel.shared.getBlueSkyAPIService()
                
                // Fetch thread (post with replies)
                let thread = try await blueSkyService.fetchPostThread(uri: uri, depth: 6)
                
                // Convert replies to our Reply model
                await MainActor.run {
                    self.replies = self.convertBlueSkyReplies(from: thread.replies ?? [])
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                    // Show placeholder replies on error
                    self.generatePlaceholderReplies()
                }
            }
        }
    }
    
    /// Load additional details for a Mastodon post
    private func loadMastodonDetails() {
        // Extract handle if available
        guard let handle = extractHandle() else {
            self.error = NSError(domain: "SocialDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine Mastodon handle"])
            return
        }
        
        Task {
            do {
                self.isLoading = true
                
                // Get the Mastodon API service from App Model
                let mastodonService = AppModel.shared.getMastodonAPIService()
                
                // Fetch content for the source to get real data
                if let source = createSourceFromHandle(handle) {
                    let content = try await mastodonService.fetchContentForSource(source)
                    
                    // Find the matching post by comparing titles
                    if let matchingPost = content.first(where: { $0.title == self.item.title }) {
                        await updateUIWithPost(matchingPost)
                    } else if !content.isEmpty {
                        // If no exact match, just use the first post
                        await updateUIWithPost(content[0])
                    }
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
    
    /// Extract the handle from the content item
    private func extractHandle() -> String? {
        // For BlueSky
        if item.type == .bluesky {
            // Try to extract from subtitle which typically has the format "@handle.bsky.social"
            if let handle = authorHandle.isEmpty ? nil : authorHandle {
                return handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
            }
        }
        
        // For Mastodon
        if item.type == .mastodon {
            // Try to extract from subtitle which typically has the format "@user@instance.social"
            if let handle = authorHandle.isEmpty ? nil : authorHandle {
                return handle
            }
        }
        
        return nil
    }
    
    /// Create a source object from a handle
    private func createSourceFromHandle(_ handle: String) -> Source? {
        return Source(
            name: authorName.isEmpty ? handle : authorName,
            type: item.type,
            description: "",
            handle: handle,
            artworkUrl: nil,
            feedUrl: item.type == .bluesky ? "https://bsky.app/profile/\(handle)" : nil
        )
    }
    
    /// Update the UI with post data
    @MainActor
    private func updateUIWithPost(_ post: ContentItem) {
        // Update post content
        self.postContent = post.title
        
        // Parse interaction counts from subtitle
        let subtitle = post.subtitle
        
        if item.type == .bluesky {
            // Example format: "@handle • 10 replies • 5 reposts • 20 likes"
            if subtitle.contains("replies") {
                let components = subtitle.components(separatedBy: " • ")
                
                for component in components.dropFirst() { // Skip the handle
                    if component.contains("replies") {
                        self.replyCount = extractNumber(from: component)
                    } else if component.contains("reposts") {
                        self.repostCount = extractNumber(from: component)
                    } else if component.contains("likes") {
                        self.likeCount = extractNumber(from: component)
                    }
                }
            }
        } else if item.type == .mastodon {
            // Example format: "@handle • 10 replies • 5 boosts • 20 favorites"
            if subtitle.contains("replies") {
                let components = subtitle.components(separatedBy: " • ")
                
                for component in components.dropFirst() { // Skip the handle
                    if component.contains("replies") {
                        self.replyCount = extractNumber(from: component)
                    } else if component.contains("boosts") {
                        self.repostCount = extractNumber(from: component)
                    } else if component.contains("favorites") {
                        self.likeCount = extractNumber(from: component)
                    }
                }
            }
        }
        
        // For now, use a placeholder avatar image
        // In a real app, we would fetch the actual author profile
        
        // Set formatted date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        self.formattedDate = formatter.localizedString(for: post.date, relativeTo: Date())
        
        // In a real app, we would fetch replies for the post
        generatePlaceholderReplies()
    }
    
    /// Extract a number from a string like "10 replies"
    private func extractNumber(from string: String) -> Int {
        let components = string.components(separatedBy: " ")
        if let first = components.first, let number = Int(first) {
            return number
        }
        return 0
    }
    
    /// Generate placeholder replies for error states
    private func generatePlaceholderReplies() {
        self.replies = [
            Reply(
                authorName: "System",
                authorHandle: "@system",
                authorAvatarURL: nil,
                content: "Unable to load replies. Please check your connection and try again.",
                timestamp: "now"
            )
        ]
    }
    
    /// Convert BlueSky thread replies to our Reply model
    private func convertBlueSkyReplies(from threads: [PostThread]) -> [Reply] {
        return threads.compactMap { thread in
            let post = thread.post
            
            // Format timestamp
            let date: Date
            if let postDate = ISO8601DateFormatter().date(from: post.record.createdAt) {
                date = postDate
            } else {
                date = Date()
            }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let timestamp = formatter.localizedString(for: date, relativeTo: Date())
            
            // Get avatar URL
            var avatarURL: URL? = nil
            if let avatar = post.author.avatar, !avatar.isEmpty {
                avatarURL = URL(string: avatar)
            }
            
            return Reply(
                authorName: post.author.displayName ?? post.author.handle,
                authorHandle: "@\(post.author.handle)",
                authorAvatarURL: avatarURL,
                content: post.record.text,
                timestamp: timestamp
            )
        }
    }
}
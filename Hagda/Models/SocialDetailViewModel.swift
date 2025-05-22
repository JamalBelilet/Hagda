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
        
        // Extract handle from subtitle if available
        if let atSymbolRange = item.subtitle.range(of: "@") {
            self.authorHandle = String(item.subtitle[atSymbolRange.lowerBound...])
                .components(separatedBy: " ").first ?? ""
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
        Task {
            do {
                self.isLoading = true
                
                // Get the BlueSky API service from App Model
                let blueSkyService = AppModel.shared.getBlueSkyAPIService()
                
                // Check if we have metadata with post URI
                let metadata = item.metadata
                if let postUri = metadata["postUri"] as? String {
                    
                    // TODO: Implement fetchPostThread in BlueSkyAPI
                    // For now, just update UI with metadata
                    await MainActor.run {
                        // Set author information from metadata
                        if let displayName = metadata["authorDisplayName"] as? String {
                            self.authorName = displayName
                        }
                        if let handle = metadata["authorHandle"] as? String {
                            self.authorHandle = "@\(handle)"
                        }
                        if let avatarUrl = metadata["authorAvatar"] as? String,
                           !avatarUrl.isEmpty {
                            self.authorAvatarURL = URL(string: avatarUrl)
                        }
                        
                        // Set interaction counts from metadata
                        if let replies = metadata["replyCount"] as? Int {
                            self.replyCount = replies
                        }
                        if let reposts = metadata["repostCount"] as? Int {
                            self.repostCount = reposts
                        }
                        if let likes = metadata["likeCount"] as? Int {
                            self.likeCount = likes
                        }
                        
                        // Process text if available
                        if let text = metadata["postText"] as? String {
                            self.postContent = text
                        }
                        
                        // For now, use placeholder replies until fetchPostThread is implemented
                        generatePlaceholderReplies()
                        
                        // Check for embedded images
                        if let embed = metadata["embedImages"] as? [[String: Any]],
                           let firstImage = embed.first,
                           let fullsizeUrl = firstImage["fullsize"] as? String {
                            self.hasImage = true
                            self.imageURL = URL(string: fullsizeUrl)
                        }
                    }
                } else {
                    // Fallback: try to extract handle and fetch content
                    guard let handle = extractHandle() else {
                        self.error = NSError(domain: "SocialDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine BlueSky handle"])
                        return
                    }
                    
                    // Fetch content for the source to get real data
                    if let source = createSourceFromHandle(handle) {
                        let content = try await blueSkyService.fetchContentForSource(source)
                        
                        // Find the matching post by comparing titles
                        if let matchingPost = content.first(where: { $0.title == self.item.title }) {
                            await updateUIWithPost(matchingPost)
                        } else if !content.isEmpty {
                            // If no exact match, just use the first post
                            await updateUIWithPost(content[0])
                        }
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
    
    /// Load additional details for a Mastodon post
    private func loadMastodonDetails() {
        Task {
            do {
                self.isLoading = true
                
                // Get the Mastodon API service from App Model
                let mastodonService = AppModel.shared.getMastodonAPIService()
                
                // Check if we have metadata with status ID
                let metadata = item.metadata
                if let statusId = metadata["statusId"] as? String {
                    
                    // Fetch the thread context using the status ID
                    let context = try await mastodonService.fetchThreadContext(statusID: statusId)
                    
                    // Update UI with the actual data from metadata
                    await MainActor.run {
                        // Set author information from metadata
                        if let displayName = metadata["accountDisplayName"] as? String {
                            self.authorName = displayName
                        }
                        if let handle = metadata["accountHandle"] as? String {
                            self.authorHandle = "@\(handle)"
                        }
                        if let avatarUrl = metadata["accountAvatar"] as? String,
                           !avatarUrl.isEmpty {
                            self.authorAvatarURL = URL(string: avatarUrl)
                        }
                        
                        // Set interaction counts from metadata
                        if let replies = metadata["repliesCount"] as? Int {
                            self.replyCount = replies
                        }
                        if let boosts = metadata["reblogsCount"] as? Int {
                            self.repostCount = boosts
                        }
                        if let favorites = metadata["favouritesCount"] as? Int {
                            self.likeCount = favorites
                        }
                        
                        // Process raw content if available
                        if let rawContent = metadata["rawContent"] as? String {
                            self.postContent = rawContent.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        
                        // Convert Mastodon statuses from context.descendants to replies
                        self.replies = context.descendants.prefix(10).map { status in
                            Reply(
                                authorName: status.account.display_name.isEmpty ? status.account.username : status.account.display_name,
                                authorHandle: "@\(status.account.acct)",
                                authorAvatarURL: status.account.avatar.flatMap { URL(string: $0) },
                                content: status.content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                                    .trimmingCharacters(in: .whitespacesAndNewlines),
                                timestamp: formatRelativeTime(from: status.parsedCreatedAt)
                            )
                        }
                        
                        // Check for media attachments
                        if let mediaAttachments = metadata["mediaAttachments"] as? [[String: Any]],
                           let firstImage = mediaAttachments.first(where: { ($0["type"] as? String) == "image" }),
                           let imageUrlString = firstImage["url"] as? String {
                            self.hasImage = true
                            self.imageURL = URL(string: imageUrlString)
                        }
                    }
                } else {
                    // Fallback: try to extract handle and fetch content
                    guard let handle = extractHandle() else {
                        self.error = NSError(domain: "SocialDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine Mastodon handle"])
                        return
                    }
                    
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
    
    /// Generate placeholder replies until we implement real reply fetching
    private func generatePlaceholderReplies() {
        let replyCount = min(self.replyCount, 3) // Show up to 3 replies
        
        self.replies = (0..<replyCount).map { i in
            Reply(
                authorName: "User \(i+1)",
                authorHandle: item.type == .bluesky ? "@user\(i+1).bsky.social" : "@user\(i+1)@mastodon.social",
                authorAvatarURL: nil,
                content: i == 0 ? "Great insights! I'd love to hear more about your perspective on this." : "I've had a similar experience and completely agree with your points.",
                timestamp: "\(Int.random(in: 1...12))h"
            )
        }
    }
    
    /// Format a date into relative time string
    private func formatRelativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Parse BlueSky date string to Date
    private func parseBlueskyDate(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        return Date()
    }
}
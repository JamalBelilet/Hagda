import Foundation
import SwiftUI

/// Represents a content item from a source, like an article, post, or episode
struct ContentItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let description: String
    let date: Date
    let type: SourceType
    let contentPreview: String
    let progressPercentage: Double
    let metadata: [String: Any]  // Store platform-specific data
    let source: Source
    
    // Implement Equatable to allow comparison of ContentItems
    static func == (lhs: ContentItem, rhs: ContentItem) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), title: String, subtitle: String, description: String = "", date: Date, type: SourceType, contentPreview: String = "", progressPercentage: Double = 0.0, metadata: [String: Any] = [:], source: Source? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.date = date
        self.type = type
        self.contentPreview = contentPreview
        self.progressPercentage = progressPercentage
        self.metadata = metadata
        // Use a default source if none provided
        self.source = source ?? Source(
            name: "Sample Source",
            type: type,
            description: "Sample source"
        )
    }
}

// MARK: - Helper Methods
extension ContentItem {
    /// Returns an appropriate icon for the content type
    var typeIcon: String {
        switch type {
        case .article: return "doc.text"
        case .reddit: return "bubble.left"
        case .bluesky: return "cloud"
        case .mastodon: return "message"
        case .podcast: return "headphones"
        }
    }
    
    /// Formats the date as a relative time string
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Returns a summary of the remaining content
    var remainingContentSummary: String {
        if contentPreview.isEmpty {
            return generateDefaultRemainingContentSummary()
        }
        return contentPreview
    }
    
    /// Returns an appropriate title for the remaining content based on type
    var remainingContentTitle: String {
        switch type {
        case .article:
            return "Remaining in this article"
        case .podcast:
            return "Coming up in this episode"
        case .reddit:
            return "Continue reading this post"
        case .bluesky, .mastodon:
            return "Continue this thread"
        }
    }
    
    /// Generate remaining time or content for display
    var remainingContentInfo: String {
        switch type {
        case .article:
            let remainingMins = Int(ceil(6.5 * (1 - progressPercentage)))
            return "\(remainingMins) min left to read"
        case .podcast:
            let totalSeconds = 45 * 60 // 45 minutes in seconds
            let remainingSeconds = Int(Double(totalSeconds) * (1 - progressPercentage))
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return "\(minutes):\(String(format: "%02d", seconds)) remaining"
        default:
            return "\(Int((1 - progressPercentage) * 100))% remaining"
        }
    }
    
    /// Generate a default preview if none is provided
    private func generateDefaultRemainingContentSummary() -> String {
        switch type {
        case .article:
            return "The article continues with a discussion of implementation details and best practices for developers. Key points include scalability considerations, performance optimizations, and real-world case studies."
        case .podcast:
            return "In the remainder of this episode, the hosts discuss practical applications and interview an industry expert about future trends. Topics include recent technological advancements and implications for developers."
        case .reddit:
            return "The post continues with detailed examples and community feedback. There are several code snippets and implementation suggestions from experienced developers."
        case .bluesky, .mastodon:
            return "This thread continues with responses from other users and additional context about the topic. Several interesting perspectives are shared in the replies."
        }
    }
}

// MARK: - Sample Data
extension ContentItem {
    /// Sample content items for testing
    static let sampleItems: [ContentItem] = [
        ContentItem(
            title: "SwiftUI 5.0 Released with Major Performance Improvements",
            subtitle: "TechCrunch • 2 hours ago",
            description: "Apple has released SwiftUI 5.0 with significant performance improvements and new features for developers.",
            date: Date().addingTimeInterval(-7200),
            type: .article,
            contentPreview: "Apple has released SwiftUI 5.0 with significant performance improvements...",
            progressPercentage: 0.3,
            source: Source(name: "TechCrunch", type: .article, description: "Tech news")
        ),
        ContentItem(
            title: "Discussion: Best practices for async/await in Swift",
            subtitle: "r/swift • 150 comments",
            description: "Community discussion about best practices and patterns for using async/await in Swift.",
            date: Date().addingTimeInterval(-14400),
            type: .reddit,
            contentPreview: "What are your favorite patterns when working with async/await?",
            progressPercentage: 0.0,
            source: Source(name: "r/swift", type: .reddit, description: "Swift programming")
        ),
        ContentItem(
            title: "Swift Talk: Advanced Concurrency Patterns",
            subtitle: "45 min • objc.io",
            description: "In this episode, we explore advanced concurrency patterns and how to use them effectively in your Swift code.",
            date: Date().addingTimeInterval(-86400),
            type: .podcast,
            contentPreview: "In this episode, we explore advanced concurrency patterns...",
            progressPercentage: 0.65,
            source: Source(name: "Swift Talk", type: .podcast, description: "Swift podcast")
        ),
        ContentItem(
            title: "New SwiftUI property wrappers are game changers",
            subtitle: "@johnsundell@mastodon.social",
            description: "Just discovered the new @Observable macro and it's amazing for simplifying state management.",
            date: Date().addingTimeInterval(-3600),
            type: .mastodon,
            contentPreview: "Just discovered the new @Observable macro and it's amazing...",
            progressPercentage: 0.0,
            source: Source(name: "@johnsundell", type: .mastodon, description: "Swift developer")
        ),
        ContentItem(
            title: "iOS 18 Beta 3 Released",
            subtitle: "MacRumors • 5 hours ago",
            description: "Apple has released the third beta of iOS 18 to developers with bug fixes and performance improvements.",
            date: Date().addingTimeInterval(-18000),
            type: .article,
            contentPreview: "Apple has released the third beta of iOS 18 to developers...",
            progressPercentage: 0.0,
            source: Source(name: "MacRumors", type: .article, description: "Apple news")
        )
    ]
    
    /// Generates sample content items for a given source
    static func samplesForSource(_ source: Source, count: Int = 15) -> [ContentItem] {
        let today = Date()
        let calendar = Calendar.current
        
        return (1...count).map { index in
            let daysAgo = Double(index) / 2.0
            let date = calendar.date(byAdding: .hour, value: -Int(daysAgo * 24), to: today) ?? today
            
            switch source.type {
            case .article:
                // Return loading state for articles since they're fetched from RSS
                return ContentItem(
                    title: "Loading articles...",
                    subtitle: "Fetching latest news",
                    description: "Content is being loaded from the source.",
                    date: date,
                    type: .article,
                    contentPreview: "",
                    progressPercentage: 0.0,
                    source: source
                )
            case .reddit:
                // Return empty item - real data should come from Reddit API
                return ContentItem(
                    title: "Loading Reddit content...",
                    subtitle: "Fetching from Reddit API",
                    description: "Content will be loaded from the Reddit API.",
                    date: date,
                    type: .reddit,
                    contentPreview: "Content will be loaded from the Reddit API.",
                    progressPercentage: 0.0,
                    source: source
                )
            case .bluesky:
                // Return empty item - real data should come from Bluesky API
                return ContentItem(
                    title: "Loading Bluesky content...",
                    subtitle: "Fetching from Bluesky API",
                    description: "Content will be loaded from the Bluesky API.",
                    date: date,
                    type: .bluesky,
                    contentPreview: "Content will be loaded from the Bluesky API.",
                    progressPercentage: 0.0,
                    source: source
                )
            case .mastodon:
                // Return loading state for Mastodon posts since they're fetched from API
                return ContentItem(
                    title: "Loading Mastodon posts...",
                    subtitle: "Fetching latest updates",
                    description: "Content is being loaded from Mastodon.",
                    date: date,
                    type: .mastodon,
                    contentPreview: "",
                    progressPercentage: 0.0,
                    source: source
                )
            case .podcast:
                // Return loading state for Podcast episodes since they're fetched from RSS
                return ContentItem(
                    title: "Loading podcast episodes...",
                    subtitle: "Fetching latest episodes",
                    description: "Episodes are being loaded from the podcast feed.",
                    date: date,
                    type: .podcast,
                    contentPreview: "",
                    progressPercentage: 0.0,
                    source: source
                )
            }
        }
    }
}

/// Displays a single content item in a row format
struct ContentItemRow: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(item.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: item.typeIcon)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                Text(item.relativeTimeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("ContentItem-\(item.id)")
    }
}

#Preview {
    List {
        ContentItemRow(item: ContentItem(
            title: "The Future of AI: What's Next?",
            subtitle: "Opinion by Sarah Johnson",
            description: "An exploration of upcoming AI developments and their implications.",
            date: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
            type: .article
        ))
        
        ContentItemRow(item: ContentItem(
            title: "Just discovered this amazing new programming tool!",
            subtitle: "Posted by u/tech_enthusiast • 42 comments",
            description: "A community member shares their experience with a new development tool.",
            date: Date().addingTimeInterval(-3600 * 24), // 1 day ago
            type: .reddit
        ))
    }
}

// MARK: - Date Extensions
extension Date {
    /// Returns a user-friendly time ago display string
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

/// Displays a podcast episode in a row format
struct PodcastEpisodeRow: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
            
            // Duration and date
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Text(item.subtitle) // Contains the duration
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Text(item.relativeTimeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Progress bar if episode is partially played
            if item.progressPercentage > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    ProgressView(value: item.progressPercentage, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                    
                    Text("\(Int(item.progressPercentage * 100))% played")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("PodcastEpisode-\(item.id)")
    }
}

#Preview("Podcast Episodes") {
    List {
        PodcastEpisodeRow(item: ContentItem(
            title: "Episode 142: The Future of Mobile Development",
            subtitle: "45 minutes",
            description: "Discussion about the future trends in mobile app development.",
            date: Date().addingTimeInterval(-3600 * 24), // 1 day ago
            type: .podcast,
            progressPercentage: 0.35
        ))
        
        PodcastEpisodeRow(item: ContentItem(
            title: "Interview with Tech Industry Leader",
            subtitle: "62 minutes",
            description: "An in-depth interview with a prominent figure in the tech industry.",
            date: Date().addingTimeInterval(-3600 * 72), // 3 days ago
            type: .podcast,
            progressPercentage: 0.0
        ))
    }
}
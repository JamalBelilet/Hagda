import Foundation
import SwiftUI

/// Represents a content item from a source, like an article, post, or episode
struct ContentItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let date: Date
    let type: SourceType
    let contentPreview: String
    let progressPercentage: Double
    let metadata: [String: Any]  // Store platform-specific data
    
    // Implement Equatable to allow comparison of ContentItems
    static func == (lhs: ContentItem, rhs: ContentItem) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), title: String, subtitle: String, date: Date, type: SourceType, contentPreview: String = "", progressPercentage: Double = 0.0, metadata: [String: Any] = [:]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.type = type
        self.contentPreview = contentPreview
        self.progressPercentage = progressPercentage
        self.metadata = metadata
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
                    date: date,
                    type: .article,
                    contentPreview: "",
                    progressPercentage: 0.0
                )
            case .reddit:
                // Return empty item - real data should come from Reddit API
                return ContentItem(
                    title: "Loading Reddit content...",
                    subtitle: "Fetching from Reddit API",
                    date: date,
                    type: .reddit,
                    contentPreview: "Content will be loaded from the Reddit API.",
                    progressPercentage: 0.0
                )
            case .bluesky:
                // Return empty item - real data should come from Bluesky API
                return ContentItem(
                    title: "Loading Bluesky content...",
                    subtitle: "Fetching from Bluesky API",
                    date: date,
                    type: .bluesky,
                    contentPreview: "Content will be loaded from the Bluesky API.",
                    progressPercentage: 0.0
                )
            case .mastodon:
                // Return loading state for Mastodon posts since they're fetched from API
                return ContentItem(
                    title: "Loading Mastodon posts...",
                    subtitle: "Fetching latest updates",
                    date: date,
                    type: .mastodon,
                    contentPreview: "",
                    progressPercentage: 0.0
                )
            case .podcast:
                // Return loading state for Podcast episodes since they're fetched from RSS
                return ContentItem(
                    title: "Loading podcast episodes...",
                    subtitle: "Fetching latest episodes",
                    date: date,
                    type: .podcast,
                    contentPreview: "",
                    progressPercentage: 0.0
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
            date: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
            type: .article
        ))
        
        ContentItemRow(item: ContentItem(
            title: "Just discovered this amazing new programming tool!",
            subtitle: "Posted by u/tech_enthusiast • 42 comments",
            date: Date().addingTimeInterval(-3600 * 24), // 1 day ago
            type: .reddit
        ))
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
            date: Date().addingTimeInterval(-3600 * 24), // 1 day ago
            type: .podcast,
            progressPercentage: 0.35
        ))
        
        PodcastEpisodeRow(item: ContentItem(
            title: "Interview with Tech Industry Leader",
            subtitle: "62 minutes",
            date: Date().addingTimeInterval(-3600 * 72), // 3 days ago
            type: .podcast,
            progressPercentage: 0.0
        ))
    }
}
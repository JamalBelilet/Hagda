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
    let metadata: [String: Any]
    
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
                let articlePreview = """
                The article explores various approaches to solving common development challenges. Key concepts covered include:
                
                • Architectural patterns for scalable applications
                • Performance optimizations for mobile interfaces
                • Data synchronization strategies
                • Best practices for cross-platform development
                """
                return ContentItem(
                    title: "The Future of \(["AI", "Technology", "Mobile", "Programming", "Web Development"].randomElement()!): What's Next?",
                    subtitle: "\(["Analysis", "Opinion", "Report", "Review"].randomElement()!) by \(["Sarah Johnson", "Mike Chen", "Aisha Patel", "David Kim"].randomElement()!)",
                    date: date,
                    type: .article,
                    contentPreview: articlePreview,
                    progressPercentage: Double.random(in: 0.25...0.75)
                )
            case .reddit:
                let redditPreview = """
                This post continues with a detailed explanation of the implementation process and challenges faced. The community has responded with several useful suggestions and alternative approaches.
                
                Several code examples are provided to demonstrate the solution in action.
                """
                return ContentItem(
                    title: "\(["Anyone else experiencing this issue with...", "Just discovered this amazing...", "What's your opinion on...", "Help needed with..."].randomElement()!)",
                    subtitle: "Posted by u/\(["tech_enthusiast", "code_master", "curious_dev", "web_wizard"].randomElement()!) • \(Int.random(in: 5...500)) comments",
                    date: date,
                    type: .reddit,
                    contentPreview: redditPreview,
                    progressPercentage: Double.random(in: 0.25...0.75)
                )
            case .bluesky:
                let socialPreview = "The thread continues with additional insights about the latest technology trends and practical advice for implementation. There's a discussion about potential use cases and limitations."
                return ContentItem(
                    title: "\(["Just shipped a new feature for...", "Thoughts on the latest tech trends...", "Working on something exciting...", "Anyone going to the tech conference?"].randomElement()!)",
                    subtitle: "@\(["skypro", "techblogger", "devguru", "codemaster"].randomElement()!).bsky.social",
                    date: date,
                    type: .bluesky,
                    contentPreview: socialPreview,
                    progressPercentage: Double.random(in: 0.25...0.75)
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
                let podcastPreview = """
                In the remainder of this episode:
                
                • Interview with a leading industry expert about emerging technologies
                • Practical applications and implementation strategies
                • Analysis of market trends and future predictions
                • Q&A session addressing common developer questions
                """
                return ContentItem(
                    title: "Episode \(Int.random(in: 100...350)): \(["The State of Technology", "Interview with Industry Expert", "Deep Dive into New Frameworks", "Tech News Roundup"].randomElement()!)",
                    subtitle: "\(Int.random(in: 30...120)) minutes • \(["Interview", "Solo Episode", "Panel Discussion", "Q&A Session"].randomElement()!)",
                    date: date,
                    type: .podcast,
                    contentPreview: podcastPreview,
                    progressPercentage: Double.random(in: 0.25...0.75)
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
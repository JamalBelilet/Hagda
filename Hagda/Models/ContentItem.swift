import Foundation
import SwiftUI

/// Represents a content item from a source, like an article, post, or episode
struct ContentItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let date: Date
    let type: SourceType
    
    // Implement Equatable to allow comparison of ContentItems
    static func == (lhs: ContentItem, rhs: ContentItem) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), title: String, subtitle: String, date: Date, type: SourceType) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.date = date
        self.type = type
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
                return ContentItem(
                    title: "The Future of \(["AI", "Technology", "Mobile", "Programming", "Web Development"].randomElement()!): What's Next?",
                    subtitle: "\(["Analysis", "Opinion", "Report", "Review"].randomElement()!) by \(["Sarah Johnson", "Mike Chen", "Aisha Patel", "David Kim"].randomElement()!)",
                    date: date,
                    type: .article
                )
            case .reddit:
                return ContentItem(
                    title: "\(["Anyone else experiencing this issue with...", "Just discovered this amazing...", "What's your opinion on...", "Help needed with..."].randomElement()!)",
                    subtitle: "Posted by u/\(["tech_enthusiast", "code_master", "curious_dev", "web_wizard"].randomElement()!) • \(Int.random(in: 5...500)) comments",
                    date: date,
                    type: .reddit
                )
            case .bluesky:
                return ContentItem(
                    title: "\(["Just shipped a new feature for...", "Thoughts on the latest tech trends...", "Working on something exciting...", "Anyone going to the tech conference?"].randomElement()!)",
                    subtitle: "@\(["skypro", "techblogger", "devguru", "codemaster"].randomElement()!).bsky.social",
                    date: date,
                    type: .bluesky
                )
            case .mastodon:
                return ContentItem(
                    title: "\(["Just published my thoughts on...", "Here's my latest project update...", "Interesting development in tech today...", "Anyone else notice this trend?"].randomElement()!)",
                    subtitle: "@\(["techwriter", "opensourcefan", "devrelexpert", "codeartist"].randomElement()!)@mastodon.social",
                    date: date,
                    type: .mastodon
                )
            case .podcast:
                return ContentItem(
                    title: "Episode \(Int.random(in: 100...350)): \(["The State of Technology", "Interview with Industry Expert", "Deep Dive into New Frameworks", "Tech News Roundup"].randomElement()!)",
                    subtitle: "\(Int.random(in: 30...120)) minutes • \(["Interview", "Solo Episode", "Panel Discussion", "Q&A Session"].randomElement()!)",
                    date: date,
                    type: .podcast
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
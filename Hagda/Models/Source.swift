import Foundation

/// Represents the different types of content sources available in the app
enum SourceType: String, CaseIterable, Identifiable {
    case article
    case reddit
    case bluesky
    case mastodon
    case podcast
    
    var id: String { rawValue }
    
    /// The SF Symbol icon name for this source type
    var icon: String {
        switch self {
        case .article: return "doc.text"
        case .reddit: return "bubble.left"
        case .bluesky: return "cloud"
        case .mastodon: return "message"
        case .podcast: return "headphones"
        }
    }
    
    /// User-friendly display name for this source type
    var displayName: String {
        switch self {
        case .article: return "News"
        case .reddit: return "Reddit"
        case .bluesky: return "Bluesky"
        case .mastodon: return "Mastodon"
        case .podcast: return "Podcast"
        }
    }
    
    /// Localized search placeholder text for this source type
    var searchPlaceholder: String {
        switch self {
        case .article: return "Search for news source..."
        case .reddit: return "Enter subreddit name..."
        case .bluesky: return "Enter Bluesky handle..."
        case .mastodon: return "Enter Mastodon handle..."
        case .podcast: return "Search for podcast..."
        }
    }
    
    /// Default section header title for this source type 
    var sectionTitle: String {
        switch self {
        case .article: return "Top Tech Articles"
        case .reddit: return "Reddit Communities"
        case .bluesky, .mastodon: return "Social Media"
        case .podcast: return "Tech Podcasts"
        }
    }
    
    /// Default section description for this source type
    var sectionDescription: String {
        switch self {
        case .article: return "Latest articles from tech news sources"
        case .reddit: return "Trending posts from popular subreddits"
        case .bluesky, .mastodon: return "Updates from people you follow"
        case .podcast: return "Latest episodes from your favorite shows"
        }
    }
}

/// Represents a content source that can be followed and displayed in the feed
struct Source: Identifiable {
    let id = UUID()
    let name: String
    let type: SourceType
    let description: String
    let handle: String?
    
    init(name: String, type: SourceType, description: String, handle: String? = nil) {
        self.name = name
        self.type = type
        self.description = description
        self.handle = handle
    }
}

// MARK: - Sample Data
extension Source {
    /// Sample sources for development and preview purposes
    static var sampleSources: [Source] {
        [
            // Articles
            Source(name: "TechCrunch", type: .article, description: "Breaking technology news, analysis, and opinions.", handle: nil),
            Source(name: "Wired", type: .article, description: "In-depth articles about the impact of technology on our world.", handle: nil),
            Source(name: "The Verge", type: .article, description: "Covering the intersection of technology, science, art, and culture.", handle: nil),
            
            // Reddit
            Source(name: "r/dataisbeautiful", type: .reddit, description: "A place to share and discuss visualizations of data.", handle: "r/dataisbeautiful"),
            Source(name: "r/gadgets", type: .reddit, description: "Explore the latest gadgets and technology.", handle: "r/gadgets"),
            Source(name: "r/programming", type: .reddit, description: "A community for sharing news and tutorials related to programming.", handle: "r/programming"),
            Source(name: "r/science", type: .reddit, description: "Engage with scientific discoveries, research, and discussions.", handle: "r/science"),
            Source(name: "r/technology", type: .reddit, description: "The latest news and discussions on technology, gadgets, and startups.", handle: "r/technology"),
            
            // Bluesky
            Source(name: "Donnell Wals", type: .bluesky, description: "Creative tech videos and vlogs from Sara Dietschy.", handle: "donnywals.bsky.social"),
            
            // Mastodon
            Source(name: "TechCrunch", type: .mastodon, description: "Startup and technology news from TechCrunch.", handle: "@TechCrunch on Mastodon"),
            
            // Podcasts
            Source(name: "All-In", type: .podcast, description: "All-In features four best friends discussing everything from tech to politics, business, and beyond.", handle: "by Chamath, Jason, Sacks & Friedberg")
        ]
    }
}

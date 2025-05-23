import Foundation
import SwiftUI

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
    
    /// Color associated with this source type
    var color: Color {
        switch self {
        case .article: return .blue
        case .reddit: return .orange
        case .bluesky: return .cyan
        case .mastodon: return .purple
        case .podcast: return .green
        }
    }
    
    /// Localized search placeholder text for this source type
    var searchPlaceholder: String {
        switch self {
        case .article: return "Find news sources or enter URL..."
        case .reddit: return "Find subreddits..."
        case .bluesky: return "Find Bluesky profiles..."
        case .mastodon: return "Find Mastodon accounts..."
        case .podcast: return "Find podcasts..."
        }
    }
    
    /// Default section header title for this source type 
    var sectionTitle: String {
        switch self {
        case .article: return "Featured Articles"
        case .reddit: return "Reddit Communities"
        case .bluesky, .mastodon: return "Social Updates"
        case .podcast: return "Podcast Episodes"
        }
    }
    
    /// Default section description for this source type
    var sectionDescription: String {
        switch self {
        case .article: return "Fresh insights from your favorite publications"
        case .reddit: return "Hot discussions from communities you follow"
        case .bluesky, .mastodon: return "Latest posts from profiles you follow"
        case .podcast: return "New episodes ready for your listening queue"
        }
    }
}

/// Represents a content source that can be followed and displayed in the feed
struct Source: Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: SourceType
    let description: String
    let handle: String?
    let artworkUrl: String?
    let feedUrl: String?
    
    // Main initializer with all parameters
    init(id: UUID, name: String, type: SourceType, description: String, handle: String? = nil, artworkUrl: String? = nil, feedUrl: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.handle = handle
        self.artworkUrl = artworkUrl
        self.feedUrl = feedUrl
    }
    
    // Convenience initializer that generates a deterministic ID
    init(name: String, type: SourceType, description: String, handle: String? = nil, artworkUrl: String? = nil, feedUrl: String? = nil) {
        // Generate a deterministic ID based on name and type
        // This ensures the same source will have the same ID even when created multiple times
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(type.rawValue)
        // Add handle to hasher if it exists for more uniqueness
        if let handle = handle {
            hasher.combine(handle)
        }
        let hashValue = hasher.finalize()
        let id = UUID(uuid: (
            UInt8(truncatingIfNeeded: hashValue),
            UInt8(truncatingIfNeeded: hashValue >> 8),
            UInt8(truncatingIfNeeded: hashValue >> 16),
            UInt8(truncatingIfNeeded: hashValue >> 24),
            UInt8(truncatingIfNeeded: hashValue >> 32),
            UInt8(truncatingIfNeeded: hashValue >> 40),
            UInt8(truncatingIfNeeded: hashValue >> 48),
            UInt8(truncatingIfNeeded: hashValue >> 56),
            0, 0, 0, 0, 0, 0, 0, 0
        ))
        
        self.init(id: id, name: name, type: type, description: description, handle: handle, artworkUrl: artworkUrl, feedUrl: feedUrl)
    }
    
    // MARK: - Hashable Conformance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Source, rhs: Source) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Debug
    
    /// Debug description of the source
    var debugDescription: String {
        return "Source(\(name), type: \(type), id: \(id.uuidString.prefix(8)))"
    }
    
    /// Print debug information about this source
    func printDebugInfo() {
        print("DEBUG: Source: \(name) (Type: \(type))")
        print("DEBUG: ID: \(id)")
        print("DEBUG: Handle: \(handle ?? "nil")")
        print("DEBUG: Description: \(description)")
    }
}

// MARK: - Sample Data
extension Source {
    /// Sample sources for development and preview purposes
    static var sampleSources: [Source] {
        [
            // Articles
            Source(name: "TechCrunch", type: .article, description: "Leading technology media platform covering startups, tech news, and funding rounds.", handle: nil),
            Source(name: "The Verge", type: .article, description: "Exploring technology, science, art, and culture with in-depth reporting and reviews.", handle: nil),
            Source(name: "Ars Technica", type: .article, description: "Expert coverage for 'alpha geeks' on everything from hardware to software and scientific breakthroughs.", handle: nil),
            Source(name: "ZDNet", type: .article, description: "Business technology news and analysis for IT professionals and decision-makers.", handle: nil),
            Source(name: "MIT Technology Review", type: .article, description: "Insights on emerging technologies and innovation from one of the oldest tech publications.", handle: nil),
            
            // Reddit
            Source(name: "r/technology", type: .reddit, description: "Comprehensive coverage of tech news, trends, innovations, and industry debates.", handle: "r/technology"),
            Source(name: "r/Futurology", type: .reddit, description: "Exploring technological breakthroughs and their implications for humanity's future.", handle: "r/Futurology"),
            Source(name: "r/artificial", type: .reddit, description: "Discussions on AI and machine learning advancements, research, and applications.", handle: "r/artificial"),
            Source(name: "r/gadgets", type: .reddit, description: "Latest devices, from smartphones to wearables, with reviews and troubleshooting.", handle: "r/gadgets"),
            Source(name: "r/cybersecurity", type: .reddit, description: "Security news, threats, best practices, and career advice from industry professionals.", handle: "r/cybersecurity"),
            Source(name: "r/pcgaming", type: .reddit, description: "PC gaming discussions, hardware recommendations, and performance optimization tips.", handle: "r/pcgaming"),
            
            // Bluesky - removed hardcoded sources, users will search and add their own
            
            // Mastodon
            Source(name: "Eugen Rochko", type: .mastodon, description: "Founder and CEO of Mastodon sharing platform updates and decentralized web insights.", handle: "@Gargron@mastodon.social"),
            Source(name: "MIT Technology Review", type: .mastodon, description: "Cutting-edge reporting on AI, climate tech, biotechnology, and computing.", handle: "@techreview@mastodon.social"),
            Source(name: "The Verge", type: .mastodon, description: "Tech journalism covering products, science, and digital culture developments.", handle: "@verge@mastodon.social"),
            
            // Podcasts
            Source(name: "This Week in Tech", 
                  type: .podcast, 
                  description: "Leo Laporte and tech insiders explore the week's hottest tech news every Sunday.", 
                  handle: "by Leo Laporte and TWiT.tv",
                  feedUrl: "https://feeds.twit.tv/twit.xml"),
            Source(name: "Hard Fork", 
                  type: .podcast, 
                  description: "Kevin Roose and Casey Newton dive into pressing questions about AI and tech's impact on society.", 
                  handle: "by The New York Times",
                  feedUrl: "https://feeds.simplecast.com/l2i9YnTd"),
            Source(name: "The Vergecast", 
                  type: .podcast, 
                  description: "Making sense of the week's tech news with Nilay Patel and David Pierce.", 
                  handle: "by The Verge",
                  feedUrl: "https://feeds.megaphone.fm/vergecast"),
            Source(name: "Waveform", 
                  type: .podcast, 
                  description: "MKBHD's deep dives on consumer tech products, industry news, and behind-the-scenes insights.", 
                  handle: "by Marques Brownlee",
                  feedUrl: "https://feeds.megaphone.fm/STU4418364045")
        ]
    }
}

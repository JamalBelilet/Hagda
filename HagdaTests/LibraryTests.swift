import Testing
import SwiftUI
@testable import Hagda

struct LibraryModelTests {
    @Test func categoriesAreCorrectlyFormed() {
        let model = AppModel()
        let categories = model.categories
        
        // Verify expected categories exist
        #expect(categories["Top Tech Articles"] != nil)
        #expect(categories["Popular Subreddits"] != nil)
        #expect(categories["Tech Podcasts"] != nil)
        #expect(categories["Tech Influencers"] != nil)
        
        // Verify sources are categorized correctly
        #expect(categories["Top Tech Articles"]?.allSatisfy { $0.type == .article } == true)
        #expect(categories["Popular Subreddits"]?.allSatisfy { $0.type == .reddit } == true)
        #expect(categories["Tech Podcasts"]?.allSatisfy { $0.type == .podcast } == true)
        
        // Tech Influencers should contain bluesky and mastodon sources
        let influencers = categories["Tech Influencers"] ?? []
        #expect(influencers.contains(where: { $0.type == .bluesky || $0.type == .mastodon }))
    }
    
    @Test func sourceTypesHaveCorrectRepresentation() {
        #expect(SourceType.article.icon == "doc.text")
        #expect(SourceType.reddit.icon == "bubble.left.fill")
        #expect(SourceType.bluesky.icon == "cloud.fill")
        #expect(SourceType.mastodon.icon == "message.fill")
        #expect(SourceType.podcast.icon == "headphones")
    }
    
    @Test func sourcesHaveCorrectFormat() {
        let sources = Source.sampleSources
        
        for source in sources {
            // All sources should have valid IDs
            #expect(source.id != UUID())
            
            // All sources need a name and description
            #expect(!source.name.isEmpty)
            #expect(!source.description.isEmpty)
            
            // Handle matches type expectations
            switch source.type {
            case .reddit:
                #expect(source.handle?.hasPrefix("r/") ?? false)
            case .bluesky:
                #expect(source.handle?.contains(".bsky.") ?? false)
            case .mastodon:
                #expect(source.handle?.contains("@") ?? false)
            case .podcast:
                #expect(source.handle?.hasPrefix("by ") ?? true)
            case .article:
                break // Articles may not have handles
            }
        }
    }
}
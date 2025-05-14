import Testing
@testable import Hagda

struct SourceTests {
    @Test func sourcesShouldHaveUniqueIds() {
        let sources = Source.sampleSources
        let ids = sources.map { $0.id }
        let uniqueIds = Set(ids)
        
        #expect(ids.count == uniqueIds.count)
    }
    
    @Test func eachSourceTypeShouldBeRepresented() {
        let sources = Source.sampleSources
        let types = sources.map { $0.type }
        let uniqueTypes = Set(types)
        
        #expect(uniqueTypes.contains(.article))
        #expect(uniqueTypes.contains(.reddit))
        #expect(uniqueTypes.contains(.bluesky))
        #expect(uniqueTypes.contains(.mastodon))
        #expect(uniqueTypes.contains(.podcast))
    }
    
    @Test func sourceTypeAllCasesMatchesImplementation() {
        let allCases = SourceType.allCases
        #expect(allCases.count == 5)
        
        let expectedTypes: [SourceType] = [.article, .reddit, .bluesky, .mastodon, .podcast]
        for type in expectedTypes {
            #expect(allCases.contains(type))
        }
    }
}
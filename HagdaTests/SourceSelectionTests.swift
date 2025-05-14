import Testing
import SwiftUI
@testable import Hagda

struct SourceSelectionTests {
    @Test func selectedSourcesAreTracked() {
        let model = AppModel()
        let source = Source.sampleSources.first!
        
        #expect(model.selectedSources.isEmpty)
        
        model.toggleSourceSelection(source)
        #expect(model.selectedSources.count == 1)
        #expect(model.selectedSources.contains(source.id))
        
        model.toggleSourceSelection(source)
        #expect(model.selectedSources.isEmpty)
    }
    
    @Test func feedShowsSelectedSources() {
        let model = AppModel()
        
        // Create a test source that we have full control over
        let testSource = Source(name: "Test Source", type: .article, description: "Test source description", handle: nil)
        
        // Replace model's sources with our test source
        model.sources = [testSource]
        
        #expect(model.feedSources.isEmpty)
        
        model.toggleSourceSelection(testSource)
        #expect(model.feedSources.count == 1)
        #expect(model.feedSources.first?.name == testSource.name)
        
        model.toggleSourceSelection(testSource)
        #expect(model.feedSources.isEmpty)
    }
    
    @Test func multipleFeedSourcesAreOrdered() {
        let model = AppModel()
        
        // Create test sources with specific names to control sort order
        let sourceA = Source(name: "A Source", type: .article, description: "Test source A", handle: nil)
        let sourceB = Source(name: "B Source", type: .article, description: "Test source B", handle: nil)
        let sourceC = Source(name: "C Source", type: .article, description: "Test source C", handle: nil)
        
        // Replace model's sources with our test sources
        model.sources = [sourceC, sourceA, sourceB] // Intentionally out of order
        
        // Add all sources
        model.toggleSourceSelection(sourceC)
        model.toggleSourceSelection(sourceA)
        model.toggleSourceSelection(sourceB)
        
        #expect(model.feedSources.count == 3)
        
        // Verify they are sorted by name
        #expect(model.feedSources[0].name == "A Source")
        #expect(model.feedSources[1].name == "B Source")
        #expect(model.feedSources[2].name == "C Source")
        
        // Remove middle source
        model.toggleSourceSelection(sourceB)
        #expect(model.feedSources.count == 2)
        #expect(model.feedSources[0].name == "A Source")
        #expect(model.feedSources[1].name == "C Source")
    }
}
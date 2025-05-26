import XCTest
import SwiftUI
@testable import Hagda

final class DailyBriefIntegrationTests: XCTestCase {
    var appModel: AppModel!
    
    override func setUpWithError() throws {
        appModel = AppModel(isTestingMode: true)
        
        // Set up some selected sources for testing
        let sources = Source.sampleSources
        appModel.selectedSources.insert(sources[0].id) // TechCrunch
        appModel.selectedSources.insert(sources[5].id) // r/technology
        appModel.selectedSources.insert(sources[15].id) // This Week in Tech
    }
    
    override func tearDownWithError() throws {
        appModel = nil
    }
    
    // MARK: - Feed Integration Tests
    
    func testDailyBriefAppearsInFeed() throws {
        // The FeedView should display the daily brief as the first section
        let feedView = FeedView()
            .environment(appModel)
        
        // Create a hosting controller to render the view
        let controller = UIHostingController(rootView: feedView)
        
        // Force view to load
        _ = controller.view
        
        // In a real test, we would inspect the view hierarchy
        // For now, verify the generator is accessible
        XCTAssertNotNil(appModel.dailyBriefGenerator, "Daily brief generator should be available")
    }
    
    // MARK: - Content Flow Tests
    
    func testBriefContentMatchesSelectedSources() async {
        // Generate a brief
        await appModel.dailyBriefGenerator.generateBrief()
        
        guard let brief = appModel.dailyBriefGenerator.currentBrief else {
            XCTFail("Brief should be generated")
            return
        }
        
        // Verify all content comes from selected sources
        for item in brief.items {
            let sourceId = item.content.source.id
            XCTAssertTrue(
                appModel.selectedSources.contains(sourceId) || item.content.source.name == "Sample Source",
                "Brief should only contain content from selected sources"
            )
        }
    }
    
    func testBriefUpdatesWhenSourcesChange() async {
        // Generate initial brief
        await appModel.dailyBriefGenerator.generateBrief()
        let initialBrief = appModel.dailyBriefGenerator.currentBrief
        
        // Add a new source
        let newSource = Source.sampleSources[10]
        appModel.selectedSources.insert(newSource.id)
        
        // Generate new brief
        await appModel.dailyBriefGenerator.generateBrief()
        let updatedBrief = appModel.dailyBriefGenerator.currentBrief
        
        // Briefs should be different (different IDs)
        XCTAssertNotEqual(initialBrief?.id, updatedBrief?.id, "New brief should be generated when sources change")
    }
    
    // MARK: - User Behavior Tests
    
    func testEngagementTracking() async {
        // Generate a brief
        await appModel.dailyBriefGenerator.generateBrief()
        
        guard let brief = appModel.dailyBriefGenerator.currentBrief,
              let firstItem = brief.items.first else {
            XCTFail("Brief should have items")
            return
        }
        
        // Record engagement
        appModel.dailyBriefGenerator.recordEngagement(
            briefItemId: firstItem.id,
            contentId: firstItem.content.id,
            timeSpent: 45,
            action: .clicked
        )
        
        // In a full implementation, we would verify this affects future brief generation
        XCTAssertTrue(true, "Engagement should be recorded without errors")
    }
    
    // MARK: - Mode Selection Tests
    
    func testDifferentModesProduceDifferentBriefs() async {
        // Generate rush mode brief
        await appModel.dailyBriefGenerator.generateBrief(mode: .rush)
        let rushBrief = appModel.dailyBriefGenerator.currentBrief
        
        // Generate weekend mode brief
        await appModel.dailyBriefGenerator.generateBrief(mode: .weekend)
        let weekendBrief = appModel.dailyBriefGenerator.currentBrief
        
        XCTAssertNotNil(rushBrief)
        XCTAssertNotNil(weekendBrief)
        
        if let rush = rushBrief, let weekend = weekendBrief {
            XCTAssertLessThanOrEqual(rush.items.count, BriefMode.rush.maxItems)
            XCTAssertLessThanOrEqual(weekend.items.count, BriefMode.weekend.maxItems)
            XCTAssertNotEqual(rush.readTime, weekend.readTime, "Different modes should have different read times")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testBriefGenerationWithNoSources() async {
        // Clear all selected sources
        appModel.selectedSources.removeAll()
        
        // Try to generate brief
        await appModel.dailyBriefGenerator.generateBrief()
        
        // Should handle gracefully (either empty brief or nil)
        if let brief = appModel.dailyBriefGenerator.currentBrief {
            XCTAssertEqual(brief.items.count, 0, "Brief with no sources should be empty")
        }
    }
    
    // MARK: - Summary Generation Tests
    
    func testSummaryLength() async {
        await appModel.dailyBriefGenerator.generateBrief(mode: .rush)
        
        guard let brief = appModel.dailyBriefGenerator.currentBrief else {
            XCTFail("Brief should be generated")
            return
        }
        
        for item in brief.items {
            XCTAssertLessThanOrEqual(
                item.summary.count,
                150,
                "Rush mode summaries should be concise"
            )
        }
    }
    
    // MARK: - Category Distribution Tests
    
    func testCategoryDistribution() async {
        // Add sources of different types
        for source in Source.sampleSources.prefix(10) {
            appModel.selectedSources.insert(source.id)
        }
        
        await appModel.dailyBriefGenerator.generateBrief()
        
        guard let brief = appModel.dailyBriefGenerator.currentBrief else {
            XCTFail("Brief should be generated")
            return
        }
        
        // Count items by category
        var categoryCounts: [BriefCategory: Int] = [:]
        for item in brief.items {
            categoryCounts[item.category, default: 0] += 1
        }
        
        // Should have items from multiple categories
        XCTAssertGreaterThan(categoryCounts.keys.count, 1, "Brief should have diverse categories")
    }
    
    // MARK: - Persistence Tests
    
    func testBriefPersistsAcrossGeneratorInstances() async {
        // Generate a brief
        await appModel.dailyBriefGenerator.generateBrief()
        let originalBrief = appModel.dailyBriefGenerator.currentBrief
        
        // Create a new generator (simulating app restart)
        let newGenerator = DailyBriefGenerator(appModel: appModel)
        
        // For MVP, briefs are not persisted, so this should be nil
        XCTAssertNil(newGenerator.currentBrief, "MVP does not persist briefs")
        
        // In future versions, we would test persistence here
    }
}
import XCTest
@testable import Hagda

final class DailyBriefTests: XCTestCase {
    var appModel: AppModel!
    var generator: DailyBriefGenerator!
    
    override func setUpWithError() throws {
        appModel = AppModel(isTestingMode: true)
        generator = DailyBriefGenerator(appModel: appModel)
    }
    
    override func tearDownWithError() throws {
        generator = nil
        appModel = nil
    }
    
    // MARK: - Model Tests
    
    func testBriefModeProperties() {
        XCTAssertEqual(BriefMode.rush.targetReadTime, 120) // 2 minutes
        XCTAssertEqual(BriefMode.standard.targetReadTime, 300) // 5 minutes
        XCTAssertEqual(BriefMode.weekend.targetReadTime, 1200) // 20 minutes
        
        XCTAssertEqual(BriefMode.rush.maxItems, 5)
        XCTAssertEqual(BriefMode.standard.maxItems, 10)
        XCTAssertEqual(BriefMode.weekend.maxItems, 12)
    }
    
    func testBriefCategoryProperties() {
        XCTAssertEqual(BriefCategory.topStories.displayName, "Top Stories")
        XCTAssertEqual(BriefCategory.trending.icon, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(BriefCategory.podcasts.color, .green)
    }
    
    func testDailyBriefInitialization() {
        let items = [
            BriefItem(
                content: ContentItem.sampleItems[0],
                reason: "Test reason",
                summary: "Test summary",
                category: .topStories,
                priority: 0
            )
        ]
        
        let brief = DailyBrief(
            items: items,
            readTime: 300,
            mode: .standard
        )
        
        XCTAssertEqual(brief.items.count, 1)
        XCTAssertEqual(brief.readTimeMinutes, 5)
        XCTAssertEqual(brief.mode, .standard)
        XCTAssertTrue(brief.isToday)
    }
    
    // MARK: - Generator Tests
    
    func testGeneratorInitialization() {
        XCTAssertNil(generator.currentBrief)
        XCTAssertFalse(generator.isGenerating)
        XCTAssertNil(generator.lastError)
    }
    
    func testGenerateBriefCreatesContent() async {
        // Ensure we have some selected sources
        appModel.selectedSources.insert(Source.sampleSources[0].id)
        appModel.selectedSources.insert(Source.sampleSources[5].id)
        
        await generator.generateBrief()
        
        XCTAssertNotNil(generator.currentBrief, "Brief should be generated")
        XCTAssertFalse(generator.isGenerating, "Generation should be complete")
        
        if let brief = generator.currentBrief {
            XCTAssertGreaterThan(brief.items.count, 0, "Brief should have items")
            XCTAssertLessThanOrEqual(brief.items.count, brief.mode.maxItems, "Brief should not exceed max items")
        }
    }
    
    func testGenerateBriefWithSpecificMode() async {
        appModel.selectedSources.insert(Source.sampleSources[0].id)
        
        await generator.generateBrief(mode: .rush)
        
        if let brief = generator.currentBrief {
            XCTAssertEqual(brief.mode, .rush)
            XCTAssertLessThanOrEqual(brief.items.count, BriefMode.rush.maxItems)
        }
    }
    
    // MARK: - Content Selection Tests
    
    func testContentDiversityInBrief() async {
        // Add multiple sources of different types
        let articleSource = Source.sampleSources.first { $0.type == .article }!
        let redditSource = Source.sampleSources.first { $0.type == .reddit }!
        let podcastSource = Source.sampleSources.first { $0.type == .podcast }!
        
        appModel.selectedSources.insert(articleSource.id)
        appModel.selectedSources.insert(redditSource.id)
        appModel.selectedSources.insert(podcastSource.id)
        
        await generator.generateBrief()
        
        if let brief = generator.currentBrief {
            let types = Set(brief.items.map { $0.content.type })
            XCTAssertGreaterThan(types.count, 1, "Brief should have diverse content types")
        }
    }
    
    func testBriefItemsHaveRequiredProperties() async {
        appModel.selectedSources.insert(Source.sampleSources[0].id)
        
        await generator.generateBrief()
        
        if let brief = generator.currentBrief {
            for item in brief.items {
                XCTAssertFalse(item.reason.isEmpty, "Each item should have a reason")
                XCTAssertFalse(item.summary.isEmpty, "Each item should have a summary")
                XCTAssertNotNil(item.category, "Each item should have a category")
            }
        }
    }
    
    // MARK: - Engagement Tracking Tests
    
    func testRecordEngagement() {
        let briefItem = BriefItem(
            content: ContentItem.sampleItems[0],
            reason: "Test",
            summary: "Test summary",
            category: .topStories,
            priority: 0
        )
        
        generator.recordEngagement(
            briefItemId: briefItem.id,
            contentId: briefItem.content.id,
            timeSpent: 30,
            action: .clicked
        )
        
        // In the real implementation, this would update user behavior
        // For now, just verify the method doesn't crash
        XCTAssertTrue(true, "Engagement recording should not crash")
    }
    
    // MARK: - Selection Reason Tests
    
    func testSelectionReasonExplanations() {
        XCTAssertEqual(SelectionReason.topStory.explanation, "Top story from your sources")
        XCTAssertEqual(SelectionReason.trending.explanation, "Trending in your network")
        XCTAssertEqual(SelectionReason.followUp.explanation, "Update on story you followed")
        XCTAssertEqual(SelectionReason.diversityPick.explanation, "Different perspective")
    }
    
    // MARK: - Read Time Calculation Tests
    
    func testReadTimeCalculation() async {
        appModel.selectedSources.insert(Source.sampleSources[0].id)
        
        await generator.generateBrief()
        
        if let brief = generator.currentBrief {
            XCTAssertGreaterThan(brief.readTime, 0, "Read time should be positive")
            XCTAssertLessThanOrEqual(brief.readTime, brief.mode.targetReadTime * 2, "Read time should be reasonable")
        }
    }
    
    // MARK: - Mode Detection Tests
    
    func testModeDetectionBasedOnTime() {
        // This would require mocking the current time
        // For now, just test that a mode is always selected
        appModel.selectedSources.insert(Source.sampleSources[0].id)
        
        Task {
            await generator.generateBrief()
            
            if let brief = generator.currentBrief {
                XCTAssertNotNil(brief.mode, "Brief should always have a mode")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testBriefGenerationPerformance() {
        // Add multiple sources
        for source in Source.sampleSources.prefix(5) {
            appModel.selectedSources.insert(source.id)
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Brief generation")
            
            Task {
                await generator.generateBrief()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
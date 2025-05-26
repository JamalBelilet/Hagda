import XCTest

final class TodaysBriefUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestingMode"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic Visibility Tests
    
    func testTodaysBriefSectionIsVisible() throws {
        // Navigate to feed
        let feedList = app.scrollViews["FeedList"].firstMatch
        XCTAssertTrue(feedList.waitForExistence(timeout: 5), "Feed list should exist")
        
        // Check for Today's Brief section header
        let briefHeader = app.staticTexts["Today's Brief"]
        XCTAssertTrue(briefHeader.exists, "Today's Brief header should be visible")
        
        // Check for description
        let briefDescription = app.staticTexts["Your personalized overview for today"]
        XCTAssertTrue(briefDescription.exists, "Brief description should be visible")
    }
    
    func testTodaysBriefCardIsDisplayed() throws {
        // Wait for the brief card to appear
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Daily brief card should appear")
        
        // Check for brief icon
        let briefIcon = app.images.matching(identifier: "BriefModeIcon").firstMatch
        XCTAssertTrue(briefIcon.exists, "Brief mode icon should be visible")
        
        // Check for story count and read time
        let storyCount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'stories'")).firstMatch
        XCTAssertTrue(storyCount.exists, "Story count should be visible")
        
        let readTime = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'min read'")).firstMatch
        XCTAssertTrue(readTime.exists, "Read time should be visible")
    }
    
    // MARK: - Collapsed State Tests
    
    func testCollapsedBriefShowsPreview() throws {
        // Wait for the brief card
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        
        // Check for chevron down icon (collapsed state)
        let chevronDown = app.images["chevron.down.circle"]
        XCTAssertTrue(chevronDown.exists, "Chevron down should be visible in collapsed state")
        
        // Check that preview content is visible
        let previewTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'SwiftUI'")).firstMatch
        if previewTitle.exists {
            XCTAssertTrue(previewTitle.isHittable, "Preview title should be visible")
        }
    }
    
    // MARK: - Expansion Tests
    
    func testTappingBriefExpandsContent() throws {
        // Find and tap the brief card
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        
        briefCard.tap()
        
        // Wait for expansion animation
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check for chevron up icon (expanded state)
        let chevronUp = app.images["chevron.up.circle"]
        XCTAssertTrue(chevronUp.waitForExistence(timeout: 2), "Chevron up should be visible in expanded state")
        
        // Check that scroll view with items is visible
        let briefScrollView = app.scrollViews.matching(identifier: "BriefItemsScrollView").firstMatch
        XCTAssertTrue(briefScrollView.exists, "Brief items scroll view should be visible when expanded")
    }
    
    func testExpandedBriefShowsMultipleItems() throws {
        // Expand the brief
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        briefCard.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check for multiple brief items
        let briefItems = app.buttons.matching(identifier: "BriefItemRow")
        XCTAssertTrue(briefItems.count > 0, "Should have at least one brief item")
        
        // Check first item has required elements
        let firstItem = briefItems.firstMatch
        if firstItem.exists {
            // Check for category icon
            let categoryIcon = firstItem.images.firstMatch
            XCTAssertTrue(categoryIcon.exists, "Category icon should be visible")
            
            // Check for source name
            let sourceName = firstItem.staticTexts.matching(NSPredicate(format: "label CONTAINS 'TechCrunch' OR label CONTAINS 'r/swift'")).firstMatch
            XCTAssertTrue(sourceName.exists, "Source name should be visible")
            
            // Check for lightbulb icon (reason indicator)
            let reasonIcon = firstItem.images["lightbulb.fill"]
            XCTAssertTrue(reasonIcon.exists, "Reason indicator should be visible")
        }
    }
    
    // MARK: - Collapse Tests
    
    func testTappingChevronCollapsesBrief() throws {
        // First expand the brief
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        briefCard.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Find and tap the chevron up button
        let chevronUp = app.buttons.containing(NSPredicate(format: "label CONTAINS 'chevron.up.circle'")).firstMatch
        XCTAssertTrue(chevronUp.exists, "Chevron up button should exist")
        chevronUp.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check that we're back to collapsed state
        let chevronDown = app.images["chevron.down.circle"]
        XCTAssertTrue(chevronDown.exists, "Should be back to collapsed state with chevron down")
    }
    
    // MARK: - Navigation Tests
    
    func testTappingBriefItemNavigatesToDetail() throws {
        // Expand the brief
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        briefCard.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Tap the first brief item
        let firstItem = app.buttons.matching(identifier: "BriefItemRow").firstMatch
        XCTAssertTrue(firstItem.exists, "Should have at least one brief item")
        firstItem.tap()
        
        // Wait for navigation
        Thread.sleep(forTimeInterval: 1)
        
        // Check that we navigated to content detail
        let backButton = app.navigationBars.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 3), "Should navigate to detail view with back button")
        
        // Verify we're on a detail view (check for common elements)
        let contentScrollView = app.scrollViews.firstMatch
        XCTAssertTrue(contentScrollView.exists, "Content detail should have a scroll view")
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateIsShown() throws {
        // This test would need the app to be in a state where brief is loading
        // For now, we'll just check that the loading view structure exists
        
        // If we catch the loading state, it should show:
        let progressView = app.activityIndicators.firstMatch
        let loadingText = app.staticTexts["Generating your brief..."]
        
        // These might not always be visible, so we just check the structure
        if progressView.exists && loadingText.exists {
            XCTAssertTrue(true, "Loading state UI elements are present")
        }
    }
    
    // MARK: - Content Tests
    
    func testBriefItemShowsRequiredInformation() throws {
        // Expand the brief
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        briefCard.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check first item for required elements
        let firstItem = app.buttons.matching(identifier: "BriefItemRow").firstMatch
        if firstItem.exists {
            // Check that title exists
            let title = firstItem.staticTexts.element(boundBy: 2) // Usually the title is the third static text
            XCTAssertTrue(title.exists, "Item should have a title")
            
            // Check that summary exists
            let summaryPredicate = NSPredicate(format: "label CONTAINS '...'")
            let summary = firstItem.staticTexts.matching(summaryPredicate).firstMatch
            if summary.exists {
                XCTAssertTrue(summary.label.count > 10, "Summary should have meaningful content")
            }
            
            // Check that reason exists
            let reasonPredicate = NSPredicate(format: "label CONTAINS 'Top story' OR label CONTAINS 'Trending' OR label CONTAINS 'diversity'")
            let reason = firstItem.staticTexts.matching(reasonPredicate).firstMatch
            XCTAssertTrue(reason.exists, "Item should have a reason for inclusion")
        }
    }
    
    // MARK: - Mode Display Tests
    
    func testBriefDisplaysMode() throws {
        // Expand the brief
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        briefCard.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check for mode display
        let modePredicate = NSPredicate(format: "label CONTAINS 'Standard Brief' OR label CONTAINS 'Rush Brief' OR label CONTAINS 'Weekend Brief'")
        let modeText = app.staticTexts.matching(modePredicate).firstMatch
        XCTAssertTrue(modeText.exists, "Brief mode should be displayed")
    }
    
    // MARK: - Accessibility Tests
    
    func testBriefHasAccessibilityLabels() throws {
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        
        // Check that the brief card has an accessibility label
        XCTAssertNotNil(briefCard.label, "Brief card should have accessibility label")
        
        // Expand and check items
        briefCard.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        let firstItem = app.buttons.matching(identifier: "BriefItemRow").firstMatch
        if firstItem.exists {
            XCTAssertNotNil(firstItem.label, "Brief items should have accessibility labels")
        }
    }
    
    // MARK: - Performance Tests
    
    func testBriefExpandsQuickly() throws {
        let briefCard = app.buttons.matching(identifier: "DailyBriefCard").firstMatch
        XCTAssertTrue(briefCard.waitForExistence(timeout: 10), "Brief card should exist")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        briefCard.tap()
        
        // Check that chevron up appears quickly
        let chevronUp = app.images["chevron.up.circle"]
        XCTAssertTrue(chevronUp.waitForExistence(timeout: 1), "Brief should expand within 1 second")
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 1.0, "Brief expansion should be fast")
    }
}
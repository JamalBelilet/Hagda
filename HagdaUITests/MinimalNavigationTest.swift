import XCTest

final class MinimalNavigationTest: XCTestCase {
    @MainActor
    func testMinimalNavigation() throws {
        // Absolute minimal navigation test
        let app = XCUIApplication()
        app.launch()
        
        // 1. Verify we're on the feed screen
        XCTAssertTrue(app.navigationBars["Taila"].exists)
        
        // 2. Navigate to library
        app.navigationBars["Taila"].buttons.element(boundBy: 0).tap()
        sleep(1)
        
        // 3. Verify we can see library content
        XCTAssertTrue(app.staticTexts["Top Tech Articles"].exists)
        
        // 4. Navigate back to feed
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        
        // 5. Verify we're back on feed
        XCTAssertTrue(app.navigationBars["Taila"].exists)
    }
}
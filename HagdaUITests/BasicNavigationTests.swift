import XCTest

final class BasicNavigationTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testBasicNavigation() throws {
        // Ultra-simplified test that just checks basic navigation between screens
        let app = XCUIApplication()
        app.launch()
        
        // Verify we're on the feed screen
        XCTAssertTrue(app.navigationBars["Taila"].exists)
        
        // Navigate to library using direct button access
        app.navigationBars["Taila"].buttons.element(boundBy: 0).tap()
        sleep(1)
        
        // Verify we see basic library content - direct string matching
        XCTAssertTrue(app.staticTexts["Top Tech Articles"].exists)
        
        // Navigate back to feed - direct button access
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        
        // Verify we're back on feed
        XCTAssertTrue(app.navigationBars["Taila"].exists)
    }
}
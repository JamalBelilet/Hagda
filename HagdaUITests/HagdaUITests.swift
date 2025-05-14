//
//  HagdaUITests.swift
//  HagdaUITests
//
//  Created by Djamaleddine Belilet on 13/05/2025.
//

import XCTest

final class HagdaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testNavigationToLibrary() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify we're on the feed screen
        XCTAssertTrue(app.navigationBars["Taila"].exists)
        
        // Navigate to library
        app.navigationBars["Taila"].buttons.element(boundBy: 0).tap()
        sleep(1)
        
        // Verify we see library elements
        XCTAssertTrue(app.staticTexts["Top Tech Articles"].exists)
        XCTAssertTrue(app.staticTexts["Popular Subreddits"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

import XCTest
@testable import Hagda

/// Tests for the Bluesky API integration
final class BlueSkyAPITests: XCTestCase {
    
    // Test instance of the BlueSkyAPIService
    var blueSkyAPIService: BlueSkyAPIService!
    
    // Mock URLSession for testing API calls without network
    var mockURLSession: SharedMockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = SharedMockURLSession()
        blueSkyAPIService = BlueSkyAPIService(session: mockURLSession)
    }
    
    override func tearDown() {
        mockURLSession = nil
        blueSkyAPIService = nil
        super.tearDown()
    }
    
    /// Test that the API correctly parses a valid Bluesky account search response
    func testBlueSkyAccountSearchParsingAsync() async throws {
        // Set up mock response data
        let jsonString = """
        {
            "actors": [
                {
                    "did": "did:plc:1234567890abcdef",
                    "handle": "alice.bsky.social",
                    "displayName": "Alice",
                    "description": "Tech writer and software developer",
                    "avatar": "https://example.com/avatar1.jpg",
                    "followersCount": 5243,
                    "followsCount": 983,
                    "postsCount": 1205
                },
                {
                    "did": "did:plc:abcdef1234567890",
                    "handle": "bob.bsky.social",
                    "displayName": "Bob",
                    "description": "Open source enthusiast and tech blogger",
                    "avatar": "https://example.com/avatar2.jpg",
                    "followersCount": 2341,
                    "followsCount": 512,
                    "postsCount": 845
                }
            ]
        }
        """
        
        // Convert to data and set up mock response
        let mockData = jsonString.data(using: .utf8)!
        mockURLSession.mockData = mockData
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://bsky.social")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Call the function and get the result
        let sources = try await blueSkyAPIService.searchAccounts(query: "test")
        
        // Verify the sources were parsed correctly
        XCTAssertEqual(sources.count, 2, "Should parse 2 Bluesky accounts from the mock response")
        
        // Verify first source details
        XCTAssertEqual(sources[0].name, "Alice", "First source name should be Alice")
        XCTAssertEqual(sources[0].type, .bluesky, "Source type should be bluesky")
        XCTAssertEqual(sources[0].handle, "alice.bsky.social", "Handle should be alice.bsky.social")
        XCTAssertTrue(sources[0].description.contains("Tech writer"), "Description should include original content")
        XCTAssertTrue(sources[0].description.contains("5,243"), "Description should include formatted follower count")
        XCTAssertEqual(sources[0].artworkUrl, "https://example.com/avatar1.jpg", "Should use avatar as artwork URL")
        XCTAssertEqual(sources[0].feedUrl, "https://bsky.app/profile/alice.bsky.social", "FeedUrl should be the profile URL")
        
        // Verify second source details
        XCTAssertEqual(sources[1].name, "Bob", "Second source name should be Bob")
        XCTAssertEqual(sources[1].handle, "bob.bsky.social", "Handle should be bob.bsky.social")
        XCTAssertTrue(sources[1].description.contains("Open source"), "Description should include original content")
        XCTAssertTrue(sources[1].description.contains("2,341"), "Description should include formatted follower count")
        XCTAssertEqual(sources[1].artworkUrl, "https://example.com/avatar2.jpg", "Should use avatar as artwork URL")
    }
    
    /// Test the search accounts functionality with completion handler API
    func testBlueSkyAccountSearchWithCompletionHandler() {
        // Set up mock response data
        let jsonString = """
        {
            "actors": [
                {
                    "did": "did:plc:1234567890abcdef",
                    "handle": "alice.bsky.social",
                    "displayName": "Alice",
                    "description": "Tech writer and software developer",
                    "avatar": "https://example.com/avatar1.jpg",
                    "followersCount": 5243,
                    "followsCount": 983,
                    "postsCount": 1205
                }
            ]
        }
        """
        
        // Convert to data and set up mock response
        let mockData = jsonString.data(using: .utf8)!
        mockURLSession.mockData = mockData
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://bsky.social")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Create expectation for async test
        let expectation = XCTestExpectation(description: "Search accounts completion")
        
        // Call the function with completion handler
        blueSkyAPIService.searchAccounts(query: "test") { result in
            switch result {
            case .success(let sources):
                // Verify results
                XCTAssertEqual(sources.count, 1, "Should parse 1 Bluesky account")
                XCTAssertEqual(sources[0].name, "Alice", "Source name should be Alice")
                XCTAssertEqual(sources[0].type, .bluesky, "Source type should be bluesky")
                XCTAssertEqual(sources[0].handle, "alice.bsky.social", "Handle should match")
                XCTAssertTrue(sources[0].description.contains("Tech writer"), "Description should include original content")
            case .failure(let error):
                XCTFail("Search should succeed, but got error: \(error)")
            }
            expectation.fulfill()
        }
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that the API correctly handles errors with completion handler
    func testBlueSkyAccountSearchError() {
        // Set up mock error response
        mockURLSession.mockError = NSError(domain: "test.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // Create expectation for async test
        let expectation = XCTestExpectation(description: "Search error completion")
        
        // Call the function with completion handler
        blueSkyAPIService.searchAccounts(query: "test") { result in
            switch result {
            case .success:
                XCTFail("Function should fail when network error occurs")
            case .failure(let error):
                // Success - function returned an error as expected
                XCTAssertNotNil(error, "Should receive a network error")
                XCTAssertEqual((error as NSError).domain, "test.error", "Error domain should match")
            }
            expectation.fulfill()
        }
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
    }
}


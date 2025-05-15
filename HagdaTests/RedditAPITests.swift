import XCTest
@testable import Hagda

/// Tests for the Reddit API integration
final class RedditAPITests: XCTestCase {
    
    // Test instance of the RedditAPIService
    var redditAPIService: RedditAPIService!
    
    // Mock URLSession for testing API calls without network
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = MockURLSession()
        redditAPIService = RedditAPIService(session: mockURLSession)
    }
    
    override func tearDown() {
        mockURLSession = nil
        redditAPIService = nil
        super.tearDown()
    }
    
    /// Test that the API correctly parses a valid subreddit search response
    func testSubredditSearchParsing() async throws {
        // Set up mock response data
        let jsonString = """
        {
            "kind": "Listing",
            "data": {
                "after": "t5_2qh1i",
                "dist": 2,
                "children": [
                    {
                        "kind": "t5",
                        "data": {
                            "id": "2qh1i",
                            "display_name": "AskReddit",
                            "title": "Ask Reddit...",
                            "display_name_prefixed": "r/AskReddit",
                            "url": "/r/AskReddit/",
                            "description": "Ask a question",
                            "public_description": "r/AskReddit is the place to ask and answer thought-provoking questions.",
                            "subscribers": 42000000,
                            "created_utc": 1201233135.0,
                            "icon_img": "https://example.com/icon.png"
                        }
                    },
                    {
                        "kind": "t5",
                        "data": {
                            "id": "2qh3s",
                            "display_name": "todayilearned",
                            "title": "Today I Learned (TIL)",
                            "display_name_prefixed": "r/todayilearned",
                            "url": "/r/todayilearned/",
                            "description": "Learn something",
                            "public_description": "You learn something new every day.",
                            "subscribers": 30000000,
                            "created_utc": 1201243135.0,
                            "community_icon": "https://example.com/community.png"
                        }
                    }
                ],
                "before": null
            }
        }
        """
        
        // Convert to data and set up mock response
        let mockData = jsonString.data(using: .utf8)!
        mockURLSession.mockData = mockData
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://www.reddit.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Call the function and get the result
        let sources = try await redditAPIService.searchSubreddits(query: "test")
        
        // Verify the sources were parsed correctly
        XCTAssertEqual(sources.count, 2, "Should parse 2 subreddits from the mock response")
        
        // Verify first source details
        XCTAssertEqual(sources[0].name, "AskReddit", "First source name should be AskReddit")
        XCTAssertEqual(sources[0].type, .reddit, "Source type should be reddit")
        XCTAssertEqual(sources[0].handle, "r/AskReddit", "Handle should be r/AskReddit")
        XCTAssertTrue(sources[0].description.contains("thought-provoking"), "Description should include public_description content")
        XCTAssertTrue(sources[0].description.contains("42"), "Description should include formatted subscriber count")
        XCTAssertEqual(sources[0].artworkUrl, "https://example.com/icon.png", "Should use icon_img as artwork URL")
        
        // Verify second source details
        XCTAssertEqual(sources[1].name, "todayilearned", "Second source name should be todayilearned")
        XCTAssertEqual(sources[1].handle, "r/todayilearned", "Handle should be r/todayilearned")
        XCTAssertTrue(sources[1].description.contains("learn"), "Description should include public_description content")
        XCTAssertTrue(sources[1].description.contains("30"), "Description should include formatted subscriber count")
        XCTAssertEqual(sources[1].artworkUrl, "https://example.com/community.png", "Should use community_icon as artwork URL")
    }
    
    /// Test that the API correctly handles errors
    func testSubredditSearchError() async {
        // Set up mock error response
        mockURLSession.mockError = NSError(domain: "test.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // Call the function and verify it throws an error
        do {
            _ = try await redditAPIService.searchSubreddits(query: "test")
            XCTFail("Function should throw an error when network fails")
        } catch {
            // Success - function threw an error as expected
            XCTAssertNotNil(error, "Should receive a network error")
        }
    }
}

/// A mock URLSession for testing API calls without network
class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if let mockError = mockError {
            throw mockError
        }
        guard let mockData = mockData, let mockResponse = mockResponse else {
            throw URLError(.unknown)
        }
        return (mockData, mockResponse)
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let mockDataTask = MockURLSessionDataTask()
        mockDataTask.completionHandler = {
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
        return mockDataTask
    }
}

/// A mock URLSessionDataTask for testing
class MockURLSessionDataTask: URLSessionDataTask {
    var completionHandler: (() -> Void)?
    
    override func resume() {
        completionHandler?()
    }
}
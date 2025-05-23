import XCTest
@testable import Hagda

/// Tests for the Reddit API service and post details functionality
class RedditPostTests: XCTestCase {
    
    /// Tests fetching posts from the Reddit API
    func testFetchRedditPosts() async throws {
        // Create mock data
        let mockSession = SharedMockURLSession()
        
        // Sample API response data for subreddit posts
        let mockPostsResponse = """
        {
            "kind": "Listing",
            "data": {
                "after": "t3_abc123",
                "dist": 25,
                "children": [
                    {
                        "kind": "t3",
                        "data": {
                            "id": "12345",
                            "title": "This is a test Reddit post",
                            "author": "testuser",
                            "selftext": "This is the content of the test post with details about a project.",
                            "created_utc": \(Date().timeIntervalSince1970),
                            "num_comments": 42,
                            "subreddit": "programming",
                            "subreddit_name_prefixed": "r/programming",
                            "ups": 100,
                            "downs": 10,
                            "url": "https://www.reddit.com/r/programming/comments/12345/",
                            "permalink": "/r/programming/comments/12345/this_is_a_test_reddit_post/"
                        }
                    }
                ],
                "before": null
            }
        }
        """
        
        mockSession.mockData = mockPostsResponse.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.mockError = nil
        
        // Create the API service with the mock session
        let service = RedditAPIService(session: mockSession)
        
        // Call the fetchSubredditContent method
        let posts = try await service.fetchSubredditContent(subredditName: "r/programming")
        
        // Verify the result
        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts[0].title, "This is a test Reddit post")
        XCTAssertEqual(posts[0].type, .reddit)
        XCTAssertTrue(posts[0].subtitle.contains("u/testuser"))
        XCTAssertTrue(posts[0].subtitle.contains("42 comments"))
    }
    
    /// Tests the RedditDetailViewModel initialization from a ContentItem
    func testRedditDetailViewModel() {
        // Create a content item
        let contentItem = ContentItem(
            title: "This is a test Reddit post",
            subtitle: "Posted by u/testuser • r/programming • 42 comments",
            date: Date(),
            type: .reddit,
            contentPreview: "This is the content of the test post with details about a project."
        )
        
        // Create the view model
        let viewModel = RedditDetailViewModel(item: contentItem)
        
        // Verify the view model
        XCTAssertEqual(viewModel.postTitle, "This is a test Reddit post")
        XCTAssertEqual(viewModel.authorName, "testuser")
        XCTAssertEqual(viewModel.subredditName, "r/programming")
        XCTAssertEqual(viewModel.commentCount, 42)
        XCTAssertEqual(viewModel.postContent, "This is the content of the test post with details about a project.")
        
        // The view model would try to load real data, which we can't test directly
        // So we'll just verify the initialization worked
        XCTAssertFalse(viewModel.isLoading) // Should start loading after initialization
        XCTAssertNil(viewModel.error) // Should not have an error initially
    }
    
    /// Tests the parsing of subtitle information
    func testSubtitleParsing() {
        // Create content items with different subtitle formats
        let contentItem1 = ContentItem(
            title: "Test Post 1",
            subtitle: "Posted by u/testuser • r/programming • 42 comments",
            date: Date(),
            type: .reddit
        )
        
        let contentItem2 = ContentItem(
            title: "Test Post 2",
            subtitle: "Posted by u/another_user • 15 comments",
            date: Date(),
            type: .reddit
        )
        
        // Create view models
        let viewModel1 = RedditDetailViewModel(item: contentItem1)
        let viewModel2 = RedditDetailViewModel(item: contentItem2)
        
        // Verify the parsing
        XCTAssertEqual(viewModel1.authorName, "testuser")
        XCTAssertEqual(viewModel1.subredditName, "r/programming")
        XCTAssertEqual(viewModel1.commentCount, 42)
        
        XCTAssertEqual(viewModel2.authorName, "another_user")
        // Default subreddit name since not in subtitle
        XCTAssertEqual(viewModel2.subredditName, "r/subreddit") 
        XCTAssertEqual(viewModel2.commentCount, 15)
    }
}
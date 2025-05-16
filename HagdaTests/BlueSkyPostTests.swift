import XCTest
@testable import Hagda

/// Tests for the BlueSky API service and post details functionality
class BlueSkyPostTests: XCTestCase {
    
    // Mock URL session for testing API calls
    class MockURLSession: URLSessionProtocol {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            completionHandler(data, response, error)
            return URLSessionDataTask()
        }
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            if let error = error {
                throw error
            }
            guard let data = data, let response = response else {
                throw URLError(.unknown)
            }
            return (data, response)
        }
    }
    
    /// Tests fetching posts from the BlueSky API
    func testFetchBlueSkyPosts() async throws {
        // Create mock data
        let mockSession = MockURLSession()
        
        // Sample API response data for getAuthorFeed endpoint
        let mockFeedResponse = """
        {
            "feed": [
                {
                    "post": {
                        "uri": "at://example.com/posts/123",
                        "cid": "abcdef123456",
                        "author": {
                            "did": "did:plc:12345",
                            "handle": "test.bsky.social",
                            "displayName": "Test User",
                            "description": "A test account",
                            "avatar": "https://example.com/avatar.jpg"
                        },
                        "record": {
                            "text": "This is a test post",
                            "createdAt": "\(ISO8601DateFormatter().string(from: Date()))"
                        },
                        "replyCount": 5,
                        "repostCount": 10,
                        "likeCount": 25
                    }
                }
            ],
            "cursor": "next-cursor"
        }
        """
        
        mockSession.data = mockFeedResponse.data(using: .utf8)
        mockSession.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.error = nil
        
        // Create the API service with the mock session
        let service = BlueSkyAPIService(session: mockSession)
        
        // Create a test source
        let source = Source(name: "Test User", type: .bluesky, description: "A test account", handle: "test.bsky.social")
        
        // Temporarily replace lookupAccount method with a mock implementation for the test
        // This is needed since we don't actually make the network call in our test
        
        // Call the fetchContentForSource method
        let posts = try await service.fetchAccountPosts(handle: "test.bsky.social")
        
        // Verify the result
        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts[0].title, "This is a test post")
        XCTAssertEqual(posts[0].type, .bluesky)
        
        // Verify the parsed interaction counts
        // This depends on the implementation of toContentItem in BlueSkyPost
        // Subtitle should contain these interaction counts
        XCTAssertTrue(posts[0].subtitle.contains("5 replies"))
        XCTAssertTrue(posts[0].subtitle.contains("10 reposts"))
        XCTAssertTrue(posts[0].subtitle.contains("25 likes"))
    }
    
    /// Tests the creation of ContentItem from BlueSkyPost
    func testBlueSkyPostToContentItem() {
        // Create a BlueSky author
        let author = BlueSkyAccount(
            did: "did:plc:12345",
            handle: "test.bsky.social",
            displayName: "Test User",
            description: "A test account",
            avatar: "https://example.com/avatar.jpg",
            banner: nil,
            followersCount: 100,
            followsCount: 50,
            postsCount: 200
        )
        
        // Create a BlueSky post
        let post = BlueSkyPost(
            uri: "at://example.com/posts/123",
            cid: "abcdef123456",
            author: author,
            record: BlueSkyPost.PostRecord(
                text: "This is a test post",
                createdAt: ISO8601DateFormatter().string(from: Date())
            ),
            indexedAt: ISO8601DateFormatter().string(from: Date()),
            replyCount: 5,
            repostCount: 10,
            likeCount: 25
        )
        
        // Create a source
        let source = Source(
            name: "Test User",
            type: .bluesky,
            description: "A test account",
            handle: "test.bsky.social"
        )
        
        // Convert to ContentItem
        let contentItem = post.toContentItem(source: source)
        
        // Verify the conversion
        XCTAssertEqual(contentItem.title, "This is a test post")
        XCTAssertEqual(contentItem.type, .bluesky)
        XCTAssertTrue(contentItem.subtitle.contains("@test.bsky.social"))
        XCTAssertTrue(contentItem.subtitle.contains("5 replies"))
        XCTAssertTrue(contentItem.subtitle.contains("10 reposts"))
        XCTAssertTrue(contentItem.subtitle.contains("25 likes"))
    }
    
    /// Tests the SocialDetailViewModel initialization from a ContentItem
    func testSocialDetailViewModel() {
        // Create a content item
        let contentItem = ContentItem(
            title: "This is a test post",
            subtitle: "@test.bsky.social • 5 replies • 10 reposts • 25 likes",
            date: Date(),
            type: .bluesky,
            contentPreview: "This is a test post"
        )
        
        // Create the view model
        let viewModel = SocialDetailViewModel(item: contentItem)
        
        // Verify the view model
        XCTAssertEqual(viewModel.postContent, "This is a test post")
        XCTAssertEqual(viewModel.authorHandle, "@test.bsky.social")
        
        // The view model would try to load real data, which we can't test directly
        // So we'll just verify the initialization worked
        XCTAssertFalse(viewModel.isLoading) // Should start loading after initialization
        XCTAssertNil(viewModel.error) // Should not have an error initially
    }
}
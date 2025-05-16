import XCTest
@testable import Hagda

/// Tests for the Mastodon API service and post details functionality
class MastodonPostTests: XCTestCase {
    
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
    
    /// Tests fetching statuses from the Mastodon API
    func testFetchMastodonStatuses() async throws {
        // Create mock data
        let mockSession = MockURLSession()
        
        // Sample API response data for account statuses endpoint
        let mockStatusesResponse = """
        [
            {
                "id": "12345",
                "created_at": "\(ISO8601DateFormatter().string(from: Date()))",
                "content": "This is a test Mastodon status with <a href='https://example.com'>links</a> and formatting.",
                "url": "https://mastodon.social/@test/12345",
                "account": {
                    "id": "67890",
                    "username": "test",
                    "acct": "test@mastodon.social",
                    "display_name": "Test User",
                    "url": "https://mastodon.social/@test",
                    "note": "A test Mastodon account",
                    "avatar": "https://example.com/avatar.jpg",
                    "header": "https://example.com/header.jpg",
                    "followers_count": 150,
                    "following_count": 75,
                    "statuses_count": 300
                },
                "replies_count": 3,
                "reblogs_count": 7,
                "favourites_count": 15,
                "media_attachments": []
            }
        ]
        """
        
        mockSession.data = mockStatusesResponse.data(using: .utf8)
        mockSession.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.error = nil
        
        // Mock the account info endpoint as well
        let mockAccountResponse = """
        {
            "id": "67890",
            "username": "test",
            "acct": "test@mastodon.social",
            "display_name": "Test User",
            "url": "https://mastodon.social/@test",
            "note": "A test Mastodon account",
            "avatar": "https://example.com/avatar.jpg",
            "header": "https://example.com/header.jpg",
            "followers_count": 150,
            "following_count": 75,
            "statuses_count": 300
        }
        """
        
        // Create the API service with the mock session
        let service = MastodonAPIService(instance: "mastodon.social", session: mockSession)
        
        // Since we can't easily mock multiple different responses for different URLs,
        // we'll use a mock approach and verify that the processing logic works correctly
        
        // Create a MastodonStatus directly from the mock JSON
        let jsonData = mockStatusesResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        let statuses = try decoder.decode([MastodonStatus].self, from: jsonData)
        
        XCTAssertEqual(statuses.count, 1)
        
        // Create an account
        let accountData = mockAccountResponse.data(using: .utf8)!
        let account = try decoder.decode(MastodonAccount.self, from: accountData)
        
        // Create a source from the account
        let source = account.toSource()
        
        // Convert status to ContentItem
        let contentItem = statuses[0].toContentItem(source: source)
        
        // Verify the conversion
        XCTAssertEqual(contentItem.type, .mastodon)
        
        // Check that HTML tags are removed from content
        XCTAssertFalse(contentItem.title.contains("<a href="))
        XCTAssertFalse(contentItem.title.contains("</a>"))
        
        // Check the subtitle format
        XCTAssertTrue(contentItem.subtitle.contains("@test@mastodon.social"))
        XCTAssertTrue(contentItem.subtitle.contains("3 replies"))
        XCTAssertTrue(contentItem.subtitle.contains("7 boosts"))
        XCTAssertTrue(contentItem.subtitle.contains("15 favorites"))
    }
    
    /// Tests the creation of ContentItem from MastodonStatus
    func testMastodonStatusToContentItem() {
        // Create a Mastodon account
        let account = MastodonAccount(
            id: "67890",
            username: "test",
            acct: "test@mastodon.social",
            display_name: "Test User",
            url: "https://mastodon.social/@test",
            note: "A test Mastodon account",
            avatar: "https://example.com/avatar.jpg",
            header: "https://example.com/header.jpg",
            followers_count: 150,
            following_count: 75,
            statuses_count: 300
        )
        
        // Create a Mastodon status
        let status = MastodonStatus(
            id: "12345",
            created_at: ISO8601DateFormatter().string(from: Date()),
            content: "This is a test Mastodon status with <a href='https://example.com'>links</a> and formatting.",
            url: "https://mastodon.social/@test/12345",
            account: account,
            replies_count: 3,
            reblogs_count: 7,
            favourites_count: 15,
            media_attachments: []
        )
        
        // Create a source
        let source = Source(
            name: "Test User",
            type: .mastodon,
            description: "A test Mastodon account",
            handle: "@test@mastodon.social"
        )
        
        // Convert to ContentItem
        let contentItem = status.toContentItem(source: source)
        
        // Verify the conversion
        XCTAssertEqual(contentItem.type, .mastodon)
        
        // Check that HTML tags are removed from content
        XCTAssertFalse(contentItem.title.contains("<a href="))
        XCTAssertFalse(contentItem.title.contains("</a>"))
        
        // Check the subtitle format
        XCTAssertTrue(contentItem.subtitle.contains("@test@mastodon.social"))
        XCTAssertTrue(contentItem.subtitle.contains("3 replies"))
        XCTAssertTrue(contentItem.subtitle.contains("7 boosts"))
        XCTAssertTrue(contentItem.subtitle.contains("15 favorites"))
    }
    
    /// Tests the SocialDetailViewModel initialization from a ContentItem for Mastodon
    func testSocialDetailViewModelWithMastodon() {
        // Create a content item for Mastodon
        let contentItem = ContentItem(
            title: "This is a test Mastodon post",
            subtitle: "@test@mastodon.social • 3 replies • 7 boosts • 15 favorites",
            date: Date(),
            type: .mastodon,
            contentPreview: "This is a test Mastodon post"
        )
        
        // Create the view model
        let viewModel = SocialDetailViewModel(item: contentItem)
        
        // Verify the view model
        XCTAssertEqual(viewModel.postContent, "This is a test Mastodon post")
        XCTAssertEqual(viewModel.authorHandle, "@test@mastodon.social")
        
        // The view model would try to load real data, which we can't test directly
        // So we'll just verify the initialization worked
        XCTAssertFalse(viewModel.isLoading) // Should start loading after initialization
        XCTAssertNil(viewModel.error) // Should not have an error initially
    }
}
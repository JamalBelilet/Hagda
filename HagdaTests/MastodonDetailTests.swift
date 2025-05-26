import Testing
import Foundation
@testable import Hagda

/// Tests for Mastodon detail functionality
struct MastodonDetailTests {
    
    // MARK: - Content Item Tests
    
    @Test("Mastodon status converts to ContentItem with metadata")
    func testMastodonStatusToContentItem() async throws {
        // Arrange
        let account = MastodonAccount(
            id: "123",
            username: "testuser",
            acct: "testuser@mastodon.social",
            display_name: "Test User",
            url: "https://mastodon.social/@testuser",
            note: "Test bio",
            avatar: "https://example.com/avatar.jpg",
            header: nil,
            followers_count: 100,
            following_count: 50,
            statuses_count: 200
        )
        
        let status = MastodonStatus(
            id: "456",
            created_at: "2024-01-15T10:30:00.000Z",
            content: "<p>This is a test Mastodon post with <a href='#'>links</a></p>",
            url: "https://mastodon.social/@testuser/456",
            account: account,
            replies_count: 5,
            reblogs_count: 10,
            favourites_count: 20,
            media_attachments: [
                MastodonStatus.MediaAttachment(
                    id: "789",
                    type: "image",
                    url: "https://example.com/image.jpg",
                    preview_url: "https://example.com/preview.jpg",
                    description: "Test image"
                )
            ]
        )
        
        let source = Source(
            name: "Test User",
            type: .mastodon,
            description: "Test description",
            handle: "@testuser@mastodon.social"
        )
        
        // Act
        let contentItem = status.toContentItem(source: source)
        
        // Assert
        #expect(contentItem.type == .mastodon)
        #expect(contentItem.title == "This is a test Mastodon post with links")
        #expect(contentItem.subtitle == "@testuser@mastodon.social • 5 replies • 10 boosts • 20 favorites")
        
        // Check metadata
        #expect(contentItem.metadata["statusId"] as? String == "456")
        #expect(contentItem.metadata["statusUrl"] as? String == "https://mastodon.social/@testuser/456")
        #expect(contentItem.metadata["accountId"] as? String == "123")
        #expect(contentItem.metadata["accountUsername"] as? String == "testuser")
        #expect(contentItem.metadata["accountDisplayName"] as? String == "Test User")
        #expect(contentItem.metadata["accountHandle"] as? String == "testuser@mastodon.social")
        #expect(contentItem.metadata["repliesCount"] as? Int == 5)
        #expect(contentItem.metadata["reblogsCount"] as? Int == 10)
        #expect(contentItem.metadata["favouritesCount"] as? Int == 20)
        
        // Check media attachments
        let mediaAttachments = contentItem.metadata["mediaAttachments"] as? [[String: Any]]
        #expect(mediaAttachments?.count == 1)
        #expect(mediaAttachments?.first?["type"] as? String == "image")
        #expect(mediaAttachments?.first?["url"] as? String == "https://example.com/image.jpg")
    }
    
    // MARK: - API Integration Tests
    
    @Test("Fetch Mastodon thread context")
    func testFetchMastodonThreadContext() async throws {
        // Arrange
        let mockSession = SharedMockURLSession()
        let service = MastodonAPIService(session: mockSession)
        
        let contextData = """
        {
            "ancestors": [
                {
                    "id": "100",
                    "created_at": "2024-01-15T09:00:00.000Z",
                    "content": "<p>Original post</p>",
                    "url": "https://mastodon.social/@user/100",
                    "account": {
                        "id": "1",
                        "username": "originaluser",
                        "acct": "originaluser@mastodon.social",
                        "display_name": "Original User",
                        "url": "https://mastodon.social/@originaluser",
                        "followers_count": 50,
                        "following_count": 30,
                        "statuses_count": 100
                    }
                }
            ],
            "descendants": [
                {
                    "id": "200",
                    "created_at": "2024-01-15T11:00:00.000Z",
                    "content": "<p>Reply to the post</p>",
                    "url": "https://mastodon.social/@replier/200",
                    "account": {
                        "id": "2",
                        "username": "replier",
                        "acct": "replier@mastodon.social",
                        "display_name": "Reply User",
                        "url": "https://mastodon.social/@replier",
                        "followers_count": 20,
                        "following_count": 10,
                        "statuses_count": 50
                    },
                    "replies_count": 1,
                    "reblogs_count": 0,
                    "favourites_count": 2
                }
            ]
        }
        """.data(using: .utf8)!
        
        mockSession.mockData = contextData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://mastodon.social/api/v1/statuses/456/context")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Act
        let context = try await service.fetchThreadContext(statusID: "456")
        
        // Assert
        #expect(context.ancestors.count == 1)
        #expect(context.descendants.count == 1)
        
        let ancestor = context.ancestors.first!
        #expect(ancestor.id == "100")
        #expect(ancestor.content == "<p>Original post</p>")
        #expect(ancestor.account.username == "originaluser")
        
        let descendant = context.descendants.first!
        #expect(descendant.id == "200")
        #expect(descendant.content == "<p>Reply to the post</p>")
        #expect(descendant.account.username == "replier")
        #expect(descendant.replies_count == 1)
    }
    
    // MARK: - ViewModel Tests
    
    @Test("SocialDetailViewModel loads Mastodon details from metadata")
    func testLoadMastodonDetailsFromMetadata() async throws {
        // Arrange
        let mockSession = SharedMockURLSession()
        let appModel = AppModel.shared
        
        // Create a content item with metadata
        let contentItem = ContentItem(
            title: "Test Mastodon post",
            subtitle: "@testuser@mastodon.social • 5 replies",
            date: Date(),
            type: .mastodon,
            contentPreview: "Test content",
            progressPercentage: 0.0,
            metadata: [
                "statusId": "456",
                "accountDisplayName": "Test User",
                "accountHandle": "testuser@mastodon.social",
                "accountAvatar": "https://example.com/avatar.jpg",
                "repliesCount": 5,
                "reblogsCount": 10,
                "favouritesCount": 20,
                "rawContent": "<p>Test Mastodon post with HTML</p>",
                "mediaAttachments": [
                    [
                        "type": "image",
                        "url": "https://example.com/image.jpg"
                    ]
                ]
            ]
        )
        
        // Mock the thread context response
        let contextData = """
        {
            "ancestors": [],
            "descendants": [
                {
                    "id": "789",
                    "created_at": "2024-01-15T12:00:00.000Z",
                    "content": "<p>Great post!</p>",
                    "url": "https://mastodon.social/@replier/789",
                    "account": {
                        "id": "2",
                        "username": "replier",
                        "acct": "replier@mastodon.social",
                        "display_name": "Reply User",
                        "url": "https://mastodon.social/@replier",
                        "avatar": "https://example.com/replier-avatar.jpg",
                        "followers_count": 20,
                        "following_count": 10,
                        "statuses_count": 50
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        mockSession.mockData = contextData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://mastodon.social/api/v1/statuses/456/context")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Replace the API service with our mock
        let originalService = appModel.getMastodonAPIService()
        let mockService = MastodonAPIService(session: mockSession)
        
        // Act
        let viewModel = SocialDetailViewModel(item: contentItem)
        
        // Wait a bit for async operations
        try await Task.sleep(for: .milliseconds(200))
        
        // Assert - Check that metadata was properly loaded
        #expect(viewModel.authorName == "Test User")
        #expect(viewModel.authorHandle == "@testuser@mastodon.social")
        #expect(viewModel.replyCount == 5)
        #expect(viewModel.repostCount == 10)
        #expect(viewModel.likeCount == 20)
        #expect(viewModel.postContent == "Test Mastodon post with HTML")
        #expect(viewModel.hasImage == true)
        #expect(viewModel.imageURL?.absoluteString == "https://example.com/image.jpg")
    }
    
    // MARK: - Content Loading Tests
    
    @Test("ContentItem generates loading state for Mastodon")
    func testMastodonContentItemLoadingState() {
        // Arrange
        let source = Source(
            name: "Test Mastodon",
            type: .mastodon,
            description: "Test Mastodon instance",
            handle: "@test@mastodon.social"
        )
        
        // Act
        let contentItems = ContentItem.samplesForSource(source, count: 1)
        let contentItem = contentItems.first!
        
        // Assert
        #expect(contentItem.title == "Loading Mastodon posts...")
        #expect(contentItem.subtitle == "Fetching latest updates")
        #expect(contentItem.type == .mastodon)
        #expect(contentItem.contentPreview == "")
        #expect(contentItem.progressPercentage == 0.0)
    }
    
    // MARK: - Search Tests
    
    @Test("AppModel returns empty array for Mastodon search")
    func testMastodonSearchReturnsEmpty() {
        // Arrange
        let appModel = AppModel.shared
        
        // Act
        let results = appModel.searchSources(query: "test", type: .mastodon)
        
        // Assert
        #expect(results.isEmpty)
    }
}
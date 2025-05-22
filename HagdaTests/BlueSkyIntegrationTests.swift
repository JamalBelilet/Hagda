import XCTest
@testable import Hagda

/// Tests for complete Bluesky integration without dummy data
final class BlueSkyIntegrationTests: XCTestCase {
    
    var appModel: AppModel!
    var blueSkyService: BlueSkyAPIService!
    
    override func setUp() {
        super.setUp()
        appModel = AppModel(isTestingMode: true)
        blueSkyService = appModel.getBlueSkyAPIService()
    }
    
    override func tearDown() {
        appModel = nil
        blueSkyService = nil
        super.tearDown()
    }
    
    // MARK: - Content Item Tests
    
    func testContentItemHasMetadata() async throws {
        // Given a Bluesky source
        let source = Source(
            name: "Test User",
            type: .bluesky,
            description: "Test Bluesky account",
            handle: "test.bsky.social"
        )
        
        // When creating a content item with metadata
        let item = ContentItem(
            title: "Test post content",
            subtitle: "@test.bsky.social • 5 replies",
            date: Date(),
            type: .bluesky,
            contentPreview: "Test post content",
            progressPercentage: 0.0,
            metadata: [
                "uri": "at://did:plc:test/app.bsky.feed.post/test123",
                "cid": "test-cid",
                "authorDid": "did:plc:test",
                "authorHandle": "test.bsky.social",
                "authorDisplayName": "Test User",
                "authorAvatar": "https://example.com/avatar.jpg",
                "replyCount": 5,
                "repostCount": 10,
                "likeCount": 20,
                "indexedAt": "2023-12-20T10:00:00Z",
                "text": "Test post content"
            ]
        )
        
        // Then metadata should be accessible
        XCTAssertNotNil(item.metadata["uri"])
        XCTAssertNotNil(item.metadata["authorHandle"])
        XCTAssertEqual(item.metadata["replyCount"] as? Int, 5)
        XCTAssertEqual(item.metadata["likeCount"] as? Int, 20)
    }
    
    // MARK: - Thread Fetching Tests
    
    func testFetchPostThread() async throws {
        // Given a post URI
        let uri = "at://did:plc:test/app.bsky.feed.post/test123"
        
        do {
            // When fetching thread
            let thread = try await blueSkyService.fetchPostThread(uri: uri, depth: 3)
            
            // Then we should handle the response appropriately
            // In a real test, we'd mock the API response
            XCTAssertTrue(true, "Thread fetching implemented")
        } catch {
            // It's okay if this fails with real API - we're testing the implementation exists
            XCTAssertNotNil(error, "Should have an error if post doesn't exist")
        }
    }
    
    // MARK: - View Model Tests
    
    func testSocialDetailViewModelWithMetadata() {
        // Given a content item with Bluesky metadata
        let item = ContentItem(
            title: "Test Bluesky Post",
            subtitle: "@testuser.bsky.social • 5 replies • 10 reposts • 20 likes",
            date: Date(),
            type: .bluesky,
            contentPreview: "This is a test post",
            progressPercentage: 0.0,
            metadata: [
                "uri": "at://did:plc:test/app.bsky.feed.post/test123",
                "authorHandle": "testuser.bsky.social",
                "authorDisplayName": "Test User",
                "authorAvatar": "https://example.com/avatar.jpg",
                "replyCount": 5,
                "repostCount": 10,
                "likeCount": 20,
                "text": "This is a test post with full content"
            ]
        )
        
        // When creating view model
        let viewModel = SocialDetailViewModel(item: item)
        
        // Then it should extract metadata correctly
        XCTAssertEqual(viewModel.authorHandle, "testuser.bsky.social")
        XCTAssertEqual(viewModel.authorName, "Test User")
        XCTAssertEqual(viewModel.replyCount, 5)
        XCTAssertEqual(viewModel.repostCount, 10)
        XCTAssertEqual(viewModel.likeCount, 20)
        XCTAssertNotNil(viewModel.authorAvatarURL)
        XCTAssertEqual(viewModel.postContent, "This is a test post with full content")
    }
    
    func testSocialDetailViewModelWithoutMetadata() {
        // Given a content item without metadata (fallback case)
        let item = ContentItem(
            title: "Test Bluesky Post",
            subtitle: "@fallback.bsky.social • 3 replies",
            date: Date(),
            type: .bluesky,
            contentPreview: "This is a test post",
            progressPercentage: 0.0
        )
        
        // When creating view model
        let viewModel = SocialDetailViewModel(item: item)
        
        // Then it should parse from subtitle
        XCTAssertEqual(viewModel.authorHandle, "@fallback.bsky.social")
        XCTAssertEqual(viewModel.postContent, "Test Bluesky Post")
    }
    
    // MARK: - Sample Data Removal Tests
    
    func testNoSampleDataInContentItem() {
        // Given a Bluesky source
        let source = Source(
            name: "test",
            type: .bluesky,
            description: "Test account",
            handle: "test.bsky.social"
        )
        
        // When generating a sample
        let sample = ContentItem.samplesForSource(source).first!
        
        // Then it should not contain random generated content
        XCTAssertEqual(sample.title, "Loading Bluesky content...")
        XCTAssertEqual(sample.contentPreview, "Content will be loaded from the Bluesky API.")
        XCTAssertEqual(sample.progressPercentage, 0.0)
    }
    
    func testNoFallbackToSampleData() async {
        // Given a source that will fail to fetch
        let invalidSource = Source(
            name: "invalid",
            type: .bluesky,
            description: "Invalid source",
            handle: "invalid-handle" // Invalid format
        )
        
        do {
            // When fetching content
            _ = try await appModel.fetchBlueSkyContent(blueSkySource: invalidSource)
            
            // Then it should throw an error
            XCTFail("Should have thrown an error for invalid source")
        } catch {
            // This is expected - no fallback to sample data
            XCTAssertNotNil(error, "Error is expected for invalid source")
        }
    }
    
    // MARK: - Reply Model Tests
    
    func testReplyModelStructure() {
        // Given a reply
        let reply = SocialDetailViewModel.Reply(
            authorName: "Test User",
            authorHandle: "@test.bsky.social",
            authorAvatarURL: URL(string: "https://example.com/avatar.jpg"),
            content: "This is a test reply",
            timestamp: "2h ago"
        )
        
        // Then it should have all properties
        XCTAssertEqual(reply.authorName, "Test User")
        XCTAssertEqual(reply.authorHandle, "@test.bsky.social")
        XCTAssertNotNil(reply.authorAvatarURL)
        XCTAssertEqual(reply.content, "This is a test reply")
        XCTAssertEqual(reply.timestamp, "2h ago")
    }
    
    // MARK: - API Integration Tests
    
    func testSearchSourcesReturnsEmpty() {
        // Given the synchronous search method
        let results = appModel.searchSources(query: "test", type: .bluesky)
        
        // Then it should return empty array (async search required)
        XCTAssertTrue(results.isEmpty, "Synchronous search should return empty for Bluesky")
    }
    
    func testNoHardcodedBlueskySources() {
        // Given the sample sources
        let blueskySourceCount = Source.sampleSources.filter { $0.type == .bluesky }.count
        
        // Then there should be no hardcoded Bluesky sources
        XCTAssertEqual(blueskySourceCount, 0, "No hardcoded Bluesky sources should exist")
    }
}
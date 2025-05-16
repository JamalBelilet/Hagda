import XCTest
@testable import Hagda

/// Tests for the News API service and article details functionality
class NewsArticleTests: XCTestCase {
    
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
        
        func data(from url: URL) async throws -> (Data, URLResponse) {
            if let error = error {
                throw error
            }
            guard let data = data, let response = response else {
                throw URLError(.unknown)
            }
            return (data, response)
        }
    }
    
    /// Tests parsing RSS data
    func testRSSParsing() {
        // Create sample RSS data
        let rssData = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Test News Feed</title>
                <description>A test RSS feed for unit testing</description>
                <link>https://example.com/</link>
                <item>
                    <title>Test Article 1</title>
                    <description>This is the first test article</description>
                    <link>https://example.com/article1</link>
                    <pubDate>Tue, 15 May 2024 12:00:00 +0000</pubDate>
                    <author>Test Author</author>
                </item>
                <item>
                    <title>Test Article 2</title>
                    <description>This is the second test article</description>
                    <link>https://example.com/article2</link>
                    <pubDate>Mon, 14 May 2024 14:30:00 +0000</pubDate>
                </item>
            </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Parse the RSS data
        let parser = RSSParser()
        let items = parser.parse(data: rssData)
        
        // Verify the results
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "Test Article 1")
        XCTAssertEqual(items[0].description, "This is the first test article")
        XCTAssertEqual(items[0].author, "Test Author")
        XCTAssertEqual(items[0].feedTitle, "Test News Feed")
        XCTAssertEqual(items[0].feedDescription, "A test RSS feed for unit testing")
        
        XCTAssertEqual(items[1].title, "Test Article 2")
        XCTAssertEqual(items[1].description, "This is the second test article")
        XCTAssertNil(items[1].author)
    }
    
    /// Tests fetching articles from an RSS feed
    func testFetchArticles() async throws {
        // Create mock data
        let mockSession = MockURLSession()
        
        // Sample RSS data for a feed
        let rssData = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Test News Feed</title>
                <description>A test RSS feed for unit testing</description>
                <link>https://example.com/</link>
                <item>
                    <title>Test Article 1</title>
                    <description>This is the first test article</description>
                    <link>https://example.com/article1</link>
                    <pubDate>Tue, 15 May 2024 12:00:00 +0000</pubDate>
                    <author>Test Author</author>
                </item>
                <item>
                    <title>Test Article 2</title>
                    <description>This is the second test article</description>
                    <link>https://example.com/article2</link>
                    <pubDate>Mon, 14 May 2024 14:30:00 +0000</pubDate>
                </item>
            </channel>
        </rss>
        """.data(using: .utf8)!
        
        mockSession.data = rssData
        mockSession.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.error = nil
        
        // Create the News API service with the mock session
        let service = NewsAPIService(session: mockSession)
        
        // Create a source with an RSS feed URL
        let source = Source(
            name: "Test Source",
            type: .article,
            description: "A test news source",
            handle: nil,
            artworkUrl: nil,
            feedUrl: "https://example.com/feed.xml"
        )
        
        // Use real implementation of fetchArticles to test RSS parsing
        let articles = try await service.fetchArticles(for: source)
        
        // Verify the results
        XCTAssertEqual(articles.count, 2)
        XCTAssertEqual(articles[0].title, "Test Article 1")
        XCTAssertEqual(articles[0].type, .article)
        XCTAssertTrue(articles[0].subtitle.contains("By Test Author"))
        
        XCTAssertEqual(articles[1].title, "Test Article 2")
        XCTAssertEqual(articles[1].type, .article)
        XCTAssertTrue(articles[1].subtitle.contains("From Test Source"))
    }
    
    /// Tests the ArticleDetailViewModel initialization from a ContentItem
    func testArticleDetailViewModel() {
        // Create a content item for an article
        let contentItem = ContentItem(
            title: "Test Article Title",
            subtitle: "By John Doe • Test Source",
            date: Date(),
            type: .article,
            contentPreview: "This is a test article with sample content for testing purposes.",
            progressPercentage: 0.4
        )
        
        // Create the view model
        let viewModel = ArticleDetailViewModel(item: contentItem)
        
        // Verify the view model
        XCTAssertEqual(viewModel.title, "Test Article Title")
        XCTAssertEqual(viewModel.authorName, "John Doe")
        XCTAssertEqual(viewModel.sourceName, "Test Source")
        XCTAssertEqual(viewModel.progressPercentage, 0.4)
        XCTAssertEqual(viewModel.summary, "This is a test article with sample content for testing purposes.")
        
        // Reading time should be calculated
        XCTAssertGreaterThan(viewModel.estimatedReadingTime, 0)
        XCTAssertGreaterThan(viewModel.remainingReadingTime, 0)
        
        // The view model would try to load real data, which we can't test directly
        // So we'll just verify the initialization worked
        XCTAssertFalse(viewModel.isLoading) // Should start loading after initialization
        XCTAssertNil(viewModel.error) // Should not have an error initially
    }
    
    /// Tests parsing different subtitle formats
    func testSubtitleParsing() {
        // Create content items with different subtitle formats
        let contentItem1 = ContentItem(
            title: "Test Article 1",
            subtitle: "By John Doe • Test Source",
            date: Date(),
            type: .article
        )
        
        let contentItem2 = ContentItem(
            title: "Test Article 2",
            subtitle: "From Test Source",
            date: Date(),
            type: .article
        )
        
        let contentItem3 = ContentItem(
            title: "Test Article 3",
            subtitle: "Test Source",
            date: Date(),
            type: .article
        )
        
        // Create view models
        let viewModel1 = ArticleDetailViewModel(item: contentItem1)
        let viewModel2 = ArticleDetailViewModel(item: contentItem2)
        let viewModel3 = ArticleDetailViewModel(item: contentItem3)
        
        // Verify the parsing
        XCTAssertEqual(viewModel1.authorName, "John Doe")
        XCTAssertEqual(viewModel1.sourceName, "Test Source")
        
        XCTAssertEqual(viewModel2.authorName, "")
        XCTAssertEqual(viewModel2.sourceName, "Test Source")
        
        XCTAssertEqual(viewModel3.authorName, "")
        XCTAssertEqual(viewModel3.sourceName, "Test Source")
    }
}
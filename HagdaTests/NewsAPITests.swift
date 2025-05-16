import XCTest
@testable import Hagda

/// Tests for the NewsAPI integration using RSS feeds
class NewsAPITests: XCTestCase {
    
    // Test instance of the NewsAPIService
    var newsAPIService: NewsAPIService!
    
    // Mock URLSession for testing API calls without network
    var mockURLSession: SharedMockURLSession!
    
    override func setUp() {
        super.setUp()
        mockURLSession = SharedMockURLSession()
        newsAPIService = NewsAPIService(session: mockURLSession)
    }
    
    override func tearDown() {
        mockURLSession = nil
        newsAPIService = nil
        super.tearDown()
    }
    
    /// Test that the RSS parser correctly extracts items from a valid RSS feed
    func testRSSParserExtractsItems() {
        // Sample RSS data
        let rssData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
          <title>RSS Feed Title</title>
          <description>This is a test RSS feed</description>
          <link>http://example.com</link>
          <item>
            <title>First Article</title>
            <description>Description of the first article</description>
            <link>http://example.com/article1</link>
            <pubDate>Wed, 10 May 2023 12:00:00 +0000</pubDate>
            <author>John Doe</author>
          </item>
          <item>
            <title>Second Article</title>
            <description>Description of the second article</description>
            <link>http://example.com/article2</link>
            <pubDate>Thu, 11 May 2023 14:30:00 +0000</pubDate>
          </item>
        </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Parse the RSS feed
        let parser = RSSParser()
        let items = parser.parse(data: rssData)
        
        // Verify parsing results
        XCTAssertEqual(items.count, 2, "Parser should extract 2 items from the RSS feed")
        
        // Verify first item details
        XCTAssertEqual(items[0].title, "First Article")
        XCTAssertEqual(items[0].description, "Description of the first article")
        XCTAssertEqual(items[0].link, "http://example.com/article1")
        XCTAssertEqual(items[0].author, "John Doe")
        XCTAssertEqual(items[0].feedTitle, "RSS Feed Title")
        XCTAssertEqual(items[0].feedDescription, "This is a test RSS feed")
        
        // Verify second item details
        XCTAssertEqual(items[1].title, "Second Article")
        XCTAssertEqual(items[1].description, "Description of the second article")
        XCTAssertEqual(items[1].link, "http://example.com/article2")
        XCTAssertNil(items[1].author)
    }
    
    /// Test searching for news sources by keyword
    func testSearchSourcesByKeyword() {
        // Use async Task to test directly instead of completion handler
        let searchQuery = "technology"
        let mockResponse = mockCuratedSourcesResponse()
        
        mockURLSession.mockData = mockResponse
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://cloud.feedly.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Create expectation for async test
        let expectation = XCTestExpectation(description: "Search news sources")
        
        // Use Task to run async code
        Task {
            do {
                let sources = try await newsAPIService.searchSources(query: searchQuery)
                
                // Verify the sources were returned correctly
                XCTAssertEqual(sources.count, 2, "Should return 2 sources")
                XCTAssertEqual(sources[0].name, "The Verge", "First source name should be The Verge")
                XCTAssertEqual(sources[0].type, .article, "Source type should be article")
                XCTAssertEqual(sources[1].name, "Wired", "Second source name should be Wired")
                
                expectation.fulfill()
            } catch {
                XCTFail("Search should succeed, but got error: \(error)")
                expectation.fulfill()
            }
        }
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test discovering RSS feeds from a website URL
    func testDiscoverFeedsFromWebsite() {
        // Mock successful HTML response with RSS links
        let websiteURL = "https://example.com"
        let mockHTML = """
        <html>
          <head>
            <title>Example Website</title>
            <link rel="alternate" type="application/rss+xml" title="Example RSS Feed" href="https://example.com/feed.xml">
            <link rel="alternate" type="application/rss+xml" title="Example Category Feed" href="https://example.com/category/feed.xml">
          </head>
          <body>
            <h1>Example Website</h1>
          </body>
        </html>
        """.data(using: .utf8)!
        
        // Mock RSS feed data for the discovered feed
        let mockRSSData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
          <title>Example RSS Feed</title>
          <description>Example website's RSS feed</description>
          <link>https://example.com</link>
          <item>
            <title>Example Article</title>
            <description>Description of the example article</description>
            <link>https://example.com/article</link>
            <pubDate>Wed, 10 May 2023 12:00:00 +0000</pubDate>
          </item>
        </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Set up sequential responses for the mock session
        let sequentialSession = SharedSequentialMockURLSession()
        sequentialSession.mockResponses = [
            (mockHTML, HTTPURLResponse(url: URL(string: websiteURL)!, statusCode: 200, httpVersion: nil, headerFields: nil)!, nil),
            (mockRSSData, HTTPURLResponse(url: URL(string: "https://example.com/feed.xml")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, nil)
        ]
        
        newsAPIService = NewsAPIService(session: sequentialSession)
        
        // Create expectation for async test
        let expectation = XCTestExpectation(description: "Discover RSS feeds")
        
        // Use Task for async testing
        Task {
            do {
                let sources = try await newsAPIService.searchSources(query: websiteURL)
                
                // Verify at least one source was discovered
                XCTAssertGreaterThanOrEqual(sources.count, 1, "Should discover at least one RSS feed")
                if let source = sources.first {
                    XCTAssertEqual(source.type, .article, "Source type should be article")
                    XCTAssertNotNil(source.feedUrl, "Feed URL should not be nil")
                    XCTAssertTrue(source.feedUrl?.contains("feed.xml") ?? false, "Feed URL should contain feed.xml")
                }
                
                expectation.fulfill()
            } catch {
                XCTFail("Feed discovery should succeed, but got error: \(error)")
                expectation.fulfill()
            }
        }
        
        // Wait for expectation
        wait(for: [expectation], timeout: 2.0)
    }
    
    /// Test fetching articles from an RSS feed
    func testFetchArticlesFromRSSFeed() {
        // Create a test source with a feed URL
        let testSource = Source(
            name: "Test RSS Feed",
            type: .article,
            description: "A test RSS feed",
            handle: "technology",
            artworkUrl: nil,
            feedUrl: "https://example.com/feed.xml"
        )
        
        // Mock RSS feed data
        let mockRSSData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
          <title>Test RSS Feed</title>
          <description>A test RSS feed</description>
          <link>https://example.com</link>
          <item>
            <title>Article 1</title>
            <description>Description of article 1</description>
            <link>https://example.com/article1</link>
            <pubDate>Wed, 10 May 2023 12:00:00 +0000</pubDate>
            <author>John Doe</author>
          </item>
          <item>
            <title>Article 2</title>
            <description>Description of article 2</description>
            <link>https://example.com/article2</link>
            <pubDate>Thu, 11 May 2023 14:30:00 +0000</pubDate>
          </item>
        </channel>
        </rss>
        """.data(using: .utf8)!
        
        mockURLSession.mockData = mockRSSData
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://example.com/feed.xml")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Create expectation for async test
        let expectation = XCTestExpectation(description: "Fetch articles")
        
        // Use Task for async testing
        Task {
            do {
                let articles = try await newsAPIService.fetchArticles(for: testSource)
                
                // Verify articles were fetched correctly
                XCTAssertEqual(articles.count, 2, "Should fetch 2 articles")
                XCTAssertEqual(articles[0].title, "Article 1", "First article title should be 'Article 1'")
                XCTAssertEqual(articles[0].subtitle, "By John Doe", "First article subtitle should include author")
                XCTAssertEqual(articles[0].type, .article, "Article type should be article")
                
                XCTAssertEqual(articles[1].title, "Article 2", "Second article title should be 'Article 2'")
                XCTAssertEqual(articles[1].subtitle, "From Test RSS Feed", "Second article subtitle should include source name")
                
                expectation.fulfill()
            } catch {
                XCTFail("Article fetching should succeed, but got error: \(error)")
                expectation.fulfill()
            }
        }
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test handling of malformed RSS data
    func testHandleMalformedRSSData() {
        // Create a test source with a feed URL
        let testSource = Source(
            name: "Malformed RSS Feed",
            type: .article,
            description: "A malformed RSS feed",
            handle: "technology",
            artworkUrl: nil,
            feedUrl: "https://example.com/malformed-feed.xml"
        )
        
        // Malformed RSS data (invalid XML)
        let malformedRSSData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
          <title>Malformed RSS Feed</title>
          <description>A malformed RSS feed</description>
          <link>https://example.com</link>
          <item>
            <title>Article 1</title>
            <description>Description of article 1</description>
            <!-- Missing closing tags and malformed XML -->
          <item>
            <title>Article 2</title>
            <description>Description of article 2</description>
        </channel>
        """.data(using: .utf8)!
        
        mockURLSession.mockData = malformedRSSData
        mockURLSession.mockResponse = HTTPURLResponse(url: URL(string: "https://example.com/malformed-feed.xml")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Create expectation for async test
        let expectation = XCTestExpectation(description: "Handle malformed RSS")
        
        // Use Task for async testing
        Task {
            do {
                let articles = try await newsAPIService.fetchArticles(for: testSource)
                
                // In debug mode, should return sample data as fallback
                #if DEBUG
                XCTAssertFalse(articles.isEmpty, "Should return sample data as fallback in debug mode")
                #else
                XCTFail("Should throw an error for malformed RSS")
                #endif
                
                expectation.fulfill()
            } catch {
                // In production, should throw an error
                #if DEBUG
                XCTFail("Should return sample data as fallback in debug mode")
                #else
                // Success - correctly threw an error
                #endif
                
                expectation.fulfill()
            }
        }
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helper Methods
    
    /// Generate mock response data for curated sources
    private func mockCuratedSourcesResponse() -> Data {
        let response = """
        {
          "results": [
            {
              "feedId": "feed/https://www.theverge.com/rss/index.xml",
              "title": "The Verge",
              "description": "The Verge covers the intersection of technology, science, art, and culture.",
              "website": "theverge.com",
              "iconUrl": "https://cdn.vox-cdn.com/uploads/chorus_asset/file/7395367/favicon-64x64.0.png",
              "visualUrl": "https://cdn.vox-cdn.com/uploads/chorus_asset/file/7395367/favicon-128x128.0.png"
            },
            {
              "feedId": "feed/https://www.wired.com/feed/rss",
              "title": "Wired",
              "description": "In-depth coverage of current and future trends in technology.",
              "website": "wired.com",
              "iconUrl": "https://www.wired.com/favicon.ico"
            }
          ]
        }
        """.data(using: .utf8)!
        
        return response
    }
}


import Testing
import Foundation
@testable import Hagda

/// Tests for Article detail functionality
struct ArticleDetailTests {
    
    // MARK: - Content Item Tests
    
    @Test("News article converts to ContentItem with metadata")
    func testNewsArticleToContentItem() async throws {
        // Arrange
        let newsSource = Source(
            name: "Tech News Daily",
            type: .article,
            description: "Technology news and analysis",
            handle: "technology",
            artworkUrl: nil,
            feedUrl: "https://example.com/rss"
        )
        
        let article = NewsArticle(
            guid: "article-123",
            title: "Apple Announces New AI Features",
            description: "Apple has unveiled a suite of new artificial intelligence features that will be integrated across its product lineup.",
            link: "https://example.com/articles/apple-ai",
            pubDate: Date(),
            author: "Jane Smith",
            category: "Technology",
            imageUrl: "https://example.com/images/apple-ai.jpg",
            content: "Full article content with more details about the announcement..."
        )
        
        // Act
        let contentItem = article.toContentItem(newsSource: newsSource)
        
        // Assert
        #expect(contentItem.type == .article)
        #expect(contentItem.title == "Apple Announces New AI Features")
        #expect(contentItem.subtitle == "By Jane Smith")
        
        // Check metadata
        #expect(contentItem.metadata["articleGuid"] as? String == "article-123")
        #expect(contentItem.metadata["articleTitle"] as? String == "Apple Announces New AI Features")
        #expect(contentItem.metadata["articleLink"] as? String == "https://example.com/articles/apple-ai")
        #expect(contentItem.metadata["articleAuthor"] as? String == "Jane Smith")
        #expect(contentItem.metadata["articleCategory"] as? String == "Technology")
        #expect(contentItem.metadata["articleImageUrl"] as? String == "https://example.com/images/apple-ai.jpg")
        #expect(contentItem.metadata["sourceName"] as? String == "Tech News Daily")
        
        // Check content is prioritized over description
        let content = contentItem.metadata["articleContent"] as? String
        #expect(content?.contains("Full article content") == true)
    }
    
    @Test("News article without author uses source name")
    func testNewsArticleWithoutAuthor() {
        // Arrange
        let newsSource = Source(
            name: "Tech News Daily",
            type: .article,
            description: "Technology news",
            feedUrl: "https://example.com/rss"
        )
        
        let article = NewsArticle(
            guid: "article-456",
            title: "Breaking News",
            description: "News description",
            link: "https://example.com/breaking",
            pubDate: Date(),
            author: nil,
            category: nil,
            imageUrl: nil,
            content: nil
        )
        
        // Act
        let contentItem = article.toContentItem(newsSource: newsSource)
        
        // Assert
        #expect(contentItem.subtitle == "From Tech News Daily")
    }
    
    // MARK: - ViewModel Tests
    
    @Test("ArticleDetailViewModel loads details from metadata")
    func testLoadArticleDetailsFromMetadata() async throws {
        // Arrange
        let contentItem = ContentItem(
            title: "Test Article",
            subtitle: "By Test Author",
            date: Date(),
            type: .article,
            contentPreview: "Preview text",
            progressPercentage: 0.3,
            metadata: [
                "articleGuid": "test-123",
                "articleTitle": "Full Article Title with More Detail",
                "articleDescription": "Short description",
                "articleLink": "https://example.com/full-article",
                "articleAuthor": "John Doe",
                "articleImageUrl": "https://example.com/article-image.jpg",
                "articleContent": "This is the full article content with much more detail than the preview. It contains multiple paragraphs and goes into depth about the subject matter.",
                "sourceName": "Premium Tech News"
            ]
        )
        
        // Act
        let viewModel = ArticleDetailViewModel(item: contentItem)
        
        // Wait a bit for async operations
        try await Task.sleep(for: .milliseconds(200))
        
        // Assert - Check that metadata was properly loaded
        #expect(viewModel.title == "Full Article Title with More Detail")
        #expect(viewModel.sourceName == "Premium Tech News")
        #expect(viewModel.authorName == "John Doe")
        #expect(viewModel.fullContent.contains("full article content") == true)
        #expect(viewModel.articleURL?.absoluteString == "https://example.com/full-article")
        #expect(viewModel.imageURL?.absoluteString == "https://example.com/article-image.jpg")
        #expect(viewModel.hasImage == true)
        
        // Check reading time calculation (content has ~26 words)
        #expect(viewModel.estimatedReadingTime == 1)
        #expect(viewModel.remainingReadingTime == 1) // 70% remaining at 0.3 progress
    }
    
    // MARK: - RSS Parsing Tests
    
    @Test("Parse RSS feed into NewsItems")
    func testRSSParsing() {
        // Arrange
        let rssXml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Tech News RSS</title>
                <description>Latest technology news</description>
                <item>
                    <title>First Article Title</title>
                    <description>First article description</description>
                    <link>https://example.com/article1</link>
                    <pubDate>Mon, 15 Jan 2024 10:00:00 +0000</pubDate>
                    <author>author@example.com (Jane Doe)</author>
                    <enclosure url="https://example.com/image1.jpg" type="image/jpeg"/>
                </item>
                <item>
                    <title>Second Article Title</title>
                    <description>Second article description</description>
                    <link>https://example.com/article2</link>
                    <pubDate>Sun, 14 Jan 2024 15:30:00 +0000</pubDate>
                </item>
            </channel>
        </rss>
        """
        
        let parser = RSSParser()
        let data = rssXml.data(using: .utf8)!
        
        // Act
        let items = parser.parse(data: data)
        
        // Assert
        #expect(items.count == 2)
        
        let firstItem = items[0]
        #expect(firstItem.title == "First Article Title")
        #expect(firstItem.description == "First article description")
        #expect(firstItem.link == "https://example.com/article1")
        #expect(firstItem.author == "author@example.com (Jane Doe)")
        #expect(firstItem.imageUrl == "https://example.com/image1.jpg")
        
        let secondItem = items[1]
        #expect(secondItem.title == "Second Article Title")
        #expect(secondItem.author == nil)
    }
    
    // MARK: - Content Loading Tests
    
    @Test("ContentItem generates loading state for Articles")
    func testArticleContentItemLoadingState() {
        // Arrange
        let source = Source(
            name: "Test News",
            type: .article,
            description: "Test news source",
            handle: "technology"
        )
        
        // Act
        let contentItems = ContentItem.samplesForSource(source, count: 1)
        let contentItem = contentItems.first!
        
        // Assert
        #expect(contentItem.title == "Loading articles...")
        #expect(contentItem.subtitle == "Fetching latest news")
        #expect(contentItem.type == .article)
        #expect(contentItem.contentPreview == "")
        #expect(contentItem.progressPercentage == 0.0)
    }
    
    // MARK: - Reading Progress Tests
    
    @Test("Calculate remaining content summary")
    func testRemainingContentSummary() {
        // Arrange
        let contentItem = ContentItem(
            title: "Test Article",
            subtitle: "Test Source",
            date: Date(),
            type: .article,
            contentPreview: "The quick brown fox jumps over the lazy dog. This is a test article with multiple sentences to test the progress calculation.",
            progressPercentage: 0.5
        )
        
        let viewModel = ArticleDetailViewModel(item: contentItem)
        
        // Act
        let remaining = viewModel.remainingContentSummary
        
        // Assert
        #expect(remaining.contains("lazy dog") == true)
        #expect(remaining.contains("quick brown fox") == false)
    }
}
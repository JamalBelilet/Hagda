import XCTest
@testable import Hagda

/// Tests for the iTunes Search API service and podcast episode details functionality
class PodcastEpisodeTests: XCTestCase {
    
    // Mock URL session for testing API calls
    class MockURLSession: URLSessionProtocol {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            completionHandler(data, response, error)
            return URLSessionDataTask()
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
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
    
    /// Tests parsing RSS feed data
    func testPodcastRSSParsing() async throws {
        // Create sample RSS data for a podcast feed
        let rssData = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
            <channel>
                <title>Test Podcast</title>
                <description>A test podcast feed for unit testing</description>
                <link>https://example.com/podcast/</link>
                <item>
                    <title>Episode 1: Introduction</title>
                    <description>This is the first episode of our podcast</description>
                    <pubDate>Mon, 14 May 2024 10:00:00 +0000</pubDate>
                    <guid>episode-001</guid>
                    <itunes:duration>30:00</itunes:duration>
                    <enclosure url="https://example.com/podcast/episode1.mp3" type="audio/mpeg" length="10000000"/>
                </item>
                <item>
                    <title>Episode 2: Deep Dive</title>
                    <description>This is the second episode of our podcast</description>
                    <pubDate>Mon, 21 May 2024 10:00:00 +0000</pubDate>
                    <guid>episode-002</guid>
                    <itunes:duration>45:20</itunes:duration>
                    <enclosure url="https://example.com/podcast/episode2.mp3" type="audio/mpeg" length="20000000"/>
                </item>
            </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Create mock session
        let mockSession = MockURLSession()
        mockSession.data = rssData
        mockSession.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.error = nil
        
        // Create the iTunes Search API service with the mock session
        let service = ITunesSearchService(session: mockSession)
        
        // Create a source
        let source = Source(
            name: "Test Podcast",
            type: .podcast,
            description: "A test podcast feed for unit testing",
            handle: "by Test Author",
            artworkUrl: nil,
            feedUrl: "https://example.com/podcast/feed.xml"
        )
        
        // Fetch episodes
        let episodes = try await service.fetchPodcastEpisodes(from: "https://example.com/podcast/feed.xml", source: source)
        
        // Verify the results
        XCTAssertEqual(episodes.count, 2)
        XCTAssertEqual(episodes[0].title, "Episode 1: Introduction")
        XCTAssertEqual(episodes[0].type, .podcast)
        // Duration should be formatted from the iTunes duration tag
        XCTAssertEqual(episodes[0].subtitle, "30:00")
        
        XCTAssertEqual(episodes[1].title, "Episode 2: Deep Dive")
        XCTAssertEqual(episodes[1].type, .podcast)
        XCTAssertEqual(episodes[1].subtitle, "45:20")
    }
    
    /// Tests the PodcastDetailViewModel initialization from a ContentItem
    func testPodcastDetailViewModel() {
        // Create a content item for a podcast episode
        let contentItem = ContentItem(
            title: "Episode 100: Test Podcast Episode",
            subtitle: "45 minutes • Interview",
            date: Date(),
            type: .podcast,
            contentPreview: """
            In this episode, we talk about testing with XCTest.
            
            Topics covered include:
            • Unit testing basics
            • UI testing strategies
            • Performance testing considerations
            """,
            progressPercentage: 0.4
        )
        
        // Create the view model
        let viewModel = PodcastDetailViewModel(item: contentItem)
        
        // Verify the view model
        XCTAssertEqual(viewModel.title, "Episode 100: Test Podcast Episode")
        XCTAssertEqual(viewModel.duration, "45 minutes")
        XCTAssertEqual(viewModel.podcastName, "Interview")
        XCTAssertEqual(viewModel.progressPercentage, 0.4)
        
        // Total time should be calculated from the duration
        XCTAssertEqual(viewModel.totalTime, 45 * 60) // 45 minutes in seconds
        
        // Current time should be calculated from progress percentage
        XCTAssertEqual(viewModel.currentTime, Int(45 * 60 * 0.4)) // 40% of 45 minutes
        
        // Show notes should be extracted from the content preview
        XCTAssertFalse(viewModel.showNotes.isEmpty)
        XCTAssertEqual(viewModel.showNotes.count, 3) // 3 bullet points in the preview
        
        // The view model would try to load real data, which we can't test directly
        // So we'll just verify the initialization worked
        XCTAssertFalse(viewModel.isLoading) // Should start loading after initialization
        XCTAssertNil(viewModel.error) // Should not have an error initially
    }
    
    /// Tests the duration formatting
    func testDurationFormatting() {
        // Create a view model with a 45-minute episode
        let contentItem = ContentItem(
            title: "Test Episode",
            subtitle: "45 minutes",
            date: Date(),
            type: .podcast
        )
        
        let viewModel = PodcastDetailViewModel(item: contentItem)
        
        // Set up the total time and current time
        // Note: This is automatically set up in init based on the duration string
        XCTAssertEqual(viewModel.totalTime, 45 * 60) // 45 minutes in seconds
        
        // Test time formatting
        XCTAssertEqual(viewModel.formatTime(seconds: 0), "0:00")
        XCTAssertEqual(viewModel.formatTime(seconds: 30), "0:30")
        XCTAssertEqual(viewModel.formatTime(seconds: 60), "1:00")
        XCTAssertEqual(viewModel.formatTime(seconds: 90), "1:30")
        XCTAssertEqual(viewModel.formatTime(seconds: 3600), "60:00")
        XCTAssertEqual(viewModel.formatTime(seconds: 3661), "61:01")
    }
    
    /// Tests the playback control methods
    func testPlaybackControl() {
        // Create a content item for a podcast episode
        let contentItem = ContentItem(
            title: "Test Episode",
            subtitle: "60 minutes",
            date: Date(),
            type: .podcast,
            progressPercentage: 0.25
        )
        
        // Create the view model
        let viewModel = PodcastDetailViewModel(item: contentItem)
        
        // Verify initial state
        XCTAssertEqual(viewModel.totalTime, 60 * 60) // 60 minutes in seconds
        XCTAssertEqual(viewModel.currentTime, Int(60 * 60 * 0.25)) // 25% of 60 minutes
        XCTAssertEqual(viewModel.progressPercentage, 0.25)
        XCTAssertFalse(viewModel.isPlaying)
        
        // Test toggle playback
        viewModel.togglePlayback()
        XCTAssertTrue(viewModel.isPlaying)
        viewModel.togglePlayback()
        XCTAssertFalse(viewModel.isPlaying)
        
        // Test rewind
        let initialTime = viewModel.currentTime
        viewModel.rewind15Seconds()
        XCTAssertEqual(viewModel.currentTime, initialTime - 15)
        XCTAssertEqual(viewModel.progressPercentage, Double(viewModel.currentTime) / Double(viewModel.totalTime))
        
        // Test fast forward
        viewModel.fastForward15Seconds()
        XCTAssertEqual(viewModel.currentTime, initialTime)
        XCTAssertEqual(viewModel.progressPercentage, Double(viewModel.currentTime) / Double(viewModel.totalTime))
        
        // Test seek
        viewModel.seekTo(time: 1800) // 30 minutes
        XCTAssertEqual(viewModel.currentTime, 1800)
        XCTAssertEqual(viewModel.progressPercentage, 1800.0 / Double(viewModel.totalTime))
        
        // Test boundary conditions
        // - Seek before start
        viewModel.seekTo(time: -100)
        XCTAssertEqual(viewModel.currentTime, 0)
        XCTAssertEqual(viewModel.progressPercentage, 0.0)
        
        // - Seek past end
        viewModel.seekTo(time: viewModel.totalTime + 100)
        XCTAssertEqual(viewModel.currentTime, viewModel.totalTime)
        XCTAssertEqual(viewModel.progressPercentage, 1.0)
    }
}
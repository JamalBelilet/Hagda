import Testing
import Foundation
@testable import Hagda

/// Tests for Podcast detail functionality
struct PodcastDetailTests {
    
    // MARK: - Content Item Tests
    
    @Test("Podcast episode converts to ContentItem with metadata")
    func testPodcastEpisodeToContentItem() async throws {
        // Arrange
        let podcastSource = Source(
            name: "Tech Talk Show",
            type: .podcast,
            description: "Technology discussions and interviews",
            handle: "by John Doe",
            artworkUrl: "https://example.com/podcast-art.jpg",
            feedUrl: "https://example.com/feed.xml"
        )
        
        let episode = PodcastEpisode(
            guid: "ep-123",
            title: "Episode 42: The Future of AI",
            description: "In this episode, we discuss artificial intelligence and its impact on society.",
            pubDate: "Mon, 15 Jan 2024 10:30:00 +0000",
            enclosure: PodcastEpisode.Enclosure(
                url: "https://example.com/episode42.mp3",
                type: "audio/mpeg",
                length: "45678900"
            ),
            duration: "45:30",
            link: "https://example.com/episodes/42",
            author: "Jane Smith",
            summary: "AI discussion with expert guests",
            image: "https://example.com/episode42-art.jpg"
        )
        
        // Act
        let contentItem = episode.toContentItem(podcastSource: podcastSource)
        
        // Assert
        #expect(contentItem.type == .podcast)
        #expect(contentItem.title == "Episode 42: The Future of AI")
        #expect(contentItem.subtitle == "45 min")
        
        // Check metadata
        #expect(contentItem.metadata["episodeGuid"] as? String == "ep-123")
        #expect(contentItem.metadata["episodeTitle"] as? String == "Episode 42: The Future of AI")
        #expect(contentItem.metadata["episodeDuration"] as? String == "45:30")
        #expect(contentItem.metadata["episodeFormattedDuration"] as? String == "45 min")
        #expect(contentItem.metadata["audioUrl"] as? String == "https://example.com/episode42.mp3")
        #expect(contentItem.metadata["episodeAuthor"] as? String == "Jane Smith")
        #expect(contentItem.metadata["episodeImageUrl"] as? String == "https://example.com/episode42-art.jpg")
        #expect(contentItem.metadata["podcastName"] as? String == "Tech Talk Show")
        #expect(contentItem.metadata["podcastArtworkUrl"] as? String == "https://example.com/podcast-art.jpg")
    }
    
    // MARK: - Duration Formatting Tests
    
    @Test("Format various duration strings correctly")
    func testDurationFormatting() {
        // Test seconds only
        let episode1 = PodcastEpisode(
            guid: "1",
            title: "Test",
            description: "",
            pubDate: "",
            enclosure: nil,
            duration: "3600",
            link: nil,
            author: nil,
            summary: nil,
            image: nil
        )
        #expect(episode1.formattedDuration == "1 hr 0 min")
        
        // Test HH:MM:SS format
        let episode2 = PodcastEpisode(
            guid: "2",
            title: "Test",
            description: "",
            pubDate: "",
            enclosure: nil,
            duration: "1:25:30",
            link: nil,
            author: nil,
            summary: nil,
            image: nil
        )
        #expect(episode2.formattedDuration == "1 hr 25 min")
        
        // Test MM:SS format
        let episode3 = PodcastEpisode(
            guid: "3",
            title: "Test",
            description: "",
            pubDate: "",
            enclosure: nil,
            duration: "45:30",
            link: nil,
            author: nil,
            summary: nil,
            image: nil
        )
        #expect(episode3.formattedDuration == "45 min")
        
        // Test no duration
        let episode4 = PodcastEpisode(
            guid: "4",
            title: "Test",
            description: "",
            pubDate: "",
            enclosure: nil,
            duration: nil,
            link: nil,
            author: nil,
            summary: nil,
            image: nil
        )
        #expect(episode4.formattedDuration == "Unknown length")
    }
    
    // MARK: - ViewModel Tests
    
    @Test("PodcastDetailViewModel loads details from metadata")
    func testLoadPodcastDetailsFromMetadata() async throws {
        // Arrange
        let contentItem = ContentItem(
            title: "Test Episode",
            subtitle: "45 minutes",
            date: Date(),
            type: .podcast,
            contentPreview: "Test preview",
            progressPercentage: 0.25,
            metadata: [
                "episodeGuid": "ep-456",
                "episodeTitle": "Episode 100: Machine Learning Basics",
                "episodeDescription": "A comprehensive introduction to machine learning concepts.",
                "episodeDuration": "2700", // 45 minutes in seconds
                "episodeFormattedDuration": "45 min",
                "audioUrl": "https://example.com/ml-basics.mp3",
                "episodeAuthor": "Dr. Sarah Johnson",
                "episodeImageUrl": "https://example.com/ml-episode.jpg",
                "podcastName": "AI Explained",
                "podcastArtworkUrl": "https://example.com/ai-podcast.jpg"
            ]
        )
        
        // Act
        let viewModel = PodcastDetailViewModel(item: contentItem)
        
        // Wait a bit for async operations
        try await Task.sleep(for: .milliseconds(200))
        
        // Assert - Check that metadata was properly loaded
        #expect(viewModel.title == "Episode 100: Machine Learning Basics")
        #expect(viewModel.podcastName == "AI Explained")
        #expect(viewModel.authorName == "Dr. Sarah Johnson")
        #expect(viewModel.duration == "45 min")
        #expect(viewModel.description == "A comprehensive introduction to machine learning concepts.")
        #expect(viewModel.audioURL?.absoluteString == "https://example.com/ml-basics.mp3")
        #expect(viewModel.artworkURL?.absoluteString == "https://example.com/ml-episode.jpg")
        #expect(viewModel.hasArtwork == true)
        #expect(viewModel.totalTime == 2700)
        #expect(viewModel.currentTime == 675) // 25% of 2700
    }
    
    // MARK: - Playback Control Tests
    
    @Test("Playback controls work correctly")
    func testPlaybackControls() {
        // Arrange
        let contentItem = ContentItem(
            title: "Test Episode",
            subtitle: "60 minutes",
            date: Date(),
            type: .podcast,
            contentPreview: "",
            progressPercentage: 0.5
        )
        let viewModel = PodcastDetailViewModel(item: contentItem)
        viewModel.totalTime = 3600 // 60 minutes
        viewModel.currentTime = 1800 // 30 minutes
        
        // Test toggle playback
        #expect(viewModel.isPlaying == false)
        viewModel.togglePlayback()
        #expect(viewModel.isPlaying == true)
        
        // Test rewind
        viewModel.rewind15Seconds()
        #expect(viewModel.currentTime == 1785)
        
        // Test fast forward
        viewModel.fastForward15Seconds()
        viewModel.fastForward15Seconds()
        #expect(viewModel.currentTime == 1815)
        
        // Test seek
        viewModel.seekTo(time: 2400)
        #expect(viewModel.currentTime == 2400)
        #expect(viewModel.progressPercentage == 2400.0 / 3600.0)
        
        // Test boundary conditions
        viewModel.seekTo(time: -100)
        #expect(viewModel.currentTime == 0)
        
        viewModel.seekTo(time: 4000)
        #expect(viewModel.currentTime == 3600)
    }
    
    // MARK: - Content Loading Tests
    
    @Test("ContentItem generates loading state for Podcast")
    func testPodcastContentItemLoadingState() {
        // Act
        let contentItem = ContentItem.generateSampleForType(.podcast)
        
        // Assert
        #expect(contentItem.title == "Loading podcast episodes...")
        #expect(contentItem.subtitle == "Fetching latest episodes")
        #expect(contentItem.type == .podcast)
        #expect(contentItem.contentPreview == "")
        #expect(contentItem.progressPercentage == 0.0)
    }
    
    // MARK: - Feed Parsing Tests
    
    @Test("Parse podcast episodes from RSS feed")
    func testParsePodcastEpisodes() async throws {
        // Arrange
        let mockSession = MockURLSession()
        let service = ITunesSearchService(session: mockSession)
        
        let feedXml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>Test Podcast</title>
                <item>
                    <title>Episode 1: Introduction</title>
                    <description>Welcome to our podcast!</description>
                    <pubDate>Mon, 15 Jan 2024 10:00:00 +0000</pubDate>
                    <guid>episode-1</guid>
                    <enclosure url="https://example.com/ep1.mp3" type="audio/mpeg" length="12345678"/>
                    <itunes:duration>30:45</itunes:duration>
                    <itunes:author>Host Name</itunes:author>
                    <itunes:summary>An introduction to our show</itunes:summary>
                </item>
            </channel>
        </rss>
        """
        
        mockSession.data = feedXml.data(using: .utf8)!
        mockSession.response = HTTPURLResponse(
            url: URL(string: "https://example.com/feed.xml")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/rss+xml"]
        )
        
        let source = Source(
            name: "Test Podcast",
            type: .podcast,
            description: "A test podcast",
            feedUrl: "https://example.com/feed.xml"
        )
        
        // Act
        let episodes = try await service.fetchPodcastEpisodes(from: source.feedUrl!, source: source)
        
        // Assert
        #expect(episodes.count == 1)
        
        let episode = episodes.first!
        #expect(episode.title == "Episode 1: Introduction")
        #expect(episode.contentPreview == "Welcome to our podcast!")
        #expect(episode.type == .podcast)
        
        // Check metadata
        #expect(episode.metadata["episodeGuid"] as? String == "episode-1")
        #expect(episode.metadata["audioUrl"] as? String == "https://example.com/ep1.mp3")
        #expect(episode.metadata["episodeAuthor"] as? String == "Host Name")
    }
}
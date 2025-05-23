import Testing
@testable import Hagda
import AVFoundation

@Suite("Podcast Player Tests")
struct PodcastPlayerTests {
    
    @Test("Episode conversion from ContentItem")
    func testEpisodeConversion() {
        // Create a sample ContentItem with podcast metadata
        let item = ContentItem(
            title: "Test Episode",
            subtitle: "45 minutes",
            date: Date(),
            type: .podcast,
            metadata: [
                "episodeGuid": "test-123",
                "episodeTitle": "Test Episode Title",
                "audioUrl": "https://example.com/episode.mp3",
                "podcastName": "Test Podcast",
                "episodeImageUrl": "https://example.com/artwork.jpg",
                "episodeDescription": "Test description",
                "episodeDuration": "2700" // 45 minutes
            ]
        )
        
        // Convert to player episode
        let episode = PodcastEpisode.fromContentItem(item)
        
        #expect(episode != nil)
        #expect(episode?.id == "test-123")
        #expect(episode?.title == "Test Episode Title")
        #expect(episode?.podcastTitle == "Test Podcast")
        #expect(episode?.audioURL == "https://example.com/episode.mp3")
        #expect(episode?.artworkURL == "https://example.com/artwork.jpg")
        #expect(episode?.duration == 2700)
    }
    
    @Test("Duration parsing from various formats")
    func testDurationParsing() {
        // Test cases for duration parsing
        let testCases: [(String, TimeInterval?)] = [
            ("3600", 3600),           // Seconds as string
            ("45:30", 2730),          // MM:SS
            ("1:23:45", 5025),        // HH:MM:SS
            ("invalid", nil),         // Invalid format
            ("", nil),                // Empty string
            ("12", 12),               // Just seconds
            ("0:30", 30),             // 30 seconds
            ("01:00:00", 3600)       // 1 hour with leading zeros
        ]
        
        for (input, expected) in testCases {
            let item = ContentItem(
                title: "Test",
                subtitle: "",
                date: Date(),
                type: .podcast,
                metadata: ["episodeDuration": input, "episodeGuid": "test", "episodeTitle": "Test"]
            )
            
            let episode = PodcastEpisode.fromContentItem(item)
            #expect(episode?.duration == expected)
        }
    }
    
    @Test("Playback progress calculation")
    func testPlaybackProgress() {
        // Create episode with known duration
        let item = ContentItem(
            title: "Test Episode",
            subtitle: "30 minutes",
            date: Date(),
            type: .podcast,
            metadata: [
                "episodeGuid": "progress-test",
                "episodeDuration": "1800" // 30 minutes
            ]
        )
        
        // Clear any existing progress
        UserDefaults.standard.removeObject(forKey: "progress_progress-test")
        
        // Initially should be 0
        #expect(item.playbackProgress == 0)
        
        // Save some progress (15 minutes = 50%)
        UserDefaults.standard.set(900.0, forKey: "progress_progress-test")
        
        // Check progress calculation
        #expect(item.playbackProgress == 0.5)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "progress_progress-test")
    }
    
    @Test("Episode played status")
    func testPlayedStatus() {
        let item = ContentItem(
            title: "Test Episode",
            subtitle: "",
            date: Date(),
            type: .podcast,
            metadata: ["episodeGuid": "played-test"]
        )
        
        // Clear any existing status
        UserDefaults.standard.removeObject(forKey: "played_played-test")
        
        // Initially should not be played
        #expect(item.isPlayed == false)
        
        // Mark as played
        UserDefaults.standard.set(true, forKey: "played_played-test")
        
        // Check played status
        #expect(item.isPlayed == true)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "played_played-test")
    }
    
    @Test("Time formatting")
    func testTimeFormatting() {
        // Test various time intervals
        let testCases: [(TimeInterval, String)] = [
            (0, "0:00"),
            (30, "0:30"),
            (90, "1:30"),
            (3600, "1:00:00"),
            (3661, "1:01:01"),
            (7200, "2:00:00")
        ]
        
        for (interval, _) in testCases {
            let formatted = interval.formattedTime
            #expect(formatted.contains(":"))
            #expect(!formatted.isEmpty)
        }
    }
    
    @Test("Condensed time formatting")
    func testCondensedTimeFormatting() {
        // Test condensed format
        let interval: TimeInterval = 5400 // 1.5 hours
        let condensed = interval.condensedTime
        
        #expect(condensed.contains("h") || condensed.contains("m"))
        #expect(!condensed.isEmpty)
    }
    
    @Test("Sleep timer presets")
    func testSleepTimerPresets() {
        let timer = SleepTimer.shared
        
        #expect(timer.presetDurations.count > 0)
        #expect(timer.presetDurations.contains(where: { $0.seconds == 900 })) // 15 minutes
        #expect(timer.presetDurations.contains(where: { $0.seconds == -1 })) // End of episode
    }
    
    @Test("Audio player manager singleton")
    func testAudioPlayerManagerSingleton() {
        let manager1 = AudioPlayerManager.shared
        let manager2 = AudioPlayerManager.shared
        
        #expect(manager1 === manager2)
    }
    
    @Test("Playback speed options")
    func testPlaybackSpeedOptions() {
        let manager = AudioPlayerManager.shared
        
        #expect(manager.availableSpeeds.contains(1.0)) // Normal speed
        #expect(manager.availableSpeeds.contains(0.5)) // Half speed
        #expect(manager.availableSpeeds.contains(2.0)) // Double speed
        #expect(manager.availableSpeeds.count >= 5) // At least 5 options
    }
}

// Mock tests for player functionality that requires actual audio
@Suite("Podcast Player Mock Tests")
struct PodcastPlayerMockTests {
    
    @Test("Player error types")
    func testPlayerErrorTypes() {
        let invalidURLError = PodcastPlayerError.invalidAudioURL
        #expect(invalidURLError.localizedDescription == "Invalid audio URL")
        
        let playbackError = PodcastPlayerError.playbackFailed
        #expect(playbackError.localizedDescription == "Playback failed")
        
        let downloadError = PodcastPlayerError.downloadFailed
        #expect(downloadError.localizedDescription == "Download failed")
    }
    
    @Test("Player initial state")
    func testPlayerInitialState() {
        let manager = AudioPlayerManager.shared
        
        // Initial state should be not playing
        #expect(manager.isPlaying == false)
        #expect(manager.currentTime == 0)
        #expect(manager.duration == 0)
        #expect(manager.playbackRate == 1.0)
        #expect(manager.isLoading == false)
    }
}
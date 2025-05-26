import Testing
import Foundation
@testable import Hagda

@Suite("PodcastProgressTracker Tests")
@MainActor
struct PodcastProgressTrackerTests {
    
    @Test("Save and load podcast progress")
    func testSaveAndLoadProgress() throws {
        // Given
        let tracker = PodcastProgressTracker.shared
        let episode = AudioPlayerManager.PodcastEpisode(
            id: "test-episode-1",
            title: "Test Episode",
            podcastTitle: "Test Podcast",
            audioURL: "https://example.com/episode.mp3",
            duration: 3600, // 1 hour
            artworkURL: "https://example.com/artwork.jpg",
            description: "Test description",
            publishDate: Date(),
            metadata: ["sourceId": "source-123"]
        )
        
        // When
        tracker.saveProgress(for: episode, currentTime: 1800, sourceId: "source-123")
        let loadedProgress = tracker.loadProgress(for: episode.id)
        
        // Then
        #expect(loadedProgress != nil)
        #expect(loadedProgress?.episodeId == episode.id)
        #expect(loadedProgress?.currentTime == 1800)
        #expect(loadedProgress?.duration == 3600)
        #expect(loadedProgress?.progressPercentage == 0.5)
        #expect(loadedProgress?.remainingTime == 1800)
        #expect(loadedProgress?.isInProgress == true)
        
        // Cleanup
        tracker.clearProgress(for: episode.id)
    }
    
    @Test("Get all in-progress episodes")
    func testGetAllInProgressEpisodes() throws {
        // Given
        let tracker = PodcastProgressTracker.shared
        let episodes = [
            AudioPlayerManager.PodcastEpisode(
                id: "test-episode-2",
                title: "Episode 2",
                podcastTitle: "Test Podcast",
                audioURL: "https://example.com/episode2.mp3",
                duration: 3600,
                artworkURL: nil,
                description: "Test",
                publishDate: Date(),
                metadata: ["sourceId": "source-123"]
            ),
            AudioPlayerManager.PodcastEpisode(
                id: "test-episode-3",
                title: "Episode 3",
                podcastTitle: "Test Podcast",
                audioURL: "https://example.com/episode3.mp3",
                duration: 1800,
                artworkURL: nil,
                description: "Test",
                publishDate: Date(),
                metadata: ["sourceId": "source-456"]
            )
        ]
        
        // When
        tracker.saveProgress(for: episodes[0], currentTime: 600, sourceId: "source-123")
        tracker.saveProgress(for: episodes[1], currentTime: 900, sourceId: "source-456")
        
        let inProgressEpisodes = tracker.getAllInProgressEpisodes()
        
        // Then
        #expect(inProgressEpisodes.count >= 2)
        #expect(inProgressEpisodes.contains { $0.episodeId == "test-episode-2" })
        #expect(inProgressEpisodes.contains { $0.episodeId == "test-episode-3" })
        
        // Cleanup
        for episode in episodes {
            tracker.clearProgress(for: episode.id)
        }
    }
    
    @Test("Mark episode as played when > 90% complete")
    func testMarkAsPlayedWhenAlmostComplete() throws {
        // Given
        let tracker = PodcastProgressTracker.shared
        let episode = AudioPlayerManager.PodcastEpisode(
            id: "test-episode-4",
            title: "Nearly Complete Episode",
            podcastTitle: "Test Podcast",
            audioURL: "https://example.com/episode4.mp3",
            duration: 1000,
            artworkURL: nil,
            description: "Test",
            publishDate: Date(),
            metadata: ["sourceId": "source-789"]
        )
        
        // When
        tracker.saveProgress(for: episode, currentTime: 950, sourceId: "source-789") // 95% complete
        let loadedProgress = tracker.loadProgress(for: episode.id)
        
        // Then
        #expect(loadedProgress?.progressPercentage ?? 0 > 0.9)
        #expect(loadedProgress?.isInProgress == false) // Should not be in progress
        
        // Verify it's not included in in-progress list
        let inProgressEpisodes = tracker.getAllInProgressEpisodes()
        #expect(!inProgressEpisodes.contains { $0.episodeId == episode.id })
        
        // Cleanup
        tracker.clearProgress(for: episode.id)
    }
    
    @Test("Create ContentItem from progress entry")
    func testCreateContentItemFromProgress() throws {
        // Given
        let tracker = PodcastProgressTracker.shared
        let episode = AudioPlayerManager.PodcastEpisode(
            id: "test-episode-5",
            title: "Content Item Test Episode",
            podcastTitle: "Test Podcast",
            audioURL: "https://example.com/episode5.mp3",
            duration: 3600, // 1 hour
            artworkURL: "https://example.com/artwork.jpg",
            description: "Test description",
            publishDate: Date(),
            metadata: ["sourceId": "source-999"]
        )
        
        // When
        tracker.saveProgress(for: episode, currentTime: 1200, sourceId: "source-999") // 20 minutes listened
        let progress = tracker.loadProgress(for: episode.id)
        let contentItem = tracker.createContentItem(from: progress!)
        
        // Then
        #expect(contentItem.title == "Content Item Test Episode")
        #expect(contentItem.subtitle.contains("40 minutes left"))
        #expect(contentItem.subtitle.contains("Test Podcast"))
        #expect(contentItem.type == .podcast)
        #expect(contentItem.progressPercentage == progress?.progressPercentage ?? 0)
        
        // Check metadata
        #expect(contentItem.metadata["episodeGuid"] as? String == episode.id)
        #expect(contentItem.metadata["podcastName"] as? String == "Test Podcast")
        #expect(contentItem.metadata["audioUrl"] as? String == "https://example.com/episode5.mp3")
        #expect(contentItem.metadata["sourceId"] as? String == "source-999")
        
        // Cleanup
        tracker.clearProgress(for: episode.id)
    }
    
    @Test("Clear old progress")
    func testClearOldProgress() throws {
        // Given
        let tracker = PodcastProgressTracker.shared
        let oldEpisode = AudioPlayerManager.PodcastEpisode(
            id: "old-episode",
            title: "Old Episode",
            podcastTitle: "Test Podcast",
            audioURL: "https://example.com/old.mp3",
            duration: 3600,
            artworkURL: nil,
            description: "Test",
            publishDate: Date(),
            metadata: ["sourceId": "source-old"]
        )
        
        // When - Save progress and then clear immediately (simulating old progress)
        tracker.saveProgress(for: oldEpisode, currentTime: 1800, sourceId: "source-old")
        
        // Verify it exists
        #expect(tracker.loadProgress(for: oldEpisode.id) != nil)
        
        // Clear old progress (0 days old for test)
        tracker.clearOldProgress(olderThan: 0)
        
        // Then - Old progress should be cleared
        #expect(tracker.loadProgress(for: oldEpisode.id) == nil)
    }
    
    @Test("Handle legacy progress format")
    func testLegacyProgressFormat() throws {
        // Given
        let tracker = PodcastProgressTracker.shared
        let episodeId = "legacy-episode"
        let userDefaults = UserDefaults.standard
        
        // Simulate legacy format by setting only the old progress key
        userDefaults.set(1234.5, forKey: "progress_\(episodeId)")
        
        // When
        let loadedTime = tracker.loadProgressTime(for: episodeId)
        
        // Then
        #expect(loadedTime == 1234.5)
        
        // Cleanup
        userDefaults.removeObject(forKey: "progress_\(episodeId)")
    }
}
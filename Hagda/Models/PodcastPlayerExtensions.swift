import Foundation

// MARK: - PodcastEpisode Extension for Audio Player

extension PodcastEpisode {
    /// Convert metadata from ContentItem back to PodcastEpisode for player
    static func fromContentItem(_ item: ContentItem) -> AudioPlayerManager.PodcastEpisode? {
        guard item.type == .podcast,
              let episodeId = item.metadata["episodeGuid"] as? String,
              let episodeTitle = item.metadata["episodeTitle"] as? String else {
            return nil
        }
        
        let audioURL = item.metadata["audioUrl"] as? String
        let podcastTitle = item.metadata["podcastName"] as? String
        let artworkURL = (item.metadata["episodeImageUrl"] as? String) ?? (item.metadata["podcastArtworkUrl"] as? String)
        let description = item.metadata["episodeDescription"] as? String
        
        // Parse duration if available
        var duration: TimeInterval? = nil
        if let durationString = item.metadata["episodeDuration"] as? String {
            duration = parseDurationToSeconds(durationString)
        }
        
        return AudioPlayerManager.PodcastEpisode(
            id: episodeId,
            title: episodeTitle,
            podcastTitle: podcastTitle,
            audioURL: audioURL,
            duration: duration,
            artworkURL: artworkURL,
            description: description,
            publishDate: item.date
        )
    }
    
    /// Parse various duration formats to seconds
    static func parseDurationToSeconds(_ duration: String) -> TimeInterval? {
        // Try parsing as seconds first
        if let seconds = TimeInterval(duration) {
            return seconds
        }
        
        // Try parsing HH:MM:SS or MM:SS format
        let components = duration.split(separator: ":").compactMap { Int($0) }
        
        switch components.count {
        case 1:
            // Just seconds
            return TimeInterval(components[0])
        case 2:
            // MM:SS
            return TimeInterval(components[0] * 60 + components[1])
        case 3:
            // HH:MM:SS
            return TimeInterval(components[0] * 3600 + components[1] * 60 + components[2])
        default:
            return nil
        }
    }
}

// MARK: - ContentItem Extension for Playback Progress

extension ContentItem {
    /// Get playback progress for this episode
    var playbackProgress: Double {
        guard type == .podcast,
              let episodeId = metadata["episodeGuid"] as? String else {
            return 0
        }
        
        let savedTime = UserDefaults.standard.double(forKey: "progress_\(episodeId)")
        
        // Get duration to calculate percentage
        if let durationString = metadata["episodeDuration"] as? String,
           let duration = PodcastEpisode.parseDurationToSeconds(durationString),
           duration > 0 {
            return min(savedTime / duration, 1.0)
        }
        
        return 0
    }
    
    /// Check if episode has been played
    var isPlayed: Bool {
        guard type == .podcast,
              let episodeId = metadata["episodeGuid"] as? String else {
            return false
        }
        
        return UserDefaults.standard.bool(forKey: "played_\(episodeId)")
    }
}

// MARK: - Time Formatting Helpers

extension TimeInterval {
    /// Format time interval as MM:SS or HH:MM:SS
    var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = self >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? "0:00"
    }
    
    /// Format as condensed time (e.g., "5m", "1h 30m")
    var condensedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? "0m"
    }
}
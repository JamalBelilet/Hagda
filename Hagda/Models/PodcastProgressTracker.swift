import Foundation

/// Tracks podcast episode progress with enhanced metadata
@MainActor
class PodcastProgressTracker {
    static let shared = PodcastProgressTracker()
    
    private let userDefaults = UserDefaults.standard
    private let progressPrefix = "podcast_progress_"
    private let metadataPrefix = "podcast_metadata_"
    
    private init() {}
    
    // MARK: - Progress Entry Model
    
    struct ProgressEntry: Codable {
        let episodeId: String
        let episodeTitle: String
        let podcastTitle: String
        let artworkURL: String?
        let audioURL: String
        let currentTime: TimeInterval
        let duration: TimeInterval
        let lastPlayedDate: Date
        let sourceId: String
        
        var progressPercentage: Double {
            guard duration > 0 else { return 0 }
            return currentTime / duration
        }
        
        var remainingTime: TimeInterval {
            return max(0, duration - currentTime)
        }
        
        var isInProgress: Bool {
            return progressPercentage > 0 && progressPercentage < 0.9
        }
    }
    
    // MARK: - Save Progress
    
    func saveProgress(for episode: AudioPlayerManager.PodcastEpisode, 
                     currentTime: TimeInterval,
                     sourceId: String) {
        let entry = ProgressEntry(
            episodeId: episode.id,
            episodeTitle: episode.title,
            podcastTitle: episode.podcastTitle ?? "Unknown Podcast",
            artworkURL: episode.artworkURL,
            audioURL: episode.audioURL ?? "",
            currentTime: currentTime,
            duration: episode.duration ?? 0,
            lastPlayedDate: Date(),
            sourceId: sourceId
        )
        
        // Save encoded entry
        if let encoded = try? JSONEncoder().encode(entry) {
            userDefaults.set(encoded, forKey: progressPrefix + episode.id)
        }
        
        // Also save in legacy format for compatibility
        userDefaults.set(currentTime, forKey: "progress_\(episode.id)")
        
        // Mark as played if > 90% complete
        if entry.progressPercentage > 0.9 {
            userDefaults.set(true, forKey: "played_\(episode.id)")
        }
    }
    
    // MARK: - Load Progress
    
    func loadProgress(for episodeId: String) -> ProgressEntry? {
        guard let data = userDefaults.data(forKey: progressPrefix + episodeId),
              let entry = try? JSONDecoder().decode(ProgressEntry.self, from: data) else {
            // Try legacy format
            let time = userDefaults.double(forKey: "progress_\(episodeId)")
            return time > 0 ? createLegacyEntry(episodeId: episodeId, time: time) : nil
        }
        return entry
    }
    
    func loadProgressTime(for episodeId: String) -> TimeInterval? {
        if let entry = loadProgress(for: episodeId) {
            return entry.currentTime
        }
        // Legacy format
        let time = userDefaults.double(forKey: "progress_\(episodeId)")
        return time > 0 ? time : nil
    }
    
    // MARK: - Get All In-Progress
    
    func getAllInProgressEpisodes() -> [ProgressEntry] {
        let keys = userDefaults.dictionaryRepresentation().keys
        let progressKeys = keys.filter { $0.hasPrefix(progressPrefix) }
        
        let entries = progressKeys.compactMap { key -> ProgressEntry? in
            guard let data = userDefaults.data(forKey: key),
                  let entry = try? JSONDecoder().decode(ProgressEntry.self, from: data) else {
                return nil
            }
            return entry.isInProgress ? entry : nil
        }
        
        // Sort by last played date, most recent first
        return entries.sorted { $0.lastPlayedDate > $1.lastPlayedDate }
    }
    
    // MARK: - Clear Progress
    
    func clearProgress(for episodeId: String) {
        userDefaults.removeObject(forKey: progressPrefix + episodeId)
        userDefaults.removeObject(forKey: "progress_\(episodeId)")
        userDefaults.removeObject(forKey: "played_\(episodeId)")
    }
    
    func clearOldProgress(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let entries = getAllInProgressEpisodes()
        for entry in entries where entry.lastPlayedDate < cutoffDate {
            clearProgress(for: entry.episodeId)
        }
    }
    
    // MARK: - Migration Support
    
    private func createLegacyEntry(episodeId: String, time: TimeInterval) -> ProgressEntry? {
        // Create a basic entry for legacy progress data
        return ProgressEntry(
            episodeId: episodeId,
            episodeTitle: "Unknown Episode",
            podcastTitle: "Unknown Podcast",
            artworkURL: nil,
            audioURL: "",
            currentTime: time,
            duration: 0,
            lastPlayedDate: Date().addingTimeInterval(-86400), // 1 day ago
            sourceId: ""
        )
    }
    
    // MARK: - ContentItem Conversion
    
    func createContentItem(from entry: ProgressEntry) -> ContentItem {
        let remainingMinutes = Int(entry.remainingTime / 60)
        let subtitle = "\(remainingMinutes) minutes left • \(entry.podcastTitle)"
        
        return ContentItem(
            title: entry.episodeTitle,
            subtitle: subtitle,
            date: entry.lastPlayedDate,
            type: .podcast,
            contentPreview: "",
            progressPercentage: entry.progressPercentage,
            metadata: [
                "episodeGuid": entry.episodeId,
                "episodeTitle": entry.episodeTitle,
                "audioUrl": entry.audioURL,
                "podcastName": entry.podcastTitle,
                "podcastArtworkUrl": entry.artworkURL ?? "",
                "episodeDuration": String(entry.duration),
                "sourceId": entry.sourceId,
                "lastPlayedDate": entry.lastPlayedDate
            ]
        )
    }
}
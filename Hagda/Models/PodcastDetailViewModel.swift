import Foundation
import SwiftUI

/// ViewModel for podcast episode detail views
@Observable
class PodcastDetailViewModel {
    // MARK: - Properties
    
    /// The content item to display
    let item: ContentItem
    
    /// Loading state
    var isLoading = false
    
    /// Error state
    var error: Error?
    
    /// Episode information
    var title: String = ""
    var podcastName: String = ""
    var authorName: String = ""
    var duration: String = ""
    var description: String = ""
    var formattedDate: String = ""
    
    /// Audio playback state
    var isPlaying: Bool = false
    var progressPercentage: Double = 0.0
    var currentTime: Int = 0 // in seconds
    var totalTime: Int = 0 // in seconds
    
    /// Media content
    var hasArtwork: Bool = false
    var artworkURL: URL?
    
    /// Audio file information
    var audioURL: URL?
    
    /// Show notes and chapters
    var showNotes: [String] = []
    
    // MARK: - Initialization
    
    init(item: ContentItem) {
        self.item = item
        
        // Set initial values from the content item
        self.title = item.title
        self.description = item.contentPreview
        self.progressPercentage = item.progressPercentage
        
        // Extract podcast name, duration from subtitle
        // Format: "45 minutes • Interview" or just "62 minutes"
        let subtitleComponents = item.subtitle.components(separatedBy: " • ")
        if !subtitleComponents.isEmpty {
            self.duration = subtitleComponents[0]
            
            // Try to parse the duration string into seconds
            let durationComponents = duration.components(separatedBy: " ")
            if durationComponents.count >= 2 {
                if let minutes = Int(durationComponents[0]) {
                    self.totalTime = minutes * 60
                    self.currentTime = Int(Double(totalTime) * progressPercentage)
                }
            }
            
            // Extract episode type or topic if available
            if subtitleComponents.count > 1 {
                self.podcastName = subtitleComponents[1]
            }
        }
        
        // Format the date
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        self.formattedDate = formatter.localizedString(for: item.date, relativeTo: Date())
        
        // Generate show notes based on the content preview
        generateShowNotes()
        
        // Load additional details
        loadPodcastDetails()
    }
    
    // MARK: - Data Loading
    
    /// Load additional details for a podcast episode
    private func loadPodcastDetails() {
        Task {
            do {
                self.isLoading = true
                
                // Check if we have metadata from the feed
                let metadata = item.metadata
                
                await MainActor.run {
                    // Set episode information from metadata
                    if let episodeTitle = metadata["episodeTitle"] as? String {
                        self.title = episodeTitle
                    }
                    
                    if let podcastName = metadata["podcastName"] as? String {
                        self.podcastName = podcastName
                    }
                    
                    if let author = metadata["episodeAuthor"] as? String, !author.isEmpty {
                        self.authorName = author
                    }
                    
                    if let formattedDuration = metadata["episodeFormattedDuration"] as? String {
                        self.duration = formattedDuration
                    }
                    
                    // Get full description from metadata
                    if let fullDescription = metadata["episodeDescription"] as? String, !fullDescription.isEmpty {
                        self.description = fullDescription
                    } else if let summary = metadata["episodeSummary"] as? String, !summary.isEmpty {
                        self.description = summary
                    }
                    
                    // Set audio URL
                    if let audioUrlString = metadata["audioUrl"] as? String,
                       !audioUrlString.isEmpty {
                        self.audioURL = URL(string: audioUrlString)
                    }
                    
                    // Set artwork URL
                    if let episodeImage = metadata["episodeImageUrl"] as? String,
                       !episodeImage.isEmpty {
                        self.artworkURL = URL(string: episodeImage)
                        self.hasArtwork = true
                    } else if let podcastArtwork = metadata["podcastArtworkUrl"] as? String,
                              !podcastArtwork.isEmpty {
                        self.artworkURL = URL(string: podcastArtwork)
                        self.hasArtwork = true
                    }
                    
                    // Parse duration to seconds if available
                    if let durationStr = metadata["episodeDuration"] as? String {
                        self.parseDurationToSeconds(durationStr)
                    }
                    
                    // Generate show notes from the full description
                    generateShowNotes()
                }
                
                self.isLoading = false
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Update the UI with existing data
    @MainActor
    private func updateUIWithExistingData() {
        // Extract show title from the episode title if possible
        // Format: "Episode 245: The State of Modern Development"
        if title.contains(":") {
            if let colonIndex = title.firstIndex(of: ":") {
                self.podcastName = String(title[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Set calculated properties
        if totalTime == 0 {
            // Parse the duration string into minutes if not already set
            let components = duration.components(separatedBy: " ")
            if components.count >= 2 && components[1].contains("min") {
                if let minutes = Int(components[0]) {
                    self.totalTime = minutes * 60
                    self.currentTime = Int(Double(totalTime) * progressPercentage)
                }
            }
        }
    }
    
    /// Generate show notes based on the content preview
    private func generateShowNotes() {
        // Parse bullet points or numbered items from the content preview
        if description.contains("•") {
            let bulletItems = description
                .components(separatedBy: "•")
                .dropFirst() // Drop the text before the first bullet
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            showNotes = bulletItems
        } else if description.contains("\n") {
            // Try to parse lines as show notes
            let lines = description
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            showNotes = lines
        }
        
        // If no structured notes found, create default ones
        if showNotes.isEmpty {
            showNotes = [
                "Introduction and topic overview",
                "Main discussion points",
                "Q&A and listener questions"
            ]
        }
    }
    
    // MARK: - Playback Control
    
    /// Toggle play/pause state
    func togglePlayback() {
        isPlaying.toggle()
    }
    
    /// Rewind the current playback position
    func rewind15Seconds() {
        currentTime = max(0, currentTime - 15)
        progressPercentage = min(1.0, max(0.0, Double(currentTime) / Double(totalTime)))
    }
    
    /// Fast forward the current playback position
    func fastForward15Seconds() {
        currentTime = min(totalTime, currentTime + 15)
        progressPercentage = min(1.0, max(0.0, Double(currentTime) / Double(totalTime)))
    }
    
    /// Set the current playback position directly
    func seekTo(time: Int) {
        currentTime = max(0, min(totalTime, time))
        progressPercentage = min(1.0, max(0.0, Double(currentTime) / Double(totalTime)))
    }
    
    /// Format a time in seconds to a string (MM:SS)
    func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    /// Get a summary of the remaining content
    var remainingContentSummary: String {
        if description.isEmpty {
            return "The episode continues with a discussion of implementation details and practical examples. The hosts interview an industry expert about their experiences and insights."
        }
        
        if let endIndex = description.index(description.startIndex, offsetBy: description.count / 2, limitedBy: description.endIndex) {
            return String(description[endIndex...])
        }
        
        return "The episode continues with additional insights and expert interviews."
    }
    
    /// Parse duration string to seconds
    private func parseDurationToSeconds(_ durationStr: String) {
        // If it's just seconds as a string (e.g., "3600")
        if let seconds = Int(durationStr) {
            self.totalTime = seconds
            self.currentTime = Int(Double(totalTime) * progressPercentage)
            return
        }
        
        // If it's in format HH:MM:SS
        let components = durationStr.split(separator: ":").map { String($0) }
        if components.count == 3 {
            let hours = Int(components[0]) ?? 0
            let minutes = Int(components[1]) ?? 0
            let seconds = Int(components[2]) ?? 0
            self.totalTime = hours * 3600 + minutes * 60 + seconds
            self.currentTime = Int(Double(totalTime) * progressPercentage)
        } else if components.count == 2 {
            let minutes = Int(components[0]) ?? 0
            let seconds = Int(components[1]) ?? 0
            self.totalTime = minutes * 60 + seconds
            self.currentTime = Int(Double(totalTime) * progressPercentage)
        }
    }
}
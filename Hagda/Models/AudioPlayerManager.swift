import Foundation
import AVFoundation
import MediaPlayer
import Combine

/// Manages podcast audio playback
@MainActor
class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()
    
    // MARK: - Published Properties
    
    @Published var currentEpisode: PodcastEpisode?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var isLoading = false
    @Published var error: Error?
    @Published var downloadProgress: Double = 0
    
    // MARK: - Private Properties
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private let session = AVAudioSession.sharedInstance()
    private var cancellables = Set<AnyCancellable>()
    
    // Playback speeds
    let availableSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
        setupNotifications()
        setupRemoteCommands()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Playback Control
    
    func play(episode: PodcastEpisode) {
        guard let audioURLString = episode.audioURL,
              let audioURL = URL(string: audioURLString) else {
            self.error = PodcastPlayerError.invalidAudioURL
            return
        }
        
        // If same episode, just resume
        if currentEpisode?.id == episode.id {
            resume()
            return
        }
        
        // Save current progress before switching
        if let current = currentEpisode {
            saveProgress(for: current, time: currentTime)
        }
        
        // Setup new episode
        currentEpisode = episode
        isLoading = true
        error = nil
        
        // Create player item
        playerItem = AVPlayerItem(url: audioURL)
        
        // Create or update player
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            setupTimeObserver()
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        // Observe player item status
        playerItem?.publisher(for: \.status)
            .sink { [weak self] status in
                self?.handlePlayerItemStatus(status)
            }
            .store(in: &cancellables)
        
        // Observe duration
        playerItem?.publisher(for: \.duration)
            .compactMap { CMTimeGetSeconds($0) }
            .filter { !$0.isNaN }
            .sink { [weak self] duration in
                self?.duration = duration
            }
            .store(in: &cancellables)
        
        // Set playback rate
        player?.rate = playbackRate
        
        // Load saved progress
        if let savedTime = loadProgress(for: episode) {
            seek(to: savedTime)
        }
        
        // Start playback
        player?.play()
        isPlaying = true
        
        updateNowPlayingInfo()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        saveCurrentProgress()
        updateNowPlayingInfo()
    }
    
    func resume() {
        guard player != nil else { return }
        player?.play()
        player?.rate = playbackRate
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime) { [weak self] _ in
            self?.currentTime = time
            self?.updateNowPlayingInfo()
        }
    }
    
    func skipForward(_ seconds: TimeInterval = 30) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
        UserDefaults.standard.set(rate, forKey: "playbackRate")
    }
    
    // MARK: - Progress Management
    
    private func saveCurrentProgress() {
        guard let episode = currentEpisode else { return }
        saveProgress(for: episode, time: currentTime)
    }
    
    private func saveProgress(for episode: PodcastEpisode, time: TimeInterval) {
        UserDefaults.standard.set(time, forKey: "progress_\(episode.id)")
        
        // Mark as played if > 90% complete
        if duration > 0 && time / duration > 0.9 {
            markAsPlayed(episode)
        }
    }
    
    private func loadProgress(for episode: PodcastEpisode) -> TimeInterval? {
        let time = UserDefaults.standard.double(forKey: "progress_\(episode.id)")
        return time > 0 ? time : nil
    }
    
    private func markAsPlayed(_ episode: PodcastEpisode) {
        UserDefaults.standard.set(true, forKey: "played_\(episode.id)")
    }
    
    func isPlayed(_ episode: PodcastEpisode) -> Bool {
        UserDefaults.standard.bool(forKey: "played_\(episode.id)")
    }
    
    // MARK: - Time Observer
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
    }
    
    // MARK: - Player Item Status
    
    private func handlePlayerItemStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            isLoading = false
        case .failed:
            isLoading = false
            error = playerItem?.error ?? PodcastPlayerError.playbackFailed
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Now Playing Info
    
    private func updateNowPlayingInfo() {
        guard let episode = currentEpisode else { return }
        
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = episode.title
        info[MPMediaItemPropertyArtist] = episode.podcastTitle ?? "Podcast"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0
        
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        // Set artwork if available
        if let artworkURL = episode.artworkURL,
           let url = URL(string: artworkURL) {
            // In production, implement async image loading
            // For now, we'll skip artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Remote Commands
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play/Pause
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        
        // Skip
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            let skipEvent = event as? MPSkipIntervalCommandEvent
            self?.skipForward(skipEvent?.interval ?? 30)
            return .success
        }
        
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            let skipEvent = event as? MPSkipIntervalCommandEvent
            self?.skipBackward(skipEvent?.interval ?? 15)
            return .success
        }
        
        // Seek
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: positionEvent.positionTime)
            return .success
        }
        
        // Configure skip intervals
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        // Audio interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // Route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // Player item ended
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resume()
                }
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        // Pause when headphones are unplugged
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }
    
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        // Mark as played
        if let episode = currentEpisode {
            markAsPlayed(episode)
        }
        
        // Reset to beginning
        seek(to: 0)
        pause()
        
        // TODO: Play next episode if in queue
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Error Types

enum PodcastPlayerError: LocalizedError {
    case invalidAudioURL
    case playbackFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAudioURL:
            return "Invalid audio URL"
        case .playbackFailed:
            return "Playback failed"
        case .downloadFailed:
            return "Download failed"
        }
    }
}

// MARK: - Podcast Episode Model for Player

extension AudioPlayerManager {
    struct PodcastEpisode {
        let id: String
        let title: String
        let podcastTitle: String?
        let audioURL: String?
        let duration: TimeInterval?
        let artworkURL: String?
        let description: String?
        let publishDate: Date
    }
}
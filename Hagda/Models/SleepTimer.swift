import Foundation
import Combine

/// Manages sleep timer functionality for podcast playback
@MainActor
class SleepTimer: ObservableObject {
    static let shared = SleepTimer()
    
    @Published var isActive = false
    @Published var remainingTime: TimeInterval = 0
    @Published var selectedDuration: TimeInterval = 900 // 15 minutes default
    
    private var timer: Timer?
    private var endTime: Date?
    
    // Preset durations
    let presetDurations: [(label: String, seconds: TimeInterval)] = [
        ("5 minutes", 300),
        ("10 minutes", 600),
        ("15 minutes", 900),
        ("30 minutes", 1800),
        ("45 minutes", 2700),
        ("1 hour", 3600),
        ("End of episode", -1) // Special case
    ]
    
    private init() {}
    
    /// Start the sleep timer
    func start(duration: TimeInterval) {
        stop() // Cancel any existing timer
        
        selectedDuration = duration
        remainingTime = duration
        endTime = Date().addingTimeInterval(duration)
        isActive = true
        
        // Create timer that updates every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    /// Start timer to end at episode completion
    func startUntilEndOfEpisode() {
        guard let currentEpisode = AudioPlayerManager.shared.currentEpisode,
              let duration = currentEpisode.duration else {
            return
        }
        
        let currentTime = AudioPlayerManager.shared.currentTime
        let remaining = duration - currentTime
        
        if remaining > 0 {
            start(duration: remaining)
        }
    }
    
    /// Stop the sleep timer
    func stop() {
        timer?.invalidate()
        timer = nil
        isActive = false
        remainingTime = 0
        endTime = nil
    }
    
    /// Extend the timer by additional minutes
    func extend(by minutes: Int) {
        guard isActive, let endTime = endTime else { return }
        
        let additionalTime = TimeInterval(minutes * 60)
        self.endTime = endTime.addingTimeInterval(additionalTime)
        remainingTime += additionalTime
    }
    
    private func updateTimer() {
        guard let endTime = endTime else {
            stop()
            return
        }
        
        remainingTime = endTime.timeIntervalSinceNow
        
        if remainingTime <= 0 {
            // Timer expired
            stop()
            
            // Pause playback
            AudioPlayerManager.shared.pause()
            
            // TODO: Show notification or alert
        }
    }
    
    /// Format remaining time for display
    var formattedRemainingTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = remainingTime >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: remainingTime) ?? "0:00"
    }
}
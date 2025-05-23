import SwiftUI
import AVFoundation

/// Compact player view that appears at the bottom of the app
struct MiniPlayerView: View {
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @State private var showingFullPlayer = false
    
    var body: some View {
        if playerManager.currentEpisode != nil {
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    // Artwork
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "headphones")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.2))
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Episode info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playerManager.currentEpisode?.title ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(playerManager.currentEpisode?.podcastTitle ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Play/Pause button
                    Button {
                        playerManager.togglePlayPause()
                    } label: {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(playerManager.isLoading)
                    
                    // Forward button
                    Button {
                        playerManager.skipForward(30)
                    } label: {
                        Image(systemName: "goforward.30")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                #if os(iOS)
                .background(Color(.secondarySystemBackground))
                #else
                .background(Color(NSColor.controlBackgroundColor))
                #endif
                .contentShape(Rectangle())
                .onTapGesture {
                    showingFullPlayer = true
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: progressWidth(in: geometry.size.width), height: 2)
                    }
                }
                .frame(height: 2)
            }
            .sheet(isPresented: $showingFullPlayer) {
                FullPlayerView()
            }
        }
    }
    
    private var artworkURL: URL? {
        if let urlString = playerManager.currentEpisode?.artworkURL {
            return URL(string: urlString)
        }
        return nil
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard playerManager.duration > 0 else { return 0 }
        return totalWidth * CGFloat(playerManager.currentTime / playerManager.duration)
    }
}

/// Full-screen player view
struct FullPlayerView: View {
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isDraggingSlider = false
    @State private var draggedTime: TimeInterval = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Artwork
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "headphones")
                            .font(.system(size: 80))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer(minLength: 20)
                
                // Episode info
                VStack(spacing: 8) {
                    Text(playerManager.currentEpisode?.title ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                    
                    Text(playerManager.currentEpisode?.podcastTitle ?? "")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 20)
                
                // Time and progress
                VStack(spacing: 8) {
                    // Slider
                    Slider(
                        value: Binding(
                            get: { isDraggingSlider ? draggedTime : playerManager.currentTime },
                            set: { newValue in
                                draggedTime = newValue
                                if !isDraggingSlider {
                                    playerManager.seek(to: newValue)
                                }
                            }
                        ),
                        in: 0...max(playerManager.duration, 1),
                        onEditingChanged: { editing in
                            isDraggingSlider = editing
                            if !editing {
                                playerManager.seek(to: draggedTime)
                            }
                        }
                    )
                    .tint(.accentColor)
                    
                    // Time labels
                    HStack {
                        Text(formatTime(isDraggingSlider ? draggedTime : playerManager.currentTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        
                        Spacer()
                        
                        Text(formatTime(playerManager.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 20)
                
                // Playback controls
                HStack(spacing: 40) {
                    // Backward
                    Button {
                        playerManager.skipBackward(15)
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    // Play/Pause
                    Button {
                        playerManager.togglePlayPause()
                    } label: {
                        Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(playerManager.isLoading)
                    
                    // Forward
                    Button {
                        playerManager.skipForward(30)
                    } label: {
                        Image(systemName: "goforward.30")
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 20)
                
                // Speed control
                HStack(spacing: 20) {
                    Image(systemName: "gauge")
                        .foregroundStyle(.secondary)
                    
                    Picker("Speed", selection: $playerManager.playbackRate) {
                        ForEach(playerManager.availableSpeeds, id: \.self) { speed in
                            Text(formatSpeed(speed))
                                .tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
            .navigationTitle("Now Playing")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var artworkURL: URL? {
        if let urlString = playerManager.currentEpisode?.artworkURL {
            return URL(string: urlString)
        }
        return nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = time >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: time) ?? "0:00"
    }
    
    private func formatSpeed(_ speed: Float) -> String {
        if speed == 1.0 {
            return "1×"
        } else {
            return String(format: "%.1g×", speed)
        }
    }
}

#Preview("Mini Player") {
    VStack {
        Spacer()
        MiniPlayerView()
    }
}

#Preview("Full Player") {
    FullPlayerView()
}
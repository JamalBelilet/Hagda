import SwiftUI

/// Type-specific view for podcast episodes
struct PodcastDetailView: View {
    let item: ContentItem
    @State private var viewModel: PodcastDetailViewModel
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @State private var showingSleepTimer = false
    @State private var showingSpeedPicker = false
    
    init(item: ContentItem) {
        self.item = item
        self._viewModel = State(initialValue: PodcastDetailViewModel(item: item))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Episode artwork
            ZStack(alignment: .bottomTrailing) {
                if viewModel.hasArtwork, let artworkURL = viewModel.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    } placeholder: {
                        artworkPlaceholder
                    }
                } else {
                    artworkPlaceholder
                }
                
                Text(viewModel.duration)
                    .font(.caption)
                    .padding(8)
                    #if os(iOS) || os(visionOS)
                    .background(.ultraThinMaterial)
                    #else
                    .background(Color.gray.opacity(0.15))
                    #endif
                    .cornerRadius(8)
                    .padding(12)
            }
            
            // Loading indicator
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
            
            // Error message
            if let error = viewModel.error {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("Could not load details")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                }
            }
            
            // Player controls
            VStack(spacing: 12) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            #if os(iOS) || os(visionOS)
                            .fill(Color(.systemGray5))
                            #else
                            .fill(Color.gray.opacity(0.2))
                            #endif
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(viewModel.progressPercentage), height: 4)
                            .cornerRadius(2)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                            .offset(x: geometry.size.width * CGFloat(viewModel.progressPercentage) - 7)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let percentage = value.location.x / geometry.size.width
                                        viewModel.progressPercentage = min(1.0, max(0.0, Double(percentage)))
                                        viewModel.currentTime = Int(Double(viewModel.totalTime) * viewModel.progressPercentage)
                                    }
                            )
                    }
                }
                .frame(height: 20)
                
                // Time indicators
                HStack {
                    Text(viewModel.formatTime(seconds: viewModel.currentTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("-\(viewModel.formatTime(seconds: viewModel.totalTime - viewModel.currentTime))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Control buttons
                HStack(spacing: 40) {
                    Button {
                        if isCurrentEpisode {
                            playerManager.skipBackward(15)
                        }
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 28))
                    }
                    .disabled(!isCurrentEpisode)
                    
                    Button {
                        if let episode = PodcastEpisode.fromContentItem(item) {
                            if isCurrentEpisode && playerManager.isPlaying {
                                playerManager.pause()
                            } else {
                                playerManager.play(episode: episode)
                            }
                        }
                    } label: {
                        Image(systemName: playButtonIcon)
                            .font(.system(size: 54))
                            .foregroundStyle(Color.accentColor)
                    }
                    .disabled(!canPlay)
                    
                    Button {
                        if isCurrentEpisode {
                            playerManager.skipForward(30)
                        }
                    } label: {
                        Image(systemName: "goforward.30")
                            .font(.system(size: 28))
                    }
                    .disabled(!isCurrentEpisode)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                
                // Playback options
                HStack(spacing: 40) {
                    Button {
                        // Download
                    } label: {
                        Image(systemName: "arrow.down.circle")
                    }
                    
                    Button {
                        showingSpeedPicker = true
                    } label: {
                        Text(formatSpeed(playerManager.playbackRate))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            #if os(iOS) || os(visionOS)
                            .background(Color(.secondarySystemBackground))
                            #else
                            .background(Color.gray.opacity(0.2))
                            #endif
                            .cornerRadius(6)
                    }
                    
                    Button {
                        showingSleepTimer = true
                    } label: {
                        Image(systemName: SleepTimer.shared.isActive ? "timer.circle.fill" : "timer")
                            .foregroundStyle(SleepTimer.shared.isActive ? Color.purple : .secondary)
                    }
                    
                    Button {
                        // Share
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 20)
            
            // Episode description
            Text("Episode Description")
                .font(.headline)
                .padding(.top, 4)
            
            Text(viewModel.description)
                .font(.body)
                .lineSpacing(5)
            
            // What's coming up next section
            if viewModel.progressPercentage > 0 {
                comingUpNextSection
            }
            
            // Episode notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Show Notes")
                    .font(.headline)
                    .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(viewModel.showNotes.enumerated()), id: \.offset) { index, note in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(note)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding()
                #if os(iOS) || os(visionOS)
                .background(Color(.secondarySystemBackground))
                #else
                .background(Color.gray.opacity(0.2))
                #endif
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingSleepTimer) {
            SleepTimerView()
                #if os(iOS)
                .presentationDetents([.medium])
                #endif
        }
        .sheet(isPresented: $showingSpeedPicker) {
            SpeedPickerView(selectedSpeed: $playerManager.playbackRate)
                #if os(iOS)
                .presentationDetents([.height(300)])
                #endif
        }
    }
    
    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            #if os(iOS) || os(visionOS)
            .fill(Color(.secondarySystemBackground))
            #else
            .fill(Color.gray.opacity(0.2))
            #endif
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Image(systemName: "headphones")
                    .font(.system(size: 50))
                    .foregroundStyle(.tertiary)
            )
    }
    
    private var comingUpNextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coming Up Next")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(viewModel.formatTime(seconds: viewModel.totalTime - viewModel.currentTime) + " remaining")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.remainingContentSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)
            }
            .padding()
            #if os(iOS) || os(visionOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color.gray.opacity(0.15))
            #endif
            .cornerRadius(10)
        }
    }
    
    // MARK: - Helper Properties
    
    private var isCurrentEpisode: Bool {
        if let currentId = playerManager.currentEpisode?.id,
           let episodeId = item.metadata["episodeGuid"] as? String {
            return currentId == episodeId
        }
        return false
    }
    
    private var playButtonIcon: String {
        if isCurrentEpisode && playerManager.isPlaying {
            return "pause.circle.fill"
        } else {
            return "play.circle.fill"
        }
    }
    
    private var canPlay: Bool {
        return item.metadata["audioUrl"] as? String != nil
    }
    
    private func formatSpeed(_ speed: Float) -> String {
        if speed == 1.0 {
            return "1×"
        } else {
            return String(format: "%.1g×", speed)
        }
    }
}

// MARK: - Preview

#Preview("Podcast") {
    PodcastDetailView(item: ContentItem(
        title: "Episode 245: The State of Modern Development",
        subtitle: "45 minutes • Interview",
        date: Date().addingTimeInterval(-3600 * 36), // 1.5 days ago
        type: .podcast,
        contentPreview: """
        In this episode, we dive deep into technology trends that are shaping our digital landscape. Our host interviews industry experts about their insights on emerging technologies, development practices, and predictions for the future.
        
        Topics covered include:
        
        • Artificial intelligence and machine learning applications
        • Development frameworks and best practices
        • The changing patterns in how we consume digital content
        • Future predictions for technology evolution
        """,
        progressPercentage: 0.35
    ))
}
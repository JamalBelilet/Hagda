import SwiftUI

struct SleepTimerView: View {
    @ObservedObject var sleepTimer = SleepTimer.shared
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if sleepTimer.isActive {
                    activeTimerView
                } else {
                    timerSelectionView
                }
            }
            .navigationTitle("Sleep Timer")
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
    
    private var activeTimerView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            Text("Sleep Timer Active")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(sleepTimer.formattedRemainingTime)
                .font(.system(size: 48, weight: .medium, design: .rounded))
                .monospacedDigit()
            
            Text("Playback will pause when timer ends")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 20) {
                Button {
                    sleepTimer.extend(by: 5)
                } label: {
                    Label("+5 min", systemImage: "plus.circle")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                
                Button {
                    sleepTimer.stop()
                } label: {
                    Label("Cancel Timer", systemImage: "xmark.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.top)
        }
        .padding(.vertical, 40)
    }
    
    private var timerSelectionView: some View {
        List {
            Section {
                ForEach(sleepTimer.presetDurations, id: \.seconds) { preset in
                    Button {
                        if preset.seconds > 0 {
                            sleepTimer.start(duration: preset.seconds)
                        } else {
                            sleepTimer.startUntilEndOfEpisode()
                        }
                        dismiss()
                    } label: {
                        timerPresetRow(preset: preset)
                    }
                    .buttonStyle(.plain)
                    .disabled(preset.seconds < 0 && playerManager.currentEpisode == nil)
                }
            } header: {
                Text("Set Sleep Timer")
            } footer: {
                Text("Playback will automatically pause when the timer ends.")
            }
        }
    }
    
    private func timerPresetRow(preset: (label: String, seconds: TimeInterval)) -> some View {
        HStack {
            Label(preset.label, systemImage: iconForDuration(preset.seconds))
                .foregroundStyle(.primary)
            
            Spacer()
            
            if preset.seconds == sleepTimer.selectedDuration {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
    }
    
    private func iconForDuration(_ seconds: TimeInterval) -> String {
        switch seconds {
        case 0...600: return "moon.zzz"
        case 601...1800: return "moon.zzz.fill"
        case 1801...3600: return "moon.stars"
        case -1: return "music.note"
        default: return "moon.circle"
        }
    }
}

#Preview {
    SleepTimerView()
}
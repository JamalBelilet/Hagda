import SwiftUI

struct SpeedPickerView: View {
    @Binding var selectedSpeed: Float
    @Environment(\.dismiss) private var dismiss
    
    let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    
    var body: some View {
        NavigationStack {
            List(speeds, id: \.self) { speed in
                Button {
                    selectedSpeed = speed
                    AudioPlayerManager.shared.setPlaybackRate(speed)
                    dismiss()
                } label: {
                    HStack {
                        Text(formatSpeed(speed))
                            .font(.title3)
                        
                        Spacer()
                        
                        if speed == selectedSpeed {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Playback Speed")
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
    
    private func formatSpeed(_ speed: Float) -> String {
        if speed == 1.0 {
            return "Normal (1×)"
        } else if speed < 1.0 {
            return String(format: "%.2g× (Slower)", speed)
        } else {
            return String(format: "%.2g× (Faster)", speed)
        }
    }
}

#Preview {
    SpeedPickerView(selectedSpeed: .constant(1.0))
}
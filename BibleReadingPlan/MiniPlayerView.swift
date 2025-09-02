import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var audioManager = AudioPlayerEngine.shared
    @Binding var showFullPlayer: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                // Safely get current track
                if let current = audioManager.virtualTracks[safe: audioManager.currentVirtualTrackIndex] {
                    Text(current.title)
                        .font(.subheadline)
                        .bold()
                    
                    // Progress relative to current track
                    let trackProgress = max(min((audioManager.currentTime - current.startTime) / (current.endTime - current.startTime), 1.0), 0.0)
                    ProgressView(value: trackProgress)
                } else {
                    Text("No Track")
                        .font(.subheadline)
                        .bold()
                    ProgressView(value: 0)
                }
            }
            
            Spacer()
            
            Button {
                audioManager.togglePlayPause()
            } label: {
                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
        .onTapGesture {
            showFullPlayer = true
        }
    }
}

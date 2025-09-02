import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var audioManager = AudioPlayerEngine.shared
    @Binding var showFullPlayer: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                let current = audioManager.virtualTracks[audioManager.currentVirtualTrackIndex]
                    Text(current.title).font(.subheadline).bold()
                
                ProgressView(value: min(audioManager.duration == 0 ? 0 : audioManager.currentTime / max(audioManager.duration, 0.01), 1.0))
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

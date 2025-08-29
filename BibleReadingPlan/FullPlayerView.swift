import SwiftUI

struct FullPlayerView: View {
    @ObservedObject var audioManager = AudioPlayerManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            let title = audioManager.virtualTracks[audioManager.currentVirtualTrackIndex].title
            Text(title).font(.title).bold().padding(EdgeInsets.init(top: 20, leading: 0, bottom: 0, trailing: 0))
            

            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { audioManager.currentTime },
                    set: { newVal in audioManager.seekBy(audioManager.trackStartTime + newVal) }
                ), in: 0...max(audioManager.duration, 0.01))
                
                HStack {
                    Text(formatTime(audioManager.currentTime))
                    Spacer()
                    Text(formatTime(audioManager.duration))
                }
                .font(.caption)
                .monospacedDigit()
            }
            .padding(.horizontal)

            HStack(spacing: 40) {
                Button { audioManager.seekBy(-15) } label: {
                    Image(systemName: "gobackward.15").font(.system(size: 40))
                }
                Button { audioManager.togglePlayPause() } label: {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                }
                Button { audioManager.seekBy(15) } label: {
                    Image(systemName: "goforward.15").font(.system(size: 40))
                }
            }
            .padding(.top, 8)

            // Playback Speed Picker
            VStack(spacing: 8) {
                Text("Speed").font(.headline)
                Picker("Speed", selection: $audioManager.playbackRate) {
                    Text("1x").tag(Float(1.0))
                    Text("1.1x").tag(Float(1.1))
                    Text("1.2x").tag(Float(1.2))
                    Text("1.5x").tag(Float(1.5))
                }
                .pickerStyle(.segmented)
                .onChange(of: audioManager.playbackRate) { newRate in
                    audioManager.setRate(newRate)
                }
            }
            .padding(.horizontal)

            VirtualQueueView()
                .frame(maxHeight: 200)

            Spacer()
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

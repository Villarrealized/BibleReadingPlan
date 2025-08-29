import SwiftUI

struct VirtualQueueView: View {
    @ObservedObject var audioManager = AudioPlayerManager.shared
    
    var body: some View {
        List(audioManager.virtualTracks.indices, id: \.self) { index in
            let track = audioManager.virtualTracks[index]
            HStack {
                Text(track.title)
                Spacer()
                if index == audioManager.currentVirtualTrackIndex {
                    Image(systemName: "speaker.wave.2.fill").foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                audioManager.playVirtualTrack(at: index)
            }
        }
    }
}

import SwiftUI

struct VirtualQueueView: View {
    var onSelect: (Int) -> Void
    
    @ObservedObject var manager = AudioPlayerEngine.shared
    
    var body: some View {
        List(manager.virtualTracks.indices, id: \.self) { index in
            let track = manager.virtualTracks[index]
            HStack {
                Text(track.title)
                    .foregroundColor(manager.currentVirtualTrackIndex == index ? .blue : .primary)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect(index)
            }
        }
        .listStyle(PlainListStyle())
    }
}

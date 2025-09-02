import SwiftUI

struct FullPlayerView: View {
    @StateObject var manager = AudioPlayerEngine.shared
    
    var body: some View {
        VStack(spacing: 16) {
            
            // MARK: Track Title
            if let track = manager.virtualTracks[safe: manager.currentVirtualTrackIndex] {
                Text(track.title)
                    .font(.title)
                    .bold()
                    .padding(.top, 20)
            }
            
            // MARK: Slider & Time
            VStack(spacing: 8) {
                if let track = manager.virtualTracks[safe: manager.currentVirtualTrackIndex] {
                    let trackDuration = track.endTime - track.startTime
                    
                    Slider(
                        value: Binding(
                            get: { manager.currentTime - track.startTime },
                            set: { newVal in
                                manager.scrub(to: track.startTime + newVal)
                            }
                        ),
                        in: 0...max(trackDuration, 0.01),
                        onEditingChanged: { editing in
                            if !editing {
                                manager.commitScrub(to: manager.currentTime)
                            }
                        }
                    )
                    
                    HStack {
                        Text(formatTime(manager.currentTime - track.startTime))
                        Spacer()
                        Text(formatTime(trackDuration))
                    }
                    .font(.caption)
                    .monospacedDigit()
                }
            }
            .padding(.horizontal)
            
            // MARK: Playback Controls
            HStack(spacing: 40) {
                Button { seekBy(-15) } label: {
                    Image(systemName: "gobackward.15").font(.system(size: 40))
                }
                
                Button { manager.togglePlayPause() } label: {
                    Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                }
                
                Button { seekBy(15) } label: {
                    Image(systemName: "goforward.15").font(.system(size: 40))
                }
            }
            .padding(.top, 8)
            
            // MARK: Playback Speed Picker
            VStack(spacing: 8) {
                Text("Speed").font(.headline)
                
                Picker("Speed", selection: Binding(
                    get: { speedTag(from: manager.playbackRate) },
                    set: { newValue in
                        manager.setRate(rateFromTag(newValue))
                    }
                )) {
                    Text("1x").tag(1)
                    Text("1.1x").tag(11)
                    Text("1.2x").tag(12)
                    Text("1.5x").tag(15)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            
            // MARK: Queue View
            VirtualQueueView { index in
                manager.selectTrack(at: index) // fixed skipping bug
            }
            .frame(maxHeight: 400)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: Helpers
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func seekBy(_ delta: TimeInterval) {
        guard let track = manager.virtualTracks[safe: manager.currentVirtualTrackIndex] else { return }
        let newTime = min(max(manager.currentTime + delta, track.startTime), track.endTime)
        manager.seekTo(time: newTime)
    }
    
    private func speedTag(from rate: Float) -> Int {
        switch rate {
        case 1.0: return 1
        case 1.1: return 11
        case 1.2: return 12
        case 1.5: return 15
        default: return 1
        }
    }
    
    private func rateFromTag(_ tag: Int) -> Float {
        switch tag {
        case 1: return 1.0
        case 11: return 1.1
        case 12: return 1.2
        case 15: return 1.5
        default: return 1.0
        }
    }
}

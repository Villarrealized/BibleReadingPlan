import SwiftUI
import AVFoundation
import MediaPlayer
import UIKit

struct VirtualTrack: Identifiable {
    let id = UUID()
    let title: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}


final class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()
    
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackRate: Float = 1.0
    @Published var currentVirtualTrackIndex: Int = 0
    @Published var trackEndTime: TimeInterval = 0
    @Published var trackStartTime: TimeInterval = 0
    
    var virtualTracks: [VirtualTrack] = []
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    
  
    
    // MARK: - Load file
    func loadLargeFile(url: URL, tracks: [VirtualTrack]) {
        player = AVPlayer(url: url)
        virtualTracks = tracks
        addPeriodicTimeObserver()
    }
    
    // MARK: - Play a virtual track
    func playVirtualTrack(at index: Int) {
        guard virtualTracks.indices.contains(index), let player = player else { return }
        
        currentVirtualTrackIndex = index
        let track = virtualTracks[index]
        
        trackStartTime = track.startTime
        trackEndTime = track.endTime
        duration = trackEndTime - trackStartTime
        
        player.seek(to: CMTime(seconds: trackStartTime, preferredTimescale: 600))
        player.rate = playbackRate
        player.play()
        isPlaying = true
        
        addPeriodicTimeObserver()
        
        // Automatically stop or advance when reaching track end
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            if self.currentVirtualTrackIndex == index {
                self.isPlaying = false
                self.currentTime = self.duration
                let nextIndex = index + 1
                if self.virtualTracks.indices.contains(nextIndex) {
                    self.playVirtualTrack(at: nextIndex)
                }
            }
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.rate = playbackRate
        }
        isPlaying.toggle()
    }
    
    func seekBy(_ seconds: Double) {
        guard let player = player else { return }
        let target = max(player.currentTime().seconds + seconds, 0)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }
    
    func setRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }
    
    // MARK: - Time observer
    private func addPeriodicTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = min(time.seconds - self.trackStartTime, self.duration)
        }
    }
}


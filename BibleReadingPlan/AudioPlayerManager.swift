//import SwiftUI
//import AVFoundation
//
//struct VirtualTrack: Identifiable {
//    let id = UUID()
//    let title: String
//    let startTime: TimeInterval
//    let endTime: TimeInterval
//}
//
//final class AudioPlayerEngine: ObservableObject {
//    static let shared = AudioPlayerEngine()
//    
//    @Published var isPlaying = false
//    @Published var currentTime: TimeInterval = 0
//    @Published var duration: TimeInterval = 0
//    @Published var playbackRate: Float = 1.0
//    @Published var currentVirtualTrackIndex: Int = 0
//    @Published var virtualTracks: [VirtualTrack] = []
//    
//    private var trackStartTime: TimeInterval = 0
//    private var trackEndTime: TimeInterval = 0
//    private var player: AVPlayer?
//    private var timeObserverToken: Any?
//    
//    // MARK: - Load file and preload asset
//    func loadLargeFile(url: URL, tracks: [VirtualTrack]) {
//        virtualTracks = tracks
//        
//        let asset = AVAsset(url: url)
//        let keys = ["duration", "playable"]
//        
//        print("Preloading asset...")
//        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
//            guard let self = self else { return }
//            for key in keys {
//                var error: NSError?
//                let status = asset.statusOfValue(forKey: key, error: &error)
//                if status != .loaded {
//                    print("Failed to load key \(key): \(String(describing: error))")
//                    return
//                }
//            }
//            print("Asset loaded. Duration: \(asset.duration.seconds)")
//            
//            let item = AVPlayerItem(asset: asset)
//            DispatchQueue.main.async {
//                self.player = AVPlayer(playerItem: item)
//                self.addPeriodicTimeObserver()
//            }
//        }
//    }
//    
//    // MARK: - Play virtual track with logging
//    func playVirtualTrack(at index: Int) {
//        guard virtualTracks.indices.contains(index), let player = player else { return }
//        
//        currentVirtualTrackIndex = index
//        let track = virtualTracks[index]
//        
//        trackStartTime = track.startTime
//        trackEndTime = track.endTime
//        duration = trackEndTime - trackStartTime
//        
//        let cmTime = CMTime(seconds: trackStartTime, preferredTimescale: 1_000_000)
//        print("[PlayTrack] Seeking to \(trackStartTime) seconds (CMTime: \(cmTime))")
//        
//        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
//            guard let self = self else { return }
//            print("[PlayTrack] Seek finished? \(finished), actual player time: \(self.player?.currentTime().seconds ?? -1)")
//            self.player?.rate = self.playbackRate
//            self.player?.play()
//            self.isPlaying = true
//            print("[PlayTrack] Playback started at \(self.player?.currentTime().seconds ?? -1)")
//        }
//    }
//    
//    // MARK: - Absolute seek within current track
//    func seekToTrackPosition(_ seconds: Double) {
//        guard let player = player else { return }
//        let targetTime = trackStartTime + seconds
//        print("[Seek] Slider seek to \(seconds) (absolute: \(targetTime))")
//        
//        player.seek(to: CMTime(seconds: targetTime, preferredTimescale: 1_000_000),
//                    toleranceBefore: .zero,
//                    toleranceAfter: .zero) { finished in
//            print("[Seek] Finished? \(finished), player time: \(self.player?.currentTime().seconds ?? -1)")
//        }
//    }
//    
//    // MARK: - Relative seek (e.g., +15/-15 seconds)
//    func seekBy(_ seconds: Double) {
//        guard let player = player else { return }
//        let target = max(player.currentTime().seconds + seconds, 0)
//        print("[SeekBy] Seeking by \(seconds), target: \(target)")
//        player.seek(to: CMTime(seconds: target, preferredTimescale: 1_000_000),
//                    toleranceBefore: .zero,
//                    toleranceAfter: .zero)
//    }
//    
//    func setRate(_ rate: Float) {
//        playbackRate = rate
//        if isPlaying {
//            player?.rate = rate
//            print("[Rate] Playback rate changed to \(rate)")
//        }
//    }
//    
//    func togglePlayPause() {
//        guard let player = player else { return }
//        if isPlaying {
//            player.pause()
//            print("[PlayPause] Paused at \(player.currentTime().seconds)")
//        } else {
//            player.rate = playbackRate
//            print("[PlayPause] Resumed at \(player.currentTime().seconds)")
//        }
//        isPlaying.toggle()
//    }
//    
//    // MARK: - Periodic observer with logging
//    private func addPeriodicTimeObserver() {
//        guard let player = player, timeObserverToken == nil else { return }
//        
//        let interval = CMTime(seconds: 0.1, preferredTimescale: 1_000)
//        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
//            guard let self = self else { return }
//            let elapsed = time.seconds - self.trackStartTime
//            self.currentTime = max(0, elapsed)
//            
//            print("[Observer] player time: \(time.seconds), elapsed: \(elapsed), trackEnd: \(self.trackEndTime)")
//            
//            if time.seconds >= self.trackEndTime {
//                self.player?.pause()
//                self.isPlaying = false
//                self.currentTime = self.duration
//                print("[Observer] Track ended, moving to next if exists")
//                self.playNextTrackIfExists()
//            }
//        }
//    }
//    
//    private func playNextTrackIfExists() {
//        let nextIndex = currentVirtualTrackIndex + 1
//        if virtualTracks.indices.contains(nextIndex) {
//            print("[NextTrack] Advancing to track \(nextIndex)")
//            playVirtualTrack(at: nextIndex)
//        }
//    }
//    
//    deinit {
//        if let token = timeObserverToken {
//            player?.removeTimeObserver(token)
//        }
//    }
//}

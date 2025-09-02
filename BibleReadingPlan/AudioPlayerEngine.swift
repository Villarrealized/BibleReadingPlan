import Foundation
import AVFoundation
import Combine
import MediaPlayer


struct VirtualTrack: Identifiable {
    let id = UUID()
    let title: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}

struct ChapterJSON: Codable {
    let id: Int
    let start: Double
    let end: Double
    let name: String
}

func loadAllChapters() -> [ChapterJSON] {
    guard let url = Bundle.main.url(forResource: "chapters", withExtension: "json") else {
        print("chapters.json not found")
        return []
    }
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([ChapterJSON].self, from: data)
    } catch {
        print("Error decoding chapters.json: \(error)")
        return []
    }
}


func loadTracksForToday(todayBuckets: [ReadingBucket]) -> [VirtualTrack] {
    let allChapters = loadAllChapters()
    var tracks: [VirtualTrack] = []
    
    for bucket in todayBuckets {
        // For each bucket, select chapters that match bookName and chapter number range
        let matchingChapters = allChapters.filter { chapter in
            chapter.name.starts(with: bucket.bookName) &&
            // Extract chapter number from name, e.g., "Genesis 3" -> 3
            (Int(chapter.name.components(separatedBy: " ").last ?? "") ?? 0) >= bucket.startChapter &&
            (Int(chapter.name.components(separatedBy: " ").last ?? "") ?? 0) <= bucket.endChapter
        }
        // Convert to VirtualTrack
        let bucketTracks = matchingChapters.map { chapter in
            VirtualTrack(title: chapter.name, startTime: chapter.start, endTime: chapter.end)
        }
        tracks.append(contentsOf: bucketTracks)
    }
    
    return tracks
}


final class AudioPlayerEngine: ObservableObject {
    static let shared = AudioPlayerEngine()
    
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var currentVirtualTrackIndex: Int = 0
    @Published var playbackRate: Float = 1.0
    @Published var isUserScrubbing = false
    @Published var totalDurationForToday: Double = 0
    
    private(set) var isLoaded = false
    var virtualTracks: [VirtualTrack] = []
    
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var timePitch = AVAudioUnitTimePitch()
    private var audioFile: AVAudioFile?
    private var timer: Timer?
    private var isScheduling = false
    private var trackToken = 0
    
    // MARK: - Current track helper
    private var currentTrack: VirtualTrack? {
        virtualTracks[safe: currentVirtualTrackIndex]
    }
    
    private init() {
        setupEngine()
        setupRemoteCommandCenter()
    }
    
    private func setupEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(timePitch)
        audioEngine.connect(playerNode, to: timePitch, format: nil)
        audioEngine.connect(timePitch, to: audioEngine.mainMixerNode, format: nil)
        try? audioEngine.start()
    }
    
    // MARK: - Load file
    func loadLargeFile(url: URL, tracks: [VirtualTrack]) throws {
        guard !isLoaded else { return }
        audioFile = try AVAudioFile(forReading: url)
        virtualTracks = tracks
        duration = audioFile?.duration ?? 0
        currentTime = 0
        self.isLoaded = true
    }
    
    // MARK: - Play virtual track
    func playVirtualTrack(at index: Int, from time: TimeInterval? = nil) {
        guard !isScheduling else { return }
        guard let file = audioFile, virtualTracks.indices.contains(index) else { return }
        
        isScheduling = true
        defer { isScheduling = false }
        
        // Stop any previous playback
        stop()
        
        // Ensure the engine is running
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
        
        // Update current track info
        currentVirtualTrackIndex = index
        trackToken += 1
        let currentToken = trackToken
        
        let track = virtualTracks[index]
        let startTime = time ?? track.startTime
        
        let startFrame = AVAudioFramePosition(startTime * file.fileFormat.sampleRate)
        let lengthFrames = AVAudioFrameCount((track.endTime - startTime) * file.fileFormat.sampleRate)
        
        // Schedule the segment
        playerNode.scheduleSegment(file, startingFrame: startFrame, frameCount: lengthFrames, at: nil) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard currentToken == self.trackToken else { return }
                
                self.isPlaying = false
                self.currentTime = track.endTime
                
                // Auto-advance to next track
                let nextIndex = index + 1
                if self.virtualTracks.indices.contains(nextIndex) {
                    self.playVirtualTrack(at: nextIndex)
                }
            }
        }
        
        // Apply playback rate
        timePitch.rate = playbackRate
        
        // Play node
        playerNode.play()
        isPlaying = true
        
        // Start timer after a tiny delay to sync with actual audio rendering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.startTimer(trackStartTime: startTime)
        }
    }

    
    func selectTrack(at index: Int) {
        guard virtualTracks.indices.contains(index) else { return }
        trackToken += 1
        playVirtualTrack(at: index)
    }
    
    // MARK: - Timer
    private func startTimer(trackStartTime: TimeInterval) {
        stopTimer()
        guard let track = currentTrack else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard !self.isUserScrubbing else { return }
            
            if let nodeTime = self.playerNode.lastRenderTime,
               let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) {
                let time = trackStartTime + Double(playerTime.sampleTime) / playerTime.sampleRate
                self.currentTime = min(time, track.endTime)
                
                self.updateNowPlayingInfo()
                
                if self.currentTime >= track.endTime {
                    self.stopTimer()
                    self.playerNode.stop()
                    self.isPlaying = false
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Control
    func stop() {
        playerNode.stop()
        stopTimer()
        isPlaying = false
        updateNowPlayingInfo()
    }
    
    func togglePlayPause() {
        if isPlaying {
            playerNode.pause()
            stopTimer()
            isPlaying = false
        } else {
            if !playerNode.isPlaying && !virtualTracks.isEmpty {
                let currentIndex = currentVirtualTrackIndex
                playVirtualTrack(at: currentIndex, from: currentTime)
            } else {
                playerNode.play()
                startTimer(trackStartTime: currentTrack?.startTime ?? 0)
                isPlaying = true
            }
        }
        updateNowPlayingInfo()
    }
    
    func setRate(_ rate: Float) {
        playbackRate = rate
        timePitch.rate = rate
        if isPlaying { playerNode.play() }
        updateNowPlayingInfo()
    }
    
    func seekTo(time: TimeInterval) {
        guard let track = currentTrack else { return }
        let clampedTime = min(max(time, track.startTime), track.endTime)
        playVirtualTrack(at: currentVirtualTrackIndex, from: clampedTime)
        updateNowPlayingInfo()
    }
    
    func seekBy(_ delta: TimeInterval) {
        guard let track = currentTrack else { return }
        let newTime = min(max(currentTime + delta, track.startTime), track.endTime)
        seekTo(time: newTime)
    }
    
    func scrub(to time: TimeInterval) {
        guard let track = currentTrack else { return }
        isUserScrubbing = true
        currentTime = min(max(time, track.startTime), track.endTime)
        updateNowPlayingInfo()
    }
    
    func commitScrub(to time: TimeInterval) {
        guard let track = currentTrack else { return }
        isUserScrubbing = false
        let clampedTime = min(max(time, track.startTime), track.endTime)
        seekTo(time: clampedTime)
    }
    
    func updateTracks(for todayBuckets: [ReadingBucket]) {
        let tracks = loadTracksForToday(todayBuckets: todayBuckets)
        self.totalDurationForToday = tracks.map { $0.endTime - $0.startTime }.reduce(0, +)
        virtualTracks = tracks
        if !tracks.isEmpty {
            currentVirtualTrackIndex = 0
            currentTime = tracks[0].startTime
        } else {
            currentVirtualTrackIndex = 0
            currentTime = 0
        }
        updateNowPlayingInfo()
    }
    
    // MARK: - Now Playing Info
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.endTime - track.startTime
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.playerNode.play()
            self?.isPlaying = true
            self?.updateNowPlayingInfo()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.playerNode.pause()
            self?.isPlaying = false
            self?.updateNowPlayingInfo()
            return .success
        }
        
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
    }
}



// Array safe index extension
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// AVAudioFile duration extension
extension AVAudioFile {
    var duration: Double {
        Double(length) / fileFormat.sampleRate
    }
}

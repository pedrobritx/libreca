import Foundation
import AVFoundation
import Combine
import SpectraCore

/// AVPlayer-based playback engine
@MainActor
public final class PlayerEngine: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var playbackInfo: PlaybackInfo = .initial
    @Published public private(set) var player: AVPlayer?
    
    /// Convenience accessor for playing state
    public var isPlaying: Bool {
        playbackInfo.state == .playing
    }
    
    // MARK: - Private
    
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var statusObservation: NSKeyValueObservation?
    private var rateObservation: NSKeyValueObservation?
    private var bufferObservation: NSKeyValueObservation?
    
    // Channel navigation
    private var channelList: [String] = []
    private var currentChannelIndex: Int = 0
    public var onChannelChange: ((String) -> URL?)?
    
    // MARK: - Init
    
    public init() {
        setupAudioSession()
    }
    
    // Note: cleanup is called explicitly via stop() before deallocation
    // deinit can't access @MainActor properties
    
    // MARK: - Public API
    
    /// Load and play a stream
    public func play(channelId: String, url: URL) {
        cleanup()
        
        playbackInfo = PlaybackInfo(
            channelId: channelId,
            streamURL: url,
            state: .loading
        )
        
        // Create player item with optimized settings
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 5 // Optimize for live
        
        self.playerItem = playerItem
        
        // Create player
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = true
        
        #if os(tvOS)
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        #endif
        
        self.player = player
        
        // Setup observers
        setupObservers(player: player, item: playerItem)
        
        // Start playback
        player.play()
    }
    
    /// Resume playback
    public func resume() {
        player?.play()
        if playbackInfo.state == .paused {
            playbackInfo.state = .playing
        }
    }
    
    /// Pause playback
    public func pause() {
        player?.pause()
        if playbackInfo.state == .playing {
            playbackInfo.state = .paused
        }
    }
    
    /// Toggle play/pause
    public func togglePlayPause() {
        if playbackInfo.state == .playing {
            pause()
        } else {
            resume()
        }
    }
    
    /// Stop and cleanup
    public func stop() {
        cleanup()
        playbackInfo = .initial
    }
    
    /// Seek forward by seconds
    public func seekForward(_ seconds: TimeInterval) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 1))
        player.seek(to: newTime)
    }
    
    /// Seek backward by seconds
    public func seekBackward(_ seconds: TimeInterval) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: seconds, preferredTimescale: 1))
        player.seek(to: newTime)
    }
    
    /// Seek to specific time
    public func seekTo(_ time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 1))
    }
    
    /// Set volume (0.0 - 1.0)
    public func setVolume(_ volume: Float) {
        player?.volume = max(0, min(1, volume))
        playbackInfo.volume = volume
    }
    
    /// Toggle mute
    public func toggleMute() {
        let newMuted = !playbackInfo.isMuted
        player?.isMuted = newMuted
        playbackInfo.isMuted = newMuted
    }
    
    /// Set the channel list for navigation
    public func setChannelList(_ channels: [String]) {
        self.channelList = channels
        if let currentId = playbackInfo.channelId,
           let index = channels.firstIndex(of: currentId) {
            currentChannelIndex = index
        }
    }
    
    /// Switch to next channel
    public func nextChannel() {
        guard !channelList.isEmpty else { return }
        currentChannelIndex = (currentChannelIndex + 1) % channelList.count
        playChannel(at: currentChannelIndex)
    }
    
    /// Switch to previous channel
    public func previousChannel() {
        guard !channelList.isEmpty else { return }
        currentChannelIndex = (currentChannelIndex - 1 + channelList.count) % channelList.count
        playChannel(at: currentChannelIndex)
    }
    
    /// Retry current stream
    public func retry() {
        guard let channelId = playbackInfo.channelId,
              let url = playbackInfo.streamURL else { return }
        play(channelId: channelId, url: url)
    }
    
    /// Handle player action
    public func handle(_ action: PlayerAction) {
        switch action {
        case .play(let channelId, let url):
            play(channelId: channelId, url: url)
        case .resume:
            resume()
        case .pause:
            pause()
        case .stop:
            stop()
        case .seekForward(let seconds):
            seekForward(seconds)
        case .seekBackward(let seconds):
            seekBackward(seconds)
        case .seekTo(let time):
            seekTo(time)
        case .setVolume(let volume):
            setVolume(volume)
        case .toggleMute:
            toggleMute()
        case .nextChannel:
            nextChannel()
        case .previousChannel:
            previousChannel()
        case .retry:
            retry()
        }
    }
    
    // MARK: - Private
    
    private func playChannel(at index: Int) {
        let channelId = channelList[index]
        guard let url = onChannelChange?(channelId) else { return }
        play(channelId: channelId, url: url)
    }
    
    private func setupAudioSession() {
        #if os(iOS) || os(tvOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    private func setupObservers(player: AVPlayer, item: AVPlayerItem) {
        // Status observation
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.handleStatusChange(item.status, error: item.error)
            }
        }
        
        // Rate observation for play/pause detection
        rateObservation = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
            Task { @MainActor in
                self?.handleRateChange(player.rate)
            }
        }
        
        // Buffer observation
        bufferObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                if item.isPlaybackBufferEmpty && self?.playbackInfo.state == .playing {
                    self?.playbackInfo.state = .buffering
                }
            }
        }
        
        // Time observation
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.handleTimeUpdate(time)
            }
        }
        
        // Playback ended notification
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { [weak self] _ in
                self?.playbackInfo.state = .ended
            }
            .store(in: &cancellables)
        
        // Playback failed notification
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: item)
            .sink { [weak self] notification in
                if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
                    self?.playbackInfo.state = .failed(PlayerError.from(nsError: error))
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleStatusChange(_ status: AVPlayerItem.Status, error: Error?) {
        switch status {
        case .readyToPlay:
            playbackInfo.state = .playing
            
            // Check if live stream
            if let duration = playerItem?.duration, duration.isIndefinite {
                playbackInfo.isLive = true
                playbackInfo.duration = nil
            } else if let duration = playerItem?.duration {
                playbackInfo.isLive = false
                playbackInfo.duration = CMTimeGetSeconds(duration)
            }
            
        case .failed:
            if let error = error as NSError? {
                playbackInfo.state = .failed(PlayerError.from(nsError: error))
            } else {
                playbackInfo.state = .failed(.unknown(""))
            }
            
        case .unknown:
            break
            
        @unknown default:
            break
        }
    }
    
    private func handleRateChange(_ rate: Float) {
        if rate > 0 && playbackInfo.state != .playing && playbackInfo.state != .loading {
            playbackInfo.state = .playing
        } else if rate == 0 && playbackInfo.state == .playing {
            playbackInfo.state = .paused
        }
    }
    
    private func handleTimeUpdate(_ time: CMTime) {
        playbackInfo.currentTime = CMTimeGetSeconds(time)
        
        // Update buffered time
        if let loadedRanges = playerItem?.loadedTimeRanges,
           let firstRange = loadedRanges.first?.timeRangeValue {
            let bufferedEnd = CMTimeGetSeconds(CMTimeAdd(firstRange.start, firstRange.duration))
            playbackInfo.bufferedTime = bufferedEnd
        }
    }
    
    private func cleanup() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        
        statusObservation?.invalidate()
        statusObservation = nil
        
        rateObservation?.invalidate()
        rateObservation = nil
        
        bufferObservation?.invalidate()
        bufferObservation = nil
        
        cancellables.removeAll()
        
        player?.pause()
        player = nil
        playerItem = nil
    }
}

import Foundation

/// Current state of the player
public enum PlaybackState: Sendable, Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case buffering
    case ended
    case failed(PlayerError)
    
    public var isActive: Bool {
        switch self {
        case .playing, .buffering:
            return true
        default:
            return false
        }
    }
    
    public var canPlay: Bool {
        switch self {
        case .ready, .paused, .ended:
            return true
        default:
            return false
        }
    }
    
    public var error: PlayerError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
}

/// Information about the current playback session
public struct PlaybackInfo: Sendable, Equatable {
    public var channelId: String?
    public var streamURL: URL?
    public var state: PlaybackState
    public var duration: TimeInterval?
    public var currentTime: TimeInterval
    public var bufferedTime: TimeInterval
    public var isLive: Bool
    public var volume: Float
    public var isMuted: Bool
    
    public init(
        channelId: String? = nil,
        streamURL: URL? = nil,
        state: PlaybackState = .idle,
        duration: TimeInterval? = nil,
        currentTime: TimeInterval = 0,
        bufferedTime: TimeInterval = 0,
        isLive: Bool = true,
        volume: Float = 1.0,
        isMuted: Bool = false
    ) {
        self.channelId = channelId
        self.streamURL = streamURL
        self.state = state
        self.duration = duration
        self.currentTime = currentTime
        self.bufferedTime = bufferedTime
        self.isLive = isLive
        self.volume = volume
        self.isMuted = isMuted
    }
    
    public static let initial = PlaybackInfo()
}

/// Actions that can be performed on the player
public enum PlayerAction: Sendable {
    case play(channelId: String, url: URL)
    case resume
    case pause
    case stop
    case seekForward(seconds: TimeInterval)
    case seekBackward(seconds: TimeInterval)
    case seekTo(time: TimeInterval)
    case setVolume(Float)
    case toggleMute
    case nextChannel
    case previousChannel
    case retry
}

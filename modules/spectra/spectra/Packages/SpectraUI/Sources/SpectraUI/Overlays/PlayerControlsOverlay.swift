import SwiftUI

/// Player controls overlay
public struct PlayerControlsOverlay: View {
    public let isPlaying: Bool
    public let isLive: Bool
    public let currentTime: TimeInterval
    public let duration: TimeInterval?
    public let channelName: String
    public let onPlayPause: () -> Void
    public let onPrevious: () -> Void
    public let onNext: () -> Void
    public let onSeekBackward: () -> Void
    public let onSeekForward: () -> Void
    
    public init(
        isPlaying: Bool,
        isLive: Bool = true,
        currentTime: TimeInterval = 0,
        duration: TimeInterval? = nil,
        channelName: String,
        onPlayPause: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onSeekBackward: @escaping () -> Void = {},
        onSeekForward: @escaping () -> Void = {}
    ) {
        self.isPlaying = isPlaying
        self.isLive = isLive
        self.currentTime = currentTime
        self.duration = duration
        self.channelName = channelName
        self.onPlayPause = onPlayPause
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onSeekBackward = onSeekBackward
        self.onSeekForward = onSeekForward
    }
    
    public var body: some View {
        VStack {
            // Top bar
            HStack {
                Text(channelName)
                    .font(SpectraTypography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isLive {
                    LiveBadge()
                }
            }
            .padding(SpectraSpacing.lg)
            
            Spacer()
            
            // Bottom controls
            VStack(spacing: SpectraSpacing.md) {
                // Progress bar (for VOD)
                if !isLive, let duration = duration {
                    ProgressBar(
                        progress: currentTime / duration,
                        currentTime: currentTime,
                        duration: duration
                    )
                    .padding(.horizontal, SpectraSpacing.lg)
                }
                
                // Control buttons
                HStack(spacing: SpectraSpacing.xxl) {
                    // Previous channel
                    ControlButton(systemName: "backward.end.fill", action: onPrevious)
                    
                    // Seek backward (VOD only)
                    if !isLive {
                        ControlButton(systemName: "gobackward.10", action: onSeekBackward)
                    }
                    
                    // Play/Pause
                    ControlButton(
                        systemName: isPlaying ? "pause.fill" : "play.fill",
                        size: .large,
                        action: onPlayPause
                    )
                    
                    // Seek forward (VOD only)
                    if !isLive {
                        ControlButton(systemName: "goforward.10", action: onSeekForward)
                    }
                    
                    // Next channel
                    ControlButton(systemName: "forward.end.fill", action: onNext)
                }
                .padding(.bottom, SpectraSpacing.lg)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

/// Control button
public struct ControlButton: View {
    public enum Size {
        case regular
        case large
    }
    
    public let systemName: String
    public let size: Size
    public let action: () -> Void
    
    public init(systemName: String, size: Size = .regular, action: @escaping () -> Void) {
        self.systemName = systemName
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size == .large ? 44 : 24))
                .foregroundColor(.white)
                .frame(width: size == .large ? 80 : 44, height: size == .large ? 80 : 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Live badge
public struct LiveBadge: View {
    public init() {}
    
    public var body: some View {
        HStack(spacing: SpectraSpacing.xs) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            
            Text("LIVE")
                .font(SpectraTypography.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, SpectraSpacing.sm)
        .padding(.vertical, SpectraSpacing.xs)
        .background(Color.red.opacity(0.3))
        .cornerRadius(SpectraRadius.sm)
    }
}

/// Progress bar for VOD content
public struct ProgressBar: View {
    public let progress: Double
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    
    public init(progress: Double, currentTime: TimeInterval, duration: TimeInterval) {
        self.progress = progress
        self.currentTime = currentTime
        self.duration = duration
    }
    
    public var body: some View {
        VStack(spacing: SpectraSpacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                    
                    Rectangle()
                        .fill(SpectraColors.accent)
                        .frame(width: geometry.size.width * max(0, min(1, progress)))
                }
            }
            .frame(height: 4)
            .cornerRadius(2)
            
            HStack {
                Text(formatTime(currentTime))
                Spacer()
                Text(formatTime(duration))
            }
            .font(SpectraTypography.caption)
            .foregroundColor(.gray)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        PlayerControlsOverlay(
            isPlaying: true,
            isLive: true,
            channelName: "ESPN HD",
            onPlayPause: {},
            onPrevious: {},
            onNext: {}
        )
    }
    .frame(height: 400)
}

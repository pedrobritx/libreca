import SwiftUI
import SpectraCore

/// A row displaying channel information
public struct ChannelRow: View {
    public let channel: Channel
    public let isPlaying: Bool
    public let isFavorite: Bool
    public let healthStatus: StreamHealthStatus
    public let nowPlaying: String?
    public let onTap: () -> Void
    public let onFavorite: () -> Void
    
    public init(
        channel: Channel,
        isPlaying: Bool = false,
        isFavorite: Bool = false,
        healthStatus: StreamHealthStatus = .unknown,
        nowPlaying: String? = nil,
        onTap: @escaping () -> Void,
        onFavorite: @escaping () -> Void
    ) {
        self.channel = channel
        self.isPlaying = isPlaying
        self.isFavorite = isFavorite
        self.healthStatus = healthStatus
        self.nowPlaying = nowPlaying
        self.onTap = onTap
        self.onFavorite = onFavorite
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: SpectraSpacing.md) {
                // Channel logo
                ChannelLogo(url: channel.logoURL, size: 44)
                
                // Channel info
                VStack(alignment: .leading, spacing: SpectraSpacing.xxs) {
                    HStack {
                        Text(channel.name)
                            .font(SpectraTypography.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if isPlaying {
                            Image(systemName: "play.fill")
                                .font(.caption)
                                .foregroundColor(SpectraColors.accent)
                        }
                    }
                    
                    if let nowPlaying = nowPlaying {
                        Text(nowPlaying)
                            .font(SpectraTypography.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if let group = channel.group {
                        Text(group)
                            .font(SpectraTypography.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Health indicator
                HealthIndicator(status: healthStatus)
                
                // Favorite button
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, SpectraSpacing.sm)
            .padding(.horizontal, SpectraSpacing.md)
            .background(isPlaying ? SpectraColors.accent.opacity(0.1) : Color.clear)
            .cornerRadius(SpectraRadius.md)
        }
        .buttonStyle(.plain)
    }
}

/// Channel logo with placeholder
public struct ChannelLogo: View {
    public let url: URL?
    public let size: CGFloat
    
    public init(url: URL?, size: CGFloat = 40) {
        self.url = url
        self.size = size
    }
    
    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                placeholder
            case .empty:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .background(SpectraColors.secondaryBackground)
        .cornerRadius(SpectraRadius.sm)
    }
    
    private var placeholder: some View {
        Image(systemName: "tv")
            .font(.system(size: size * 0.4))
            .foregroundColor(.secondary)
    }
}

/// Health status indicator
public struct HealthIndicator: View {
    public let status: StreamHealthStatus
    
    public init(status: StreamHealthStatus) {
        self.status = status
    }
    
    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
    
    private var color: Color {
        switch status {
        case .ok:
            return SpectraColors.healthOK
        case .flaky:
            return SpectraColors.healthFlaky
        case .dead:
            return SpectraColors.healthDead
        case .unknown:
            return SpectraColors.healthUnknown
        }
    }
}

#Preview {
    VStack {
        ChannelRow(
            channel: Channel(
                id: "1",
                name: "ESPN HD",
                logoURL: nil,
                group: "Sports",
                sourceId: UUID()
            ),
            isPlaying: true,
            isFavorite: true,
            healthStatus: .ok,
            nowPlaying: "NFL Sunday Night Football",
            onTap: {},
            onFavorite: {}
        )
        
        ChannelRow(
            channel: Channel(
                id: "2",
                name: "CNN International",
                logoURL: nil,
                group: "News",
                sourceId: UUID()
            ),
            isPlaying: false,
            isFavorite: false,
            healthStatus: .flaky,
            onTap: {},
            onFavorite: {}
        )
    }
    .padding()
}

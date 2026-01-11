import Foundation

/// Health status of a stream
public enum StreamHealthStatus: String, Codable, Sendable {
    case unknown
    case ok
    case flaky
    case dead
}

/// A stream URL associated with a channel
/// Named MediaStream to avoid conflict with Foundation.Stream
public struct MediaStream: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    
    /// The channel this stream belongs to
    public let channelId: String
    
    /// Stream URL
    public var url: URL
    
    /// Priority (lower = preferred)
    public var priority: Int
    
    /// Health status
    public var healthStatus: StreamHealthStatus
    
    /// Number of consecutive failures
    public var failureCount: Int
    
    /// Last health check timestamp
    public var lastCheckAt: Date?
    
    /// User agent override (some streams require specific UA)
    public var userAgent: String?
    
    /// HTTP referrer override
    public var referrer: String?
    
    public init(
        id: UUID = UUID(),
        channelId: String,
        url: URL,
        priority: Int = 0,
        healthStatus: StreamHealthStatus = .unknown,
        failureCount: Int = 0,
        lastCheckAt: Date? = nil,
        userAgent: String? = nil,
        referrer: String? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.url = url
        self.priority = priority
        self.healthStatus = healthStatus
        self.failureCount = failureCount
        self.lastCheckAt = lastCheckAt
        self.userAgent = userAgent
        self.referrer = referrer
    }
    
    /// Check if this is likely an HLS stream
    public var isHLS: Bool {
        url.pathExtension.lowercased() == "m3u8" ||
        url.absoluteString.contains(".m3u8")
    }
}

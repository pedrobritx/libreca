import Foundation

/// A channel parsed from a playlist with stable identity
public struct Channel: Identifiable, Codable, Sendable, Equatable, Hashable {
    /// Stable identifier (tvg-id or computed hash)
    public let id: String
    
    /// Display name
    public var name: String
    
    /// TVG ID from playlist (if available)
    public var tvgId: String?
    
    /// Logo/icon URL
    public var logoURL: URL?
    
    /// Group or category from playlist
    public var group: String?
    
    /// Country code (ISO 3166-1 alpha-2)
    public var country: String?
    
    /// Language code (ISO 639-1)
    public var language: String?
    
    /// Source this channel belongs to
    public let sourceId: UUID
    
    /// Original order in playlist
    public var playlistOrder: Int
    
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String,
        name: String,
        tvgId: String? = nil,
        logoURL: URL? = nil,
        group: String? = nil,
        country: String? = nil,
        language: String? = nil,
        sourceId: UUID,
        playlistOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.tvgId = tvgId
        self.logoURL = logoURL
        self.group = group
        self.country = country
        self.language = language
        self.sourceId = sourceId
        self.playlistOrder = playlistOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

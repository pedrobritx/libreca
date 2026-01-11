import Foundation

/// A favorited channel
public struct Favorite: Identifiable, Codable, Sendable, Equatable {
    public var id: String { channelId }
    public let channelId: String
    public let addedAt: Date
    
    public init(channelId: String, addedAt: Date = Date()) {
        self.channelId = channelId
        self.addedAt = addedAt
    }
}

/// A hidden channel
public struct Hidden: Identifiable, Codable, Sendable, Equatable {
    public var id: String { channelId }
    public let channelId: String
    public let hiddenAt: Date
    
    public init(channelId: String, hiddenAt: Date = Date()) {
        self.channelId = channelId
        self.hiddenAt = hiddenAt
    }
}

/// A history entry for recently played channels
public struct HistoryEntry: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let channelId: String
    public let playedAt: Date
    public var duration: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        channelId: String,
        playedAt: Date = Date(),
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.playedAt = playedAt
        self.duration = duration
    }
}

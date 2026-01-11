import Foundation

/// Represents the type of playlist source
public enum SourceType: String, Codable, Sendable {
    case m3uURL = "m3u_url"
    case m3uFile = "m3u_file"
}

/// Refresh policy for automatic playlist updates
public enum RefreshPolicy: String, Codable, Sendable {
    case manual
    case hourly
    case daily
    case weekly
}

/// A playlist source (M3U URL or file)
public struct Source: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var type: SourceType
    public var url: URL?
    public var fileBookmark: Data?
    public var refreshPolicy: RefreshPolicy
    public var lastRefreshAt: Date?
    public var epgURL: URL?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: SourceType,
        url: URL? = nil,
        fileBookmark: Data? = nil,
        refreshPolicy: RefreshPolicy = .manual,
        lastRefreshAt: Date? = nil,
        epgURL: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.fileBookmark = fileBookmark
        self.refreshPolicy = refreshPolicy
        self.lastRefreshAt = lastRefreshAt
        self.epgURL = epgURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

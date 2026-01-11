import Foundation

/// A TV program from EPG data
public struct Program: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let channelId: String
    public let title: String
    public let subtitle: String?
    public let description: String?
    public let category: String?
    public let startTime: Date
    public let endTime: Date
    public let iconURL: URL?
    public let rating: String?
    public let episodeNumber: String?
    public let seasonNumber: String?
    
    public init(
        id: String = UUID().uuidString,
        channelId: String,
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        category: String? = nil,
        startTime: Date,
        endTime: Date,
        iconURL: URL? = nil,
        rating: String? = nil,
        episodeNumber: String? = nil,
        seasonNumber: String? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.iconURL = iconURL
        self.rating = rating
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
    }
    
    /// Duration in minutes
    public var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
    
    /// Progress percentage (0.0 - 1.0) if currently airing
    public func progress(at date: Date = Date()) -> Double? {
        guard date >= startTime && date <= endTime else { return nil }
        let total = endTime.timeIntervalSince(startTime)
        let elapsed = date.timeIntervalSince(startTime)
        return elapsed / total
    }
    
    /// Is this program currently airing
    public func isAiring(at date: Date = Date()) -> Bool {
        date >= startTime && date <= endTime
    }
    
    /// Has this program ended
    public func hasEnded(at date: Date = Date()) -> Bool {
        date > endTime
    }
}

/// EPG channel info from XMLTV
public struct EPGChannel: Identifiable, Codable, Sendable {
    public let id: String
    public let displayName: String
    public let iconURL: URL?
    
    public init(id: String, displayName: String, iconURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.iconURL = iconURL
    }
}

/// Parsed EPG data
public struct ParsedEPG: Sendable {
    public let channels: [EPGChannel]
    public let programs: [Program]
    public let parseTime: TimeInterval
    
    public init(channels: [EPGChannel], programs: [Program], parseTime: TimeInterval) {
        self.channels = channels
        self.programs = programs
        self.parseTime = parseTime
    }
    
    public var channelCount: Int { channels.count }
    public var programCount: Int { programs.count }
}

/// Now/Next pair for a channel
public struct NowNext: Sendable {
    public let channelId: String
    public let now: Program?
    public let next: Program?
    
    public init(channelId: String, now: Program?, next: Program?) {
        self.channelId = channelId
        self.now = now
        self.next = next
    }
}

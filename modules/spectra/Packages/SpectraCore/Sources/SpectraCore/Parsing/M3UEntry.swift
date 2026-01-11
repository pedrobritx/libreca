import Foundation

/// Parsed M3U entry before being converted to Channel/Stream
public struct M3UEntry: Sendable, Equatable {
    public let name: String
    public let url: URL
    public var duration: Int?
    public var tvgId: String?
    public var tvgName: String?
    public var tvgLogo: String?
    public var groupTitle: String?
    public var language: String?
    public var country: String?
    public var userAgent: String?
    public var referrer: String?
    public var extraAttributes: [String: String]
    
    public init(
        name: String,
        url: URL,
        duration: Int? = nil,
        tvgId: String? = nil,
        tvgName: String? = nil,
        tvgLogo: String? = nil,
        groupTitle: String? = nil,
        language: String? = nil,
        country: String? = nil,
        userAgent: String? = nil,
        referrer: String? = nil,
        extraAttributes: [String: String] = [:]
    ) {
        self.name = name
        self.url = url
        self.duration = duration
        self.tvgId = tvgId
        self.tvgName = tvgName
        self.tvgLogo = tvgLogo
        self.groupTitle = groupTitle
        self.language = language
        self.country = country
        self.userAgent = userAgent
        self.referrer = referrer
        self.extraAttributes = extraAttributes
    }
    
    /// Effective name (tvg-name if available, otherwise display name)
    public var effectiveName: String {
        tvgName ?? name
    }
    
    /// Logo URL if valid
    public var logoURL: URL? {
        guard let logo = tvgLogo, !logo.isEmpty else { return nil }
        return URL(string: logo)
    }
}

/// Result of parsing an M3U playlist
public struct ParsedPlaylist: Sendable {
    public let entries: [M3UEntry]
    public let parseTime: TimeInterval
    public let errors: [M3UParseError]
    
    public init(entries: [M3UEntry], parseTime: TimeInterval, errors: [M3UParseError]) {
        self.entries = entries
        self.parseTime = parseTime
        self.errors = errors
    }
    
    public var isValid: Bool {
        !entries.isEmpty
    }
    
    public var uniqueGroups: Set<String> {
        Set(entries.compactMap { $0.groupTitle })
    }
    
    public var uniqueCountries: Set<String> {
        Set(entries.compactMap { $0.country })
    }
    
    public var uniqueLanguages: Set<String> {
        Set(entries.compactMap { $0.language })
    }
}

/// Error encountered during M3U parsing
public struct M3UParseError: Error, Sendable {
    public let line: Int
    public let message: String
    public let rawContent: String?
    
    public init(line: Int, message: String, rawContent: String? = nil) {
        self.line = line
        self.message = message
        self.rawContent = rawContent
    }
}

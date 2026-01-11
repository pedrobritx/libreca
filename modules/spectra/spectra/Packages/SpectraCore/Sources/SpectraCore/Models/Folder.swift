import Foundation

/// Type of folder
public enum FolderType: String, Codable, Sendable {
    case manual
    case smart
}

/// A folder for organizing channels
public struct Folder: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var order: Int
    public var type: FolderType
    
    /// JSON-encoded rules for smart folders
    public var ruleJSON: String?
    
    /// Icon name (SF Symbol)
    public var iconName: String?
    
    public let createdAt: Date
    public var updatedAt: Date
    
    /// Parsed rules (computed from ruleJSON)
    public var rules: FolderRules? {
        guard let json = ruleJSON,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(FolderRules.self, from: data)
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        order: Int = 0,
        type: FolderType = .manual,
        ruleJSON: String? = nil,
        iconName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.type = type
        self.ruleJSON = ruleJSON
        self.iconName = iconName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Create a smart folder with rules
    public static func smart(
        name: String,
        rules: FolderRules,
        order: Int = 0,
        iconName: String? = nil
    ) throws -> Folder {
        let encoder = JSONEncoder()
        let ruleData = try encoder.encode(rules)
        let ruleJSON = String(data: ruleData, encoding: .utf8)
        
        return Folder(
            name: name,
            order: order,
            type: .smart,
            ruleJSON: ruleJSON,
            iconName: iconName
        )
    }
}

/// A channel's membership in a folder
public struct FolderItem: Identifiable, Codable, Sendable, Equatable {
    public var id: String { "\(folderId)-\(channelId)" }
    public let folderId: UUID
    public let channelId: String
    public var order: Int
    public let addedAt: Date
    
    public init(
        folderId: UUID,
        channelId: String,
        order: Int = 0,
        addedAt: Date = Date()
    ) {
        self.folderId = folderId
        self.channelId = channelId
        self.order = order
        self.addedAt = addedAt
    }
}

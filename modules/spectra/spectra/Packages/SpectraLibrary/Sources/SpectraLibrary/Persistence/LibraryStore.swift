import Foundation
import SpectraCore

/// Protocol for library persistence backends
public protocol LibraryStore: Actor {
    // Sources
    func fetchSources() async throws -> [Source]
    func saveSource(_ source: Source) async throws
    func deleteSource(id: UUID) async throws
    
    // Channels
    func fetchChannels(sourceId: UUID?) async throws -> [Channel]
    func fetchChannel(id: String) async throws -> Channel?
    func saveChannels(_ channels: [Channel]) async throws
    func deleteChannels(sourceId: UUID) async throws
    
    // Streams
    func fetchStreams(channelId: String) async throws -> [MediaStream]
    func saveStreams(_ streams: [MediaStream]) async throws
    func updateStreamHealth(id: UUID, status: StreamHealthStatus, failureCount: Int) async throws
    
    // Folders
    func fetchFolders() async throws -> [Folder]
    func saveFolder(_ folder: Folder) async throws
    func deleteFolder(id: UUID) async throws
    func fetchFolderItems(folderId: UUID) async throws -> [FolderItem]
    func saveFolderItem(_ item: FolderItem) async throws
    func deleteFolderItem(folderId: UUID, channelId: String) async throws
    
    // User Data
    func fetchFavorites() async throws -> [Favorite]
    func saveFavorite(_ favorite: Favorite) async throws
    func deleteFavorite(channelId: String) async throws
    func isFavorite(channelId: String) async throws -> Bool
    
    func fetchHidden() async throws -> [Hidden]
    func saveHidden(_ hidden: Hidden) async throws
    func deleteHidden(channelId: String) async throws
    func isHidden(channelId: String) async throws -> Bool
    
    func fetchHistory(limit: Int) async throws -> [HistoryEntry]
    func saveHistoryEntry(_ entry: HistoryEntry) async throws
    func clearHistory() async throws
}

/// Search options for channel queries
public struct ChannelSearchOptions: Sendable {
    public var query: String?
    public var sourceId: UUID?
    public var group: String?
    public var country: String?
    public var language: String?
    public var healthStatus: StreamHealthStatus?
    public var excludeHidden: Bool
    public var onlyFavorites: Bool
    public var limit: Int?
    public var offset: Int?
    
    public init(
        query: String? = nil,
        sourceId: UUID? = nil,
        group: String? = nil,
        country: String? = nil,
        language: String? = nil,
        healthStatus: StreamHealthStatus? = nil,
        excludeHidden: Bool = true,
        onlyFavorites: Bool = false,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.query = query
        self.sourceId = sourceId
        self.group = group
        self.country = country
        self.language = language
        self.healthStatus = healthStatus
        self.excludeHidden = excludeHidden
        self.onlyFavorites = onlyFavorites
        self.limit = limit
        self.offset = offset
    }
}

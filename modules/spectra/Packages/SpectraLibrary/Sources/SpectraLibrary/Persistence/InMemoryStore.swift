import Foundation
import SpectraCore

/// In-memory implementation of LibraryStore for development and testing
public actor InMemoryStore: LibraryStore {
    
    private var sources: [UUID: Source] = [:]
    private var channels: [String: Channel] = [:]
    private var streams: [UUID: MediaStream] = [:]
    private var folders: [UUID: Folder] = [:]
    private var folderItems: [String: FolderItem] = [:] // key: folderId-channelId
    private var favorites: Set<String> = []
    private var hidden: Set<String> = []
    private var history: [HistoryEntry] = []
    
    public init() {}
    
    // MARK: - Sources
    
    public func fetchSources() async throws -> [Source] {
        Array(sources.values).sorted { $0.name < $1.name }
    }
    
    public func saveSource(_ source: Source) async throws {
        sources[source.id] = source
    }
    
    public func deleteSource(id: UUID) async throws {
        sources.removeValue(forKey: id)
        // Also delete associated channels
        channels = channels.filter { $0.value.sourceId != id }
    }
    
    // MARK: - Channels
    
    public func fetchChannels(sourceId: UUID?) async throws -> [Channel] {
        var result = Array(channels.values)
        if let sourceId = sourceId {
            result = result.filter { $0.sourceId == sourceId }
        }
        return result.sorted { $0.playlistOrder < $1.playlistOrder }
    }
    
    public func fetchChannel(id: String) async throws -> Channel? {
        channels[id]
    }
    
    public func saveChannels(_ newChannels: [Channel]) async throws {
        for channel in newChannels {
            channels[channel.id] = channel
        }
    }
    
    public func deleteChannels(sourceId: UUID) async throws {
        channels = channels.filter { $0.value.sourceId != sourceId }
    }
    
    // MARK: - Streams
    
    public func fetchStreams(channelId: String) async throws -> [MediaStream] {
        streams.values
            .filter { $0.channelId == channelId }
            .sorted { $0.priority < $1.priority }
    }
    
    public func saveStreams(_ newStreams: [MediaStream]) async throws {
        for stream in newStreams {
            streams[stream.id] = stream
        }
    }
    
    public func updateStreamHealth(id: UUID, status: StreamHealthStatus, failureCount: Int) async throws {
        guard var stream = streams[id] else { return }
        stream.healthStatus = status
        stream.failureCount = failureCount
        stream.lastCheckAt = Date()
        streams[id] = stream
    }
    
    // MARK: - Folders
    
    public func fetchFolders() async throws -> [Folder] {
        Array(folders.values).sorted { $0.order < $1.order }
    }
    
    public func saveFolder(_ folder: Folder) async throws {
        folders[folder.id] = folder
    }
    
    public func deleteFolder(id: UUID) async throws {
        folders.removeValue(forKey: id)
        folderItems = folderItems.filter { !$0.key.hasPrefix(id.uuidString) }
    }
    
    public func fetchFolderItems(folderId: UUID) async throws -> [FolderItem] {
        folderItems.values
            .filter { $0.folderId == folderId }
            .sorted { $0.order < $1.order }
    }
    
    public func saveFolderItem(_ item: FolderItem) async throws {
        folderItems[item.id] = item
    }
    
    public func deleteFolderItem(folderId: UUID, channelId: String) async throws {
        let key = "\(folderId)-\(channelId)"
        folderItems.removeValue(forKey: key)
    }
    
    // MARK: - Favorites
    
    public func fetchFavorites() async throws -> [Favorite] {
        favorites.map { Favorite(channelId: $0) }
    }
    
    public func saveFavorite(_ favorite: Favorite) async throws {
        favorites.insert(favorite.channelId)
    }
    
    public func deleteFavorite(channelId: String) async throws {
        favorites.remove(channelId)
    }
    
    public func isFavorite(channelId: String) async throws -> Bool {
        favorites.contains(channelId)
    }
    
    // MARK: - Hidden
    
    public func fetchHidden() async throws -> [Hidden] {
        hidden.map { Hidden(channelId: $0) }
    }
    
    public func saveHidden(_ hiddenItem: Hidden) async throws {
        hidden.insert(hiddenItem.channelId)
    }
    
    public func deleteHidden(channelId: String) async throws {
        hidden.remove(channelId)
    }
    
    public func isHidden(channelId: String) async throws -> Bool {
        hidden.contains(channelId)
    }
    
    // MARK: - History
    
    public func fetchHistory(limit: Int) async throws -> [HistoryEntry] {
        Array(history.sorted { $0.playedAt > $1.playedAt }.prefix(limit))
    }
    
    public func saveHistoryEntry(_ entry: HistoryEntry) async throws {
        // Remove duplicate if exists
        history.removeAll { $0.channelId == entry.channelId }
        history.append(entry)
        
        // Keep only last 100 entries
        if history.count > 100 {
            history = Array(history.sorted { $0.playedAt > $1.playedAt }.prefix(100))
        }
    }
    
    public func clearHistory() async throws {
        history.removeAll()
    }
}

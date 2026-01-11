import Foundation
import SpectraCore

/// Main library interface combining all operations
public actor Library {
    
    public let store: any LibraryStore
    private let ruleEngine: RuleEngine
    private lazy var importPipeline = ImportPipeline(store: store)
    
    public init(store: any LibraryStore) {
        self.store = store
        self.ruleEngine = RuleEngine()
    }
    
    // MARK: - Sources
    
    public func getSources() async throws -> [Source] {
        try await store.fetchSources()
    }
    
    public func importSource(url: URL, name: String? = nil) async throws -> ImportResult {
        try await importPipeline.importFromURL(url, name: name)
    }
    
    public func importSource(data: Data, name: String, bookmark: Data? = nil) async throws -> ImportResult {
        try await importPipeline.importFromFile(data, name: name, bookmark: bookmark)
    }
    
    public func refreshSource(_ source: Source) async throws -> ImportResult {
        try await importPipeline.refresh(source: source)
    }
    
    public func deleteSource(id: UUID) async throws {
        try await store.deleteSource(id: id)
    }
    
    // MARK: - Channels
    
    public func getChannels(options: ChannelSearchOptions = ChannelSearchOptions()) async throws -> [Channel] {
        var channels = try await store.fetchChannels(sourceId: options.sourceId)
        
        // Apply filters
        if let query = options.query?.lowercased(), !query.isEmpty {
            channels = channels.filter { channel in
                channel.name.lowercased().contains(query) ||
                channel.group?.lowercased().contains(query) == true ||
                channel.tvgId?.lowercased().contains(query) == true
            }
        }
        
        if let group = options.group {
            channels = channels.filter { $0.group == group }
        }
        
        if let country = options.country {
            channels = channels.filter { $0.country == country }
        }
        
        if let language = options.language {
            channels = channels.filter { $0.language == language }
        }
        
        if options.excludeHidden {
            let hidden = try await store.fetchHidden()
            let hiddenIds = Set(hidden.map { $0.channelId })
            channels = channels.filter { !hiddenIds.contains($0.id) }
        }
        
        if options.onlyFavorites {
            let favorites = try await store.fetchFavorites()
            let favoriteIds = Set(favorites.map { $0.channelId })
            channels = channels.filter { favoriteIds.contains($0.id) }
        }
        
        // Apply pagination
        if let offset = options.offset, offset > 0 {
            channels = Array(channels.dropFirst(offset))
        }
        
        if let limit = options.limit {
            channels = Array(channels.prefix(limit))
        }
        
        return channels
    }
    
    public func getChannel(id: String) async throws -> Channel? {
        try await store.fetchChannel(id: id)
    }
    
    public func getStreams(channelId: String) async throws -> [MediaStream] {
        try await store.fetchStreams(channelId: channelId)
    }
    
    // MARK: - Folders
    
    public func getFolders() async throws -> [Folder] {
        try await store.fetchFolders()
    }
    
    public func createFolder(name: String, iconName: String? = nil) async throws -> Folder {
        let folders = try await store.fetchFolders()
        let maxOrder = folders.map { $0.order }.max() ?? 0
        
        let folder = Folder(
            name: name,
            order: maxOrder + 1,
            type: .manual,
            iconName: iconName
        )
        
        try await store.saveFolder(folder)
        return folder
    }
    
    public func createSmartFolder(name: String, rules: FolderRules, iconName: String? = nil) async throws -> Folder {
        let folder = try Folder.smart(name: name, rules: rules, iconName: iconName)
        try await store.saveFolder(folder)
        return folder
    }
    
    public func updateFolder(_ folder: Folder) async throws {
        try await store.saveFolder(folder)
    }
    
    public func deleteFolder(id: UUID) async throws {
        try await store.deleteFolder(id: id)
    }
    
    public func getChannelsInFolder(_ folder: Folder) async throws -> [Channel] {
        switch folder.type {
        case .manual:
            let items = try await store.fetchFolderItems(folderId: folder.id)
            var channels: [Channel] = []
            for item in items {
                if let channel = try await store.fetchChannel(id: item.channelId) {
                    channels.append(channel)
                }
            }
            return channels
            
        case .smart:
            guard let ruleJSON = folder.ruleJSON,
                  let ruleData = ruleJSON.data(using: .utf8) else {
                return []
            }
            
            let rules = try JSONDecoder().decode(FolderRules.self, from: ruleData)
            let allChannels = try await store.fetchChannels(sourceId: nil)
            let favorites = Set((try await store.fetchFavorites()).map { $0.channelId })
            let hidden = Set((try await store.fetchHidden()).map { $0.channelId })
            
            return ruleEngine.filter(channels: allChannels, rules: rules) { channel in
                // Note: Streams are fetched lazily for health status evaluation
                // For now, we provide empty streams - a future optimization could
                // pre-fetch stream health status
                return RuleEvaluationContext(
                    channel: channel,
                    streams: [],
                    isFavorite: favorites.contains(channel.id),
                    isHidden: hidden.contains(channel.id)
                )
            }
        }
    }
    
    public func addChannelToFolder(channelId: String, folderId: UUID) async throws {
        let items = try await store.fetchFolderItems(folderId: folderId)
        let maxOrder = items.map { $0.order }.max() ?? 0
        
        let item = FolderItem(
            folderId: folderId,
            channelId: channelId,
            order: maxOrder + 1
        )
        
        try await store.saveFolderItem(item)
    }
    
    public func removeChannelFromFolder(channelId: String, folderId: UUID) async throws {
        try await store.deleteFolderItem(folderId: folderId, channelId: channelId)
    }
    
    // MARK: - Favorites
    
    public func getFavorites() async throws -> [Channel] {
        let favorites = try await store.fetchFavorites()
        var channels: [Channel] = []
        for favorite in favorites {
            if let channel = try await store.fetchChannel(id: favorite.channelId) {
                channels.append(channel)
            }
        }
        return channels
    }
    
    public func toggleFavorite(channelId: String) async throws -> Bool {
        if try await store.isFavorite(channelId: channelId) {
            try await store.deleteFavorite(channelId: channelId)
            return false
        } else {
            try await store.saveFavorite(Favorite(channelId: channelId))
            return true
        }
    }
    
    public func isFavorite(channelId: String) async throws -> Bool {
        try await store.isFavorite(channelId: channelId)
    }
    
    // MARK: - Hidden
    
    public func toggleHidden(channelId: String) async throws -> Bool {
        if try await store.isHidden(channelId: channelId) {
            try await store.deleteHidden(channelId: channelId)
            return false
        } else {
            try await store.saveHidden(Hidden(channelId: channelId))
            return true
        }
    }
    
    public func isHidden(channelId: String) async throws -> Bool {
        try await store.isHidden(channelId: channelId)
    }
    
    // MARK: - History
    
    public func getHistory(limit: Int = 20) async throws -> [Channel] {
        let history = try await store.fetchHistory(limit: limit)
        var channels: [Channel] = []
        for entry in history {
            if let channel = try await store.fetchChannel(id: entry.channelId) {
                channels.append(channel)
            }
        }
        return channels
    }
    
    public func recordPlay(channelId: String) async throws {
        let entry = HistoryEntry(channelId: channelId)
        try await store.saveHistoryEntry(entry)
    }
    
    // MARK: - Statistics
    
    public func getGroups() async throws -> [String] {
        let channels = try await store.fetchChannels(sourceId: nil)
        let groups = Set(channels.compactMap { $0.group })
        return groups.sorted()
    }
    
    public func getCountries() async throws -> [String] {
        let channels = try await store.fetchChannels(sourceId: nil)
        let countries = Set(channels.compactMap { $0.country })
        return countries.sorted()
    }
    
    public func getLanguages() async throws -> [String] {
        let channels = try await store.fetchChannels(sourceId: nil)
        let languages = Set(channels.compactMap { $0.language })
        return languages.sorted()
    }
}

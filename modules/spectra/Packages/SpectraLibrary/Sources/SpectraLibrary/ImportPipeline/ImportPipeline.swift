import Foundation
import SpectraCore

/// Result of importing a playlist
public struct ImportResult: Sendable {
    public let source: Source
    public let channelsAdded: Int
    public let channelsUpdated: Int
    public let channelsRemoved: Int
    public let streamsAdded: Int
    public let errors: [ImportError]
    public let duration: TimeInterval
    
    public var totalChannels: Int {
        channelsAdded + channelsUpdated
    }
    
    public var isSuccess: Bool {
        errors.isEmpty && totalChannels > 0
    }
}

/// Error during import
public struct ImportError: Error, Sendable {
    public let message: String
    public let entry: M3UEntry?
    
    public init(message: String, entry: M3UEntry? = nil) {
        self.message = message
        self.entry = entry
    }
}

/// Pipeline for importing and refreshing playlists
public actor ImportPipeline {
    
    private let store: any LibraryStore
    private let parser: M3UParser
    
    public init(store: any LibraryStore) {
        self.store = store
        self.parser = M3UParser()
    }
    
    /// Import a new playlist from URL
    public func importFromURL(_ url: URL, name: String? = nil) async throws -> ImportResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Parse playlist
        let playlist = try await parser.parse(url: url)
        
        // Create source
        let source = Source(
            name: name ?? url.lastPathComponent,
            type: .m3uURL,
            url: url,
            lastRefreshAt: Date()
        )
        
        // Process entries
        let result = try await processEntries(
            playlist.entries,
            source: source,
            isRefresh: false,
            startTime: startTime
        )
        
        return result
    }
    
    /// Import a new playlist from file data
    public func importFromFile(_ data: Data, name: String, bookmark: Data? = nil) async throws -> ImportResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Parse playlist
        let playlist = try await parser.parse(data: data)
        
        // Create source
        let source = Source(
            name: name,
            type: .m3uFile,
            fileBookmark: bookmark,
            lastRefreshAt: Date()
        )
        
        // Process entries
        let result = try await processEntries(
            playlist.entries,
            source: source,
            isRefresh: false,
            startTime: startTime
        )
        
        return result
    }
    
    /// Refresh an existing source
    public func refresh(source: Source) async throws -> ImportResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Fetch playlist
        let playlist: ParsedPlaylist
        
        switch source.type {
        case .m3uURL:
            guard let url = source.url else {
                throw ImportError(message: "Source has no URL")
            }
            playlist = try await parser.parse(url: url)
            
        case .m3uFile:
            guard let bookmark = source.fileBookmark else {
                throw ImportError(message: "Source has no file bookmark")
            }
            
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            guard url.startAccessingSecurityScopedResource() else {
                throw ImportError(message: "Cannot access file")
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let data = try Data(contentsOf: url)
            playlist = try await parser.parse(data: data)
        }
        
        // Update source timestamp
        var updatedSource = source
        updatedSource.lastRefreshAt = Date()
        updatedSource.updatedAt = Date()
        
        // Process entries
        let result = try await processEntries(
            playlist.entries,
            source: updatedSource,
            isRefresh: true,
            startTime: startTime
        )
        
        return result
    }
    
    // MARK: - Private
    
    private func processEntries(
        _ entries: [M3UEntry],
        source: Source,
        isRefresh: Bool,
        startTime: CFAbsoluteTime
    ) async throws -> ImportResult {
        var errors: [ImportError] = []
        var channelsAdded = 0
        var channelsUpdated = 0
        var channelsRemoved = 0
        var streamsAdded = 0
        
        // Get existing channels for this source if refreshing
        let existingChannelIds: Set<String>
        if isRefresh {
            let existing = try await store.fetchChannels(sourceId: source.id)
            existingChannelIds = Set(existing.map { $0.id })
        } else {
            existingChannelIds = []
        }
        
        var processedChannelIds = Set<String>()
        var channelsToSave: [Channel] = []
        var streamsToSave: [MediaStream] = []
        
        // Process each entry
        for (index, entry) in entries.enumerated() {
            // Generate stable ID
            let channelId = ChannelIdentity.generateId(
                tvgId: entry.tvgId,
                name: entry.effectiveName,
                streamURL: entry.url
            )
            
            processedChannelIds.insert(channelId)
            
            // Check if channel exists
            let existingChannel = try await store.fetchChannel(id: channelId)
            
            if existingChannel != nil {
                // Update existing channel
                let channel = Channel(
                    id: channelId,
                    name: entry.effectiveName,
                    tvgId: entry.tvgId,
                    logoURL: entry.logoURL,
                    group: entry.groupTitle,
                    country: entry.country,
                    language: entry.language,
                    sourceId: source.id,
                    playlistOrder: index,
                    createdAt: existingChannel!.createdAt,
                    updatedAt: Date()
                )
                channelsToSave.append(channel)
                channelsUpdated += 1
            } else {
                // New channel
                let channel = Channel(
                    id: channelId,
                    name: entry.effectiveName,
                    tvgId: entry.tvgId,
                    logoURL: entry.logoURL,
                    group: entry.groupTitle,
                    country: entry.country,
                    language: entry.language,
                    sourceId: source.id,
                    playlistOrder: index
                )
                channelsToSave.append(channel)
                channelsAdded += 1
            }
            
            // Create stream
            let stream = MediaStream(
                channelId: channelId,
                url: entry.url,
                userAgent: entry.userAgent,
                referrer: entry.referrer
            )
            streamsToSave.append(stream)
            streamsAdded += 1
        }
        
        // Save source
        try await store.saveSource(source)
        
        // Save channels in batches
        try await store.saveChannels(channelsToSave)
        
        // Save streams in batches
        try await store.saveStreams(streamsToSave)
        
        // Count removed channels (existed before but not in new playlist)
        if isRefresh {
            let removed = existingChannelIds.subtracting(processedChannelIds)
            channelsRemoved = removed.count
            // Note: We don't delete channels, they just become "orphaned"
            // User organization (folders, favorites) is preserved
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        return ImportResult(
            source: source,
            channelsAdded: channelsAdded,
            channelsUpdated: channelsUpdated,
            channelsRemoved: channelsRemoved,
            streamsAdded: streamsAdded,
            errors: errors,
            duration: duration
        )
    }
}

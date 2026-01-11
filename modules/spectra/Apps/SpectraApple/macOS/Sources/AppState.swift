import SwiftUI
import SpectraCore
import SpectraLibrary
import SpectraPlayer
import SpectraEPG
import SpectraUI

/// Main application state
@MainActor
class AppState: ObservableObject {
    // Library
    @Published var library: Library
    @Published var sources: [Source] = []
    @Published var channels: [Channel] = []
    @Published var folders: [Folder] = []
    
    // Channel streams cache
    private var streamCache: [String: [MediaStream]] = [:]
    
    // Selection
    @Published var selectedFolder: Folder?
    @Published var selectedChannel: Channel?
    
    // Player
    @Published var playerEngine = PlayerEngine()
    
    // EPG
    @Published var epgCache = EPGCache()
    
    // UI State
    @Published var searchText = ""
    @Published var showImportSheet = false
    @Published var showURLImportSheet = false
    @Published var showPlayerFullscreen = false
    
    init() {
        let store = InMemoryLibraryStore()
        self.library = Library(store: store)
        
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        do {
            sources = try await library.getSources()
            channels = try await library.getChannels()
            folders = try await library.getFolders()
        } catch {
            print("Failed to load data: \(error)")
        }
    }
    
    func streams(for channel: Channel) async -> [MediaStream] {
        if let cached = streamCache[channel.id] {
            return cached
        }
        
        do {
            let streams = try await library.getStreams(channelId: channel.id)
            streamCache[channel.id] = streams
            return streams
        } catch {
            return []
        }
    }
    
    func playChannel(_ channel: Channel) {
        selectedChannel = channel
        Task {
            let channelStreams = await streams(for: channel)
            guard let stream = channelStreams.first else { return }
            playerEngine.play(channelId: channel.id, url: stream.url)
        }
    }
    
    func previousChannel() {
        guard let current = selectedChannel,
              let index = channels.firstIndex(where: { $0.id == current.id }),
              index > 0 else { return }
        playChannel(channels[index - 1])
    }
    
    func nextChannel() {
        guard let current = selectedChannel,
              let index = channels.firstIndex(where: { $0.id == current.id }),
              index < channels.count - 1 else { return }
        playChannel(channels[index + 1])
    }
    
    var filteredChannels: [Channel] {
        var result = channels
        
        // Filter by search
        if !searchText.isEmpty {
            let search = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(search) ||
                $0.group?.lowercased().contains(search) == true
            }
        }
        
        // Filter by folder
        if let folder = selectedFolder {
            // For smart folders, apply rules
            if folder.type == .smart, let rules = folder.rules {
                let engine = RuleEngine()
                result = engine.filter(channels: result, rules: rules) { channel in
                    RuleEvaluationContext(channel: channel)
                }
            }
            // For manual folders, filter by folder items
            // (would need to look up folder items from library)
        }
        
        return result
    }
}

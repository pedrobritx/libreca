import Testing
@testable import SpectraLibrary
import SpectraCore
import Foundation

@Suite("Library Tests")
struct LibraryTests {
    
    @Test("Import creates source and channels")
    func importCreatesSourceAndChannels() async throws {
        let store = InMemoryStore()
        let library = Library(store: store)
        
        // Create test M3U content
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="test1" group-title="Sports",Channel 1
        http://example.com/stream1.m3u8
        #EXTINF:-1 tvg-id="test2" group-title="News",Channel 2
        http://example.com/stream2.m3u8
        """
        
        let data = content.data(using: .utf8)!
        let result = try await library.importSource(data: data, name: "Test Playlist")
        
        #expect(result.isSuccess)
        #expect(result.channelsAdded == 2)
        
        let channels = try await library.getChannels()
        #expect(channels.count == 2)
        
        let sources = try await library.getSources()
        #expect(sources.count == 1)
        #expect(sources[0].name == "Test Playlist")
    }
    
    @Test("Folders persist channel membership")
    func foldersWork() async throws {
        let store = InMemoryStore()
        let library = Library(store: store)
        
        // Import test data
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="ch1",Channel 1
        http://example.com/1.m3u8
        #EXTINF:-1 tvg-id="ch2",Channel 2
        http://example.com/2.m3u8
        """
        
        let data = content.data(using: .utf8)!
        _ = try await library.importSource(data: data, name: "Test")
        
        // Create folder
        let folder = try await library.createFolder(name: "My Folder")
        
        // Add channel to folder
        let channels = try await library.getChannels()
        try await library.addChannelToFolder(channelId: channels[0].id, folderId: folder.id)
        
        // Verify
        let folderChannels = try await library.getChannelsInFolder(folder)
        #expect(folderChannels.count == 1)
        #expect(folderChannels[0].id == channels[0].id)
    }
    
    @Test("Favorites toggle correctly")
    func favoritesToggle() async throws {
        let store = InMemoryStore()
        let library = Library(store: store)
        
        // Import test data
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="ch1",Channel 1
        http://example.com/1.m3u8
        """
        
        let data = content.data(using: .utf8)!
        _ = try await library.importSource(data: data, name: "Test")
        
        let channels = try await library.getChannels()
        let channelId = channels[0].id
        
        // Initially not favorite
        #expect(try await library.isFavorite(channelId: channelId) == false)
        
        // Toggle on
        let result1 = try await library.toggleFavorite(channelId: channelId)
        #expect(result1 == true)
        #expect(try await library.isFavorite(channelId: channelId) == true)
        
        // Toggle off
        let result2 = try await library.toggleFavorite(channelId: channelId)
        #expect(result2 == false)
        #expect(try await library.isFavorite(channelId: channelId) == false)
    }
    
    @Test("Search filters channels")
    func searchFilters() async throws {
        let store = InMemoryStore()
        let library = Library(store: store)
        
        let content = """
        #EXTM3U
        #EXTINF:-1 group-title="Sports",ESPN
        http://example.com/espn.m3u8
        #EXTINF:-1 group-title="News",CNN
        http://example.com/cnn.m3u8
        #EXTINF:-1 group-title="Sports",Fox Sports
        http://example.com/fox.m3u8
        """
        
        let data = content.data(using: .utf8)!
        _ = try await library.importSource(data: data, name: "Test")
        
        // Search by name
        let nameResults = try await library.getChannels(options: ChannelSearchOptions(query: "espn"))
        #expect(nameResults.count == 1)
        
        // Filter by group
        let groupResults = try await library.getChannels(options: ChannelSearchOptions(group: "Sports"))
        #expect(groupResults.count == 2)
    }
}

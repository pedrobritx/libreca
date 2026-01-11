import Testing
@testable import SpectraSync
import SpectraCore
import Foundation

@Suite("Conflict Resolution Tests")
struct ConflictResolutionTests {
    
    let resolver = ConflictResolver()
    
    @Test("Folder conflict resolves to most recent")
    func folderConflict() {
        let localFolder = Folder(
            id: UUID(),
            name: "Local Name",
            order: 1,
            updatedAt: Date()
        )
        
        let remoteFolder = Folder(
            id: localFolder.id,
            name: "Remote Name",
            order: 1,
            updatedAt: Date().addingTimeInterval(-100)
        )
        
        let result = resolver.resolve(local: localFolder, remote: remoteFolder)
        
        #expect(result.hadConflict == true)
        #expect(result.resolved.name == "Local Name")
    }
    
    @Test("Favorite conflict preserves user intent")
    func favoriteConflict() {
        // Local has favorite, remote doesn't
        let result1 = resolver.resolveFavorite(
            localExists: true,
            remoteExists: false,
            channelId: "test"
        )
        #expect(result1.keep == true)
        #expect(result1.hadConflict == true)
        
        // Remote has favorite, local doesn't
        let result2 = resolver.resolveFavorite(
            localExists: false,
            remoteExists: true,
            channelId: "test"
        )
        #expect(result2.keep == true)
        #expect(result2.hadConflict == true)
    }
    
    @Test("Folder items merge as union")
    func folderItemsMerge() {
        let folderId = UUID()
        
        let localItems = [
            FolderItem(folderId: folderId, channelId: "ch1", order: 0),
            FolderItem(folderId: folderId, channelId: "ch2", order: 1),
        ]
        
        let remoteItems = [
            FolderItem(folderId: folderId, channelId: "ch2", order: 0),
            FolderItem(folderId: folderId, channelId: "ch3", order: 1),
        ]
        
        let merged = resolver.resolveFolderItems(local: localItems, remote: remoteItems)
        
        let channelIds = Set(merged.map { $0.channelId })
        #expect(channelIds.contains("ch1"))
        #expect(channelIds.contains("ch2"))
        #expect(channelIds.contains("ch3"))
    }
}

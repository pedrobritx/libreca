import Foundation
import SpectraCore

/// Conflict resolution strategy
public enum ConflictResolution: Sendable {
    /// Local changes win
    case localWins
    /// Remote changes win  
    case remoteWins
    /// Most recent change wins
    case mostRecent
    /// User intent always preserved (for folders/favorites)
    case preserveUserIntent
}

/// Merge result
public struct MergeResult<T: Sendable>: Sendable {
    public let resolved: T
    public let hadConflict: Bool
    public let resolution: ConflictResolution
}

/// Handles merge conflicts between local and remote data
public struct ConflictResolver: Sendable {
    
    public init() {}
    
    /// Resolve folder conflicts
    /// User intent (folder name, structure) wins over refresh data
    public func resolve(
        local: Folder,
        remote: Folder
    ) -> MergeResult<Folder> {
        // User-modified properties take precedence
        if local.updatedAt > remote.updatedAt {
            return MergeResult(resolved: local, hadConflict: true, resolution: .localWins)
        }
        
        // For smart folders, preserve the more recent rules
        if local.type == .smart && remote.type == .smart {
            let resolved = local.updatedAt > remote.updatedAt ? local : remote
            return MergeResult(resolved: resolved, hadConflict: true, resolution: .mostRecent)
        }
        
        return MergeResult(resolved: remote, hadConflict: true, resolution: .remoteWins)
    }
    
    /// Resolve favorite conflicts
    /// If either side has it as favorite, keep it
    public func resolveFavorite(
        localExists: Bool,
        remoteExists: Bool,
        channelId: String
    ) -> (keep: Bool, hadConflict: Bool) {
        if localExists != remoteExists {
            // Preserve user intent - if marked as favorite anywhere, keep it
            return (keep: localExists || remoteExists, hadConflict: true)
        }
        return (keep: localExists, hadConflict: false)
    }
    
    /// Resolve hidden channel conflicts
    /// If either side has it hidden, keep it hidden
    public func resolveHidden(
        localExists: Bool,
        remoteExists: Bool,
        channelId: String
    ) -> (keep: Bool, hadConflict: Bool) {
        if localExists != remoteExists {
            // Preserve user intent - if hidden anywhere, keep hidden
            return (keep: localExists || remoteExists, hadConflict: true)
        }
        return (keep: localExists, hadConflict: false)
    }
    
    /// Resolve folder item (channel membership) conflicts
    /// Union of both sets - if channel is in folder on either device, keep it
    public func resolveFolderItems(
        local: [FolderItem],
        remote: [FolderItem]
    ) -> [FolderItem] {
        var merged: [String: FolderItem] = [:]
        
        // Add all local items
        for item in local {
            merged[item.id] = item
        }
        
        // Add remote items, keeping most recent if conflict
        for item in remote {
            if let existing = merged[item.id] {
                if item.addedAt > existing.addedAt {
                    merged[item.id] = item
                }
            } else {
                merged[item.id] = item
            }
        }
        
        // Reorder by position
        return merged.values.sorted { $0.order < $1.order }
    }
}

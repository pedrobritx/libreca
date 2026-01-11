import Foundation

/// Cache for EPG data
public actor EPGCache {
    
    private var programs: [String: [Program]] = [:]  // epgChannelId -> programs
    private var lastUpdate: Date?
    private var expirationInterval: TimeInterval
    
    public init(expirationInterval: TimeInterval = 3600) {  // 1 hour default
        self.expirationInterval = expirationInterval
    }
    
    /// Update cache with parsed EPG data
    public func update(with epg: ParsedEPG) {
        // Clear old data
        programs.removeAll()
        
        // Group programs by channel
        for program in epg.programs {
            programs[program.channelId, default: []].append(program)
        }
        
        // Sort programs by start time
        for channelId in programs.keys {
            programs[channelId]?.sort { $0.startTime < $1.startTime }
        }
        
        lastUpdate = Date()
    }
    
    /// Check if cache is stale
    public var isStale: Bool {
        guard let lastUpdate = lastUpdate else { return true }
        return Date().timeIntervalSince(lastUpdate) > expirationInterval
    }
    
    /// Get Now/Next for a channel (convenience method)
    public func nowNext(for channelId: String) -> NowNext? {
        return getNowNext(epgChannelId: channelId)
    }
    
    /// Get Now/Next for a channel
    public func getNowNext(epgChannelId: String, at date: Date = Date()) -> NowNext {
        guard let channelPrograms = programs[epgChannelId] else {
            return NowNext(channelId: epgChannelId, now: nil, next: nil)
        }
        
        var nowProgram: Program?
        var nextProgram: Program?
        
        for (index, program) in channelPrograms.enumerated() {
            if program.isAiring(at: date) {
                nowProgram = program
                if index + 1 < channelPrograms.count {
                    nextProgram = channelPrograms[index + 1]
                }
                break
            } else if program.startTime > date && nowProgram == nil {
                // First future program becomes "next" if nothing is airing
                nextProgram = program
                break
            }
        }
        
        return NowNext(channelId: epgChannelId, now: nowProgram, next: nextProgram)
    }
    
    /// Get all programs for a channel within a time range
    public func getPrograms(
        epgChannelId: String,
        from startDate: Date,
        to endDate: Date
    ) -> [Program] {
        guard let channelPrograms = programs[epgChannelId] else {
            return []
        }
        
        return channelPrograms.filter { program in
            // Program overlaps with the requested range
            program.endTime > startDate && program.startTime < endDate
        }
    }
    
    /// Get programs currently airing across all channels
    public func getOnNow(at date: Date = Date()) -> [Program] {
        var onNow: [Program] = []
        
        for (_, channelPrograms) in programs {
            if let current = channelPrograms.first(where: { $0.isAiring(at: date) }) {
                onNow.append(current)
            }
        }
        
        return onNow.sorted { $0.title < $1.title }
    }
    
    /// Search programs by title
    public func searchPrograms(query: String, limit: Int = 50) -> [Program] {
        let lowercaseQuery = query.lowercased()
        var results: [Program] = []
        
        for (_, channelPrograms) in programs {
            for program in channelPrograms {
                if program.title.lowercased().contains(lowercaseQuery) ||
                   program.description?.lowercased().contains(lowercaseQuery) == true {
                    results.append(program)
                    if results.count >= limit {
                        return results
                    }
                }
            }
        }
        
        return results
    }
    
    /// Clear all cached data
    public func clear() {
        programs.removeAll()
        lastUpdate = nil
    }
    
    /// Get statistics
    public var stats: (channelCount: Int, programCount: Int, lastUpdate: Date?) {
        let totalPrograms = programs.values.reduce(0) { $0 + $1.count }
        return (programs.count, totalPrograms, lastUpdate)
    }
}

import Testing
@testable import SpectraEPG
import Foundation

@Suite("EPG Models Tests")
struct EPGModelsTests {
    
    @Test("Program progress calculation")
    func programProgress() {
        let now = Date()
        let program = Program(
            channelId: "test",
            title: "Test Show",
            startTime: now.addingTimeInterval(-30 * 60), // Started 30 min ago
            endTime: now.addingTimeInterval(30 * 60)     // Ends in 30 min
        )
        
        let progress = program.progress(at: now)
        #expect(progress != nil)
        #expect(progress! >= 0.49 && progress! <= 0.51) // ~50%
    }
    
    @Test("Program airing status")
    func programAiringStatus() {
        let now = Date()
        
        let currentProgram = Program(
            channelId: "test",
            title: "Current",
            startTime: now.addingTimeInterval(-30 * 60),
            endTime: now.addingTimeInterval(30 * 60)
        )
        
        let pastProgram = Program(
            channelId: "test",
            title: "Past",
            startTime: now.addingTimeInterval(-120 * 60),
            endTime: now.addingTimeInterval(-60 * 60)
        )
        
        let futureProgram = Program(
            channelId: "test",
            title: "Future",
            startTime: now.addingTimeInterval(60 * 60),
            endTime: now.addingTimeInterval(120 * 60)
        )
        
        #expect(currentProgram.isAiring(at: now) == true)
        #expect(pastProgram.isAiring(at: now) == false)
        #expect(futureProgram.isAiring(at: now) == false)
        
        #expect(pastProgram.hasEnded(at: now) == true)
        #expect(currentProgram.hasEnded(at: now) == false)
    }
}

@Suite("EPG Cache Tests")
struct EPGCacheTests {
    
    @Test("Cache stores and retrieves Now/Next")
    func cacheNowNext() async {
        let cache = EPGCache()
        let now = Date()
        
        let programs = [
            Program(
                channelId: "ch1",
                title: "Current Show",
                startTime: now.addingTimeInterval(-30 * 60),
                endTime: now.addingTimeInterval(30 * 60)
            ),
            Program(
                channelId: "ch1",
                title: "Next Show",
                startTime: now.addingTimeInterval(30 * 60),
                endTime: now.addingTimeInterval(90 * 60)
            )
        ]
        
        let epg = ParsedEPG(channels: [], programs: programs, parseTime: 0.1)
        await cache.update(with: epg)
        
        let nowNext = await cache.getNowNext(epgChannelId: "ch1", at: now)
        
        #expect(nowNext.now?.title == "Current Show")
        #expect(nowNext.next?.title == "Next Show")
    }
    
    @Test("Cache returns empty for unknown channel")
    func cacheUnknownChannel() async {
        let cache = EPGCache()
        let nowNext = await cache.getNowNext(epgChannelId: "unknown")
        
        #expect(nowNext.now == nil)
        #expect(nowNext.next == nil)
    }
}

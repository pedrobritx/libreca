import Testing
@testable import SpectraCore
import Foundation

@Suite("M3U Parser Tests")
struct M3UParserTests {
    
    let parser = M3UParser()
    
    @Test("Parse basic M3U playlist")
    func parseBasicPlaylist() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Channel One
        http://example.com/stream1.m3u8
        #EXTINF:-1,Channel Two
        http://example.com/stream2.m3u8
        """
        
        let result = try await parser.parse(content: content)
        
        #expect(result.entries.count == 2)
        #expect(result.entries[0].name == "Channel One")
        #expect(result.entries[0].url.absoluteString == "http://example.com/stream1.m3u8")
        #expect(result.entries[1].name == "Channel Two")
    }
    
    @Test("Parse playlist with attributes")
    func parsePlaylistWithAttributes() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1 tvg-id="espn.us" tvg-name="ESPN" tvg-logo="http://logo.com/espn.png" group-title="Sports",ESPN HD
        http://example.com/espn.m3u8
        """
        
        let result = try await parser.parse(content: content)
        
        #expect(result.entries.count == 1)
        let entry = result.entries[0]
        #expect(entry.name == "ESPN HD")
        #expect(entry.tvgId == "espn.us")
        #expect(entry.tvgName == "ESPN")
        #expect(entry.tvgLogo == "http://logo.com/espn.png")
        #expect(entry.groupTitle == "Sports")
    }
    
    @Test("Parse playlist with VLC options")
    func parsePlaylistWithVLCOptions() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Protected Stream
        #EXTVLCOPT:http-user-agent=Mozilla/5.0
        #EXTVLCOPT:http-referrer=http://example.com
        http://example.com/protected.m3u8
        """
        
        let result = try await parser.parse(content: content)
        
        #expect(result.entries.count == 1)
        let entry = result.entries[0]
        #expect(entry.userAgent == "Mozilla/5.0")
        #expect(entry.referrer == "http://example.com")
    }
    
    @Test("Handle malformed entries gracefully")
    func handleMalformedEntries() async throws {
        let content = """
        #EXTM3U
        #EXTINF:-1,Good Channel
        http://example.com/good.m3u8
        #EXTINF:-1,Bad Channel
        not-a-valid-url
        #EXTINF:-1,Another Good
        http://example.com/good2.m3u8
        """
        
        let result = try await parser.parse(content: content)
        
        #expect(result.entries.count == 2)
        #expect(result.errors.count >= 1)
    }
    
    @Test("Parse large playlist efficiently")
    func parseLargePlaylist() async throws {
        // Generate a playlist with 10000 entries
        var content = "#EXTM3U\n"
        for i in 0..<10000 {
            content += "#EXTINF:-1 tvg-id=\"ch\(i)\" group-title=\"Group \(i % 100)\",Channel \(i)\n"
            content += "http://example.com/stream\(i).m3u8\n"
        }
        
        let result = try await parser.parse(content: content)
        
        #expect(result.entries.count == 10000)
        #expect(result.parseTime < 5.0) // Should parse in under 5 seconds
    }
    
    @Test("Empty playlist throws error")
    func emptyPlaylistThrows() async {
        await #expect(throws: M3UParser.ParserError.self) {
            try await parser.parse(content: "")
        }
    }
    
    @Test("Playlist with only comments throws error")
    func onlyCommentsThrows() async {
        let content = """
        #EXTM3U
        # This is a comment
        # Another comment
        """
        
        await #expect(throws: M3UParser.ParserError.self) {
            try await parser.parse(content: content)
        }
    }
}

@Suite("Channel Identity Tests")
struct ChannelIdentityTests {
    
    @Test("Generate ID from tvg-id")
    func generateIdFromTvgId() {
        let id = ChannelIdentity.generateId(
            tvgId: "espn.us",
            name: "ESPN",
            streamURL: URL(string: "http://example.com/stream.m3u8")!
        )
        
        #expect(id == "tvg:espn.us")
    }
    
    @Test("Generate ID from hash when no tvg-id")
    func generateIdFromHash() {
        let id = ChannelIdentity.generateId(
            tvgId: nil,
            name: "ESPN",
            streamURL: URL(string: "http://example.com/stream.m3u8")!
        )
        
        #expect(id.hasPrefix("hash:"))
        #expect(id.count > 10)
    }
    
    @Test("Normalize channel names")
    func normalizeNames() {
        #expect(ChannelIdentity.normalize(name: "ESPN HD") == "espn")
        #expect(ChannelIdentity.normalize(name: "CNN [4K]") == "cnn")
        #expect(ChannelIdentity.normalize(name: "BBC One +1") == "bbc one")
        #expect(ChannelIdentity.normalize(name: "  Multiple   Spaces  ") == "multiple spaces")
    }
    
    @Test("Same tvg-id produces same ID")
    func sameTvgIdSameId() {
        let id1 = ChannelIdentity.generateId(
            tvgId: "cnn.us",
            name: "CNN",
            streamURL: URL(string: "http://server1.com/cnn.m3u8")!
        )
        
        let id2 = ChannelIdentity.generateId(
            tvgId: "cnn.us",
            name: "CNN HD",
            streamURL: URL(string: "http://server2.com/cnn-hd.m3u8")!
        )
        
        #expect(id1 == id2)
    }
}

@Suite("Rule Engine Tests")
struct RuleEngineTests {
    
    let engine = RuleEngine()
    
    func makeContext(
        name: String = "Test Channel",
        group: String? = nil,
        country: String? = nil,
        language: String? = nil,
        isFavorite: Bool = false,
        healthStatus: StreamHealthStatus = .unknown
    ) -> RuleEvaluationContext {
        let channel = Channel(
            id: "test",
            name: name,
            group: group,
            country: country,
            language: language,
            sourceId: UUID()
        )
        let stream = Stream(
            channelId: "test",
            url: URL(string: "http://example.com/test.m3u8")!,
            healthStatus: healthStatus
        )
        return RuleEvaluationContext(
            channel: channel,
            streams: [stream],
            isFavorite: isFavorite
        )
    }
    
    @Test("Name contains rule")
    func nameContainsRule() {
        let rules = FolderRules.all([.nameContains("news")])
        
        #expect(engine.evaluate(rules: rules, context: makeContext(name: "CNN News")))
        #expect(!engine.evaluate(rules: rules, context: makeContext(name: "ESPN Sports")))
    }
    
    @Test("Group equals rule")
    func groupEqualsRule() {
        let rules = FolderRules.all([.groupEquals("Sports")])
        
        #expect(engine.evaluate(rules: rules, context: makeContext(group: "Sports")))
        #expect(!engine.evaluate(rules: rules, context: makeContext(group: "News")))
    }
    
    @Test("Multiple AND conditions")
    func multipleAndConditions() {
        let rules = FolderRules.all([
            .groupEquals("Sports"),
            .countryEquals("US")
        ])
        
        #expect(engine.evaluate(rules: rules, context: makeContext(group: "Sports", country: "US")))
        #expect(!engine.evaluate(rules: rules, context: makeContext(group: "Sports", country: "UK")))
    }
    
    @Test("Multiple OR conditions")
    func multipleOrConditions() {
        let rules = FolderRules.any([
            .groupEquals("Sports"),
            .groupEquals("News")
        ])
        
        #expect(engine.evaluate(rules: rules, context: makeContext(group: "Sports")))
        #expect(engine.evaluate(rules: rules, context: makeContext(group: "News")))
        #expect(!engine.evaluate(rules: rules, context: makeContext(group: "Movies")))
    }
    
    @Test("Favorites rule")
    func favoritesRule() {
        let rules = FolderRules.all([.isFavorite()])
        
        #expect(engine.evaluate(rules: rules, context: makeContext(isFavorite: true)))
        #expect(!engine.evaluate(rules: rules, context: makeContext(isFavorite: false)))
    }
    
    @Test("Health status rule")
    func healthStatusRule() {
        let deadRules = FolderRules.all([.isDead()])
        let healthyRules = FolderRules.all([.isHealthy()])
        
        #expect(engine.evaluate(rules: deadRules, context: makeContext(healthStatus: .dead)))
        #expect(!engine.evaluate(rules: deadRules, context: makeContext(healthStatus: .ok)))
        
        #expect(engine.evaluate(rules: healthyRules, context: makeContext(healthStatus: .ok)))
        #expect(engine.evaluate(rules: healthyRules, context: makeContext(healthStatus: .unknown)))
        #expect(!engine.evaluate(rules: healthyRules, context: makeContext(healthStatus: .dead)))
    }
}

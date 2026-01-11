import Foundation
import SpectraCore

/// Maps EPG channel IDs to Spectra channel IDs
public actor ChannelMapper {
    
    public struct Mapping: Codable, Sendable {
        public let spectraChannelId: String
        public let epgChannelId: String
        public let confidence: MappingConfidence
        public let isManualOverride: Bool
        
        public init(
            spectraChannelId: String,
            epgChannelId: String,
            confidence: MappingConfidence,
            isManualOverride: Bool = false
        ) {
            self.spectraChannelId = spectraChannelId
            self.epgChannelId = epgChannelId
            self.confidence = confidence
            self.isManualOverride = isManualOverride
        }
    }
    
    public enum MappingConfidence: String, Codable, Sendable {
        case exact      // tvg-id matches exactly
        case high       // Normalized name matches
        case medium     // Fuzzy name match
        case low        // Best guess
        case manual     // User override
    }
    
    private var mappings: [String: Mapping] = [:]  // spectraChannelId -> Mapping
    private var reverseMappings: [String: String] = [:]  // epgChannelId -> spectraChannelId
    
    public init() {}
    
    /// Add a manual mapping override
    public func setManualMapping(spectraChannelId: String, epgChannelId: String) {
        let mapping = Mapping(
            spectraChannelId: spectraChannelId,
            epgChannelId: epgChannelId,
            confidence: .manual,
            isManualOverride: true
        )
        mappings[spectraChannelId] = mapping
        reverseMappings[epgChannelId] = spectraChannelId
    }
    
    /// Remove a manual mapping
    public func removeMapping(spectraChannelId: String) {
        if let mapping = mappings[spectraChannelId] {
            reverseMappings.removeValue(forKey: mapping.epgChannelId)
        }
        mappings.removeValue(forKey: spectraChannelId)
    }
    
    /// Auto-map channels from EPG to Spectra channels
    public func autoMap(
        spectraChannels: [Channel],
        epgChannels: [EPGChannel]
    ) -> [Mapping] {
        var newMappings: [Mapping] = []
        
        for spectraChannel in spectraChannels {
            // Skip if already has manual mapping
            if let existing = mappings[spectraChannel.id], existing.isManualOverride {
                continue
            }
            
            if let mapping = findBestMatch(spectraChannel: spectraChannel, epgChannels: epgChannels) {
                mappings[spectraChannel.id] = mapping
                reverseMappings[mapping.epgChannelId] = spectraChannel.id
                newMappings.append(mapping)
            }
        }
        
        return newMappings
    }
    
    /// Get EPG channel ID for a Spectra channel
    public func getEPGChannelId(for spectraChannelId: String) -> String? {
        mappings[spectraChannelId]?.epgChannelId
    }
    
    /// Get Spectra channel ID for an EPG channel
    public func getSpectraChannelId(for epgChannelId: String) -> String? {
        reverseMappings[epgChannelId]
    }
    
    /// Get all mappings
    public func getAllMappings() -> [Mapping] {
        Array(mappings.values)
    }
    
    // MARK: - Private
    
    private func findBestMatch(
        spectraChannel: Channel,
        epgChannels: [EPGChannel]
    ) -> Mapping? {
        // 1. Exact tvg-id match
        if let tvgId = spectraChannel.tvgId {
            if let epgChannel = epgChannels.first(where: { $0.id == tvgId }) {
                return Mapping(
                    spectraChannelId: spectraChannel.id,
                    epgChannelId: epgChannel.id,
                    confidence: .exact
                )
            }
        }
        
        // 2. Normalized name match
        let normalizedName = normalize(spectraChannel.name)
        
        for epgChannel in epgChannels {
            let normalizedEPGName = normalize(epgChannel.displayName)
            
            if normalizedName == normalizedEPGName {
                return Mapping(
                    spectraChannelId: spectraChannel.id,
                    epgChannelId: epgChannel.id,
                    confidence: .high
                )
            }
        }
        
        // 3. Fuzzy match
        var bestMatch: (epgChannel: EPGChannel, score: Double)?
        
        for epgChannel in epgChannels {
            let score = similarity(normalize(spectraChannel.name), normalize(epgChannel.displayName))
            
            if score > 0.8 {
                if bestMatch == nil || score > bestMatch!.score {
                    bestMatch = (epgChannel, score)
                }
            }
        }
        
        if let match = bestMatch {
            return Mapping(
                spectraChannelId: spectraChannel.id,
                epgChannelId: match.epgChannel.id,
                confidence: match.score > 0.9 ? .medium : .low
            )
        }
        
        return nil
    }
    
    private func normalize(_ name: String) -> String {
        var result = name.lowercased()
        
        // Remove common suffixes
        let removals = ["hd", "sd", "fhd", "uhd", "4k", "+1", "+2", "(hd)", "[hd]"]
        for removal in removals {
            result = result.replacingOccurrences(of: " \(removal)", with: "")
            result = result.replacingOccurrences(of: "\(removal)", with: "")
        }
        
        // Remove special characters
        result = result.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: " ")
        
        // Normalize whitespace
        result = result.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    private func similarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1.0 }
        if a.isEmpty || b.isEmpty { return 0.0 }
        
        let longer = a.count > b.count ? a : b
        let shorter = a.count > b.count ? b : a
        
        if longer.contains(shorter) {
            return Double(shorter.count) / Double(longer.count)
        }
        
        // Levenshtein-like similarity
        let distance = levenshteinDistance(a, b)
        let maxLen = max(a.count, b.count)
        return 1.0 - (Double(distance) / Double(maxLen))
    }
    
    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bChars.count + 1), count: aChars.count + 1)
        
        for i in 0...aChars.count {
            matrix[i][0] = i
        }
        for j in 0...bChars.count {
            matrix[0][j] = j
        }
        
        for i in 1...aChars.count {
            for j in 1...bChars.count {
                let cost = aChars[i-1] == bChars[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        
        return matrix[aChars.count][bChars.count]
    }
}

import Foundation
import CryptoKit

/// Utilities for generating stable channel identifiers
public struct ChannelIdentity: Sendable {
    
    /// Generate a stable ID for a channel
    /// - Parameters:
    ///   - tvgId: The tvg-id attribute if available
    ///   - name: Channel name
    ///   - streamURL: Primary stream URL
    /// - Returns: A stable identifier string
    public static func generateId(
        tvgId: String?,
        name: String,
        streamURL: URL
    ) -> String {
        // Prefer tvg-id if available and not empty
        if let tvgId = tvgId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !tvgId.isEmpty {
            return "tvg:\(tvgId)"
        }
        
        // Otherwise, compute hash from normalized name + stream host/path
        let normalizedName = normalize(name: name)
        let streamKey = extractStreamKey(from: streamURL)
        let combined = "\(normalizedName)|\(streamKey)"
        
        return "hash:\(sha256Hash(combined))"
    }
    
    /// Normalize a channel name for consistent matching
    public static func normalize(name: String) -> String {
        var normalized = name.lowercased()
        
        // Remove common suffixes/prefixes
        let removals = ["hd", "sd", "fhd", "uhd", "4k", "hevc", "h.264", "h264", "+1", "+2"]
        for removal in removals {
            normalized = normalized.replacingOccurrences(of: " \(removal)", with: "")
            normalized = normalized.replacingOccurrences(of: "(\(removal))", with: "")
            normalized = normalized.replacingOccurrences(of: "[\(removal)]", with: "")
        }
        
        // Remove extra whitespace
        normalized = normalized.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        // Remove special characters except alphanumeric and space
        normalized = normalized.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) || $0 == " " }
            .map { String($0) }
            .joined()
        
        return normalized.trimmingCharacters(in: .whitespaces)
    }
    
    /// Extract key components from a stream URL for identity
    private static func extractStreamKey(from url: URL) -> String {
        // Use host + path without query parameters or timestamps
        let host = url.host ?? ""
        var path = url.path
        
        // Remove common variable segments (tokens, timestamps)
        let variablePatterns = [
            #"/\d{10,}/"#,  // Unix timestamps
            #"/[a-f0-9]{32,}/"#,  // Hex tokens
        ]
        
        for pattern in variablePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                path = regex.stringByReplacingMatches(
                    in: path,
                    range: NSRange(path.startIndex..., in: path),
                    withTemplate: "/"
                )
            }
        }
        
        return "\(host)\(path)".lowercased()
    }
    
    /// Compute SHA256 hash and return first 16 characters
    private static func sha256Hash(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
    
    /// Check if two channels are likely the same (fuzzy matching)
    public static func areLikelySame(
        _ a: (name: String, streamURL: URL),
        _ b: (name: String, streamURL: URL)
    ) -> Bool {
        // Same normalized name
        let normalizedA = normalize(name: a.name)
        let normalizedB = normalize(name: b.name)
        
        if normalizedA == normalizedB {
            return true
        }
        
        // Same host and similar path
        if a.streamURL.host == b.streamURL.host {
            let pathA = a.streamURL.path
            let pathB = b.streamURL.path
            
            // Levenshtein distance or simple similarity
            let similarity = stringSimilarity(pathA, pathB)
            if similarity > 0.8 {
                return true
            }
        }
        
        return false
    }
    
    /// Simple string similarity (0.0 to 1.0)
    private static func stringSimilarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1.0 }
        if a.isEmpty || b.isEmpty { return 0.0 }
        
        let longer = a.count > b.count ? a : b
        let shorter = a.count > b.count ? b : a
        
        if longer.contains(shorter) {
            return Double(shorter.count) / Double(longer.count)
        }
        
        // Common prefix ratio
        var commonPrefix = 0
        let longerChars = Array(longer)
        let shorterChars = Array(shorter)
        
        for i in 0..<min(longerChars.count, shorterChars.count) {
            if longerChars[i] == shorterChars[i] {
                commonPrefix += 1
            } else {
                break
            }
        }
        
        return Double(commonPrefix) / Double(longer.count)
    }
}

import Foundation

/// High-performance M3U/M3U8 playlist parser
public actor M3UParser {
    
    public enum ParserError: Error, Sendable {
        case invalidData
        case emptyPlaylist
        case noValidEntries
        case networkError(Error)
        case fileReadError(Error)
    }
    
    public init() {}
    
    // MARK: - Public API
    
    /// Parse M3U content from a URL
    public func parse(url: URL) async throws -> ParsedPlaylist {
        let data: Data
        
        if url.isFileURL {
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw ParserError.fileReadError(error)
            }
        } else {
            do {
                let (fetchedData, _) = try await URLSession.shared.data(from: url)
                data = fetchedData
            } catch {
                throw ParserError.networkError(error)
            }
        }
        
        return try await parse(data: data)
    }
    
    /// Parse M3U content from raw data
    public func parse(data: Data) async throws -> ParsedPlaylist {
        guard let content = String(data: data, encoding: .utf8) ??
                           String(data: data, encoding: .isoLatin1) else {
            throw ParserError.invalidData
        }
        
        return try await parse(content: content)
    }
    
    /// Parse M3U content from a string
    public func parse(content: String) async throws -> ParsedPlaylist {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let lines = content.components(separatedBy: .newlines)
        
        guard !lines.isEmpty else {
            throw ParserError.emptyPlaylist
        }
        
        var entries: [M3UEntry] = []
        var errors: [M3UParseError] = []
        var currentExtInf: ExtInfLine? = nil
        var currentExtras: [String: String] = [:]
        
        // Pre-allocate for performance (estimate ~1 entry per 3 lines)
        entries.reserveCapacity(lines.count / 3)
        
        for (index, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and comments (except #EXTINF and other directives)
            if line.isEmpty {
                continue
            }
            
            // Parse #EXTM3U header
            if line.hasPrefix("#EXTM3U") {
                continue
            }
            
            // Parse #EXTINF line
            if line.hasPrefix("#EXTINF:") {
                do {
                    currentExtInf = try parseExtInf(line: line)
                } catch {
                    errors.append(M3UParseError(
                        line: index + 1,
                        message: "Failed to parse EXTINF: \(error)",
                        rawContent: line
                    ))
                }
                continue
            }
            
            // Parse #EXTVLCOPT (VLC options like http-user-agent)
            if line.hasPrefix("#EXTVLCOPT:") {
                let option = parseVLCOption(line: line)
                if let (key, value) = option {
                    currentExtras[key] = value
                }
                continue
            }
            
            // Parse #EXTGRP (group override)
            if line.hasPrefix("#EXTGRP:") {
                let group = String(line.dropFirst("#EXTGRP:".count))
                    .trimmingCharacters(in: .whitespaces)
                if !group.isEmpty {
                    currentExtras["group-override"] = group
                }
                continue
            }
            
            // Skip other directives
            if line.hasPrefix("#") {
                continue
            }
            
            // This should be a URL line
            guard let url = URL(string: line), url.scheme != nil else {
                // Not a valid URL, skip
                if currentExtInf != nil {
                    errors.append(M3UParseError(
                        line: index + 1,
                        message: "Invalid URL after EXTINF",
                        rawContent: line
                    ))
                }
                currentExtInf = nil
                currentExtras = [:]
                continue
            }
            
            // Create entry from EXTINF + URL
            if let extInf = currentExtInf {
                let entry = M3UEntry(
                    name: extInf.title,
                    url: url,
                    duration: extInf.duration,
                    tvgId: extInf.attributes["tvg-id"],
                    tvgName: extInf.attributes["tvg-name"],
                    tvgLogo: extInf.attributes["tvg-logo"],
                    groupTitle: currentExtras["group-override"] ?? extInf.attributes["group-title"],
                    language: extInf.attributes["tvg-language"],
                    country: extInf.attributes["tvg-country"],
                    userAgent: currentExtras["http-user-agent"],
                    referrer: currentExtras["http-referrer"],
                    extraAttributes: extInf.attributes
                )
                entries.append(entry)
            } else {
                // URL without EXTINF - create minimal entry
                let name = url.lastPathComponent.isEmpty ? url.host ?? "Unknown" : url.lastPathComponent
                let entry = M3UEntry(name: name, url: url)
                entries.append(entry)
            }
            
            currentExtInf = nil
            currentExtras = [:]
        }
        
        let parseTime = CFAbsoluteTimeGetCurrent() - startTime
        
        guard !entries.isEmpty else {
            throw ParserError.noValidEntries
        }
        
        return ParsedPlaylist(entries: entries, parseTime: parseTime, errors: errors)
    }
    
    // MARK: - Private Parsing Helpers
    
    private struct ExtInfLine {
        let duration: Int?
        let title: String
        let attributes: [String: String]
    }
    
    /// Parse #EXTINF line
    /// Format: #EXTINF:duration attribute="value" ...,Title
    private func parseExtInf(line: String) throws -> ExtInfLine {
        // Remove #EXTINF: prefix
        let content = String(line.dropFirst("#EXTINF:".count))
        
        // Find the comma separating attributes from title
        guard let commaIndex = findTitleSeparator(in: content) else {
            // No comma - might be just duration
            let duration = Int(content.trimmingCharacters(in: .whitespaces))
            return ExtInfLine(duration: duration, title: "Unknown", attributes: [:])
        }
        
        let attributePart = String(content[..<commaIndex])
        let title = String(content[content.index(after: commaIndex)...])
            .trimmingCharacters(in: .whitespaces)
        
        // Parse duration (first number before space or first attribute)
        var duration: Int? = nil
        var attributeString = attributePart
        
        if let spaceIndex = attributePart.firstIndex(of: " ") {
            let durationStr = String(attributePart[..<spaceIndex])
            duration = Int(durationStr) ?? Int(durationStr.replacingOccurrences(of: "-", with: ""))
            attributeString = String(attributePart[spaceIndex...])
        } else {
            duration = Int(attributePart)
            attributeString = ""
        }
        
        // Parse attributes
        let attributes = parseAttributes(from: attributeString)
        
        return ExtInfLine(duration: duration, title: title, attributes: attributes)
    }
    
    /// Find the comma that separates attributes from title
    /// Must handle commas inside quoted attribute values
    private func findTitleSeparator(in content: String) -> String.Index? {
        var inQuotes = false
        var quoteChar: Character = "\""
        
        for (index, char) in content.enumerated() {
            if (char == "\"" || char == "'") && !inQuotes {
                inQuotes = true
                quoteChar = char
            } else if char == quoteChar && inQuotes {
                inQuotes = false
            } else if char == "," && !inQuotes {
                return content.index(content.startIndex, offsetBy: index)
            }
        }
        
        return nil
    }
    
    /// Parse key="value" attributes from a string
    private func parseAttributes(from string: String) -> [String: String] {
        var attributes: [String: String] = [:]
        
        // Regex pattern for key="value" or key='value'
        let pattern = #"([a-zA-Z0-9_-]+)\s*=\s*["']([^"']*)["']"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return attributes
        }
        
        let range = NSRange(string.startIndex..., in: string)
        let matches = regex.matches(in: string, options: [], range: range)
        
        for match in matches {
            guard match.numberOfRanges >= 3,
                  let keyRange = Range(match.range(at: 1), in: string),
                  let valueRange = Range(match.range(at: 2), in: string) else {
                continue
            }
            
            let key = String(string[keyRange]).lowercased()
            let value = String(string[valueRange])
            attributes[key] = value
        }
        
        return attributes
    }
    
    /// Parse #EXTVLCOPT line
    private func parseVLCOption(line: String) -> (String, String)? {
        let content = String(line.dropFirst("#EXTVLCOPT:".count))
        
        guard let equalsIndex = content.firstIndex(of: "=") else {
            return nil
        }
        
        let key = String(content[..<equalsIndex]).trimmingCharacters(in: .whitespaces)
        let value = String(content[content.index(after: equalsIndex)...])
            .trimmingCharacters(in: .whitespaces)
        
        return (key, value)
    }
}

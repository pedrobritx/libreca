import Foundation

/// XMLTV parser for EPG data
public actor XMLTVParser {
    
    public enum ParserError: Error, Sendable {
        case invalidData
        case parseError(String)
        case networkError(Error)
    }
    
    public init() {}
    
    /// Parse XMLTV from URL
    public func parse(url: URL) async throws -> ParsedEPG {
        let data: Data
        
        if url.isFileURL {
            data = try Data(contentsOf: url)
        } else {
            let (fetchedData, _) = try await URLSession.shared.data(from: url)
            data = fetchedData
        }
        
        return try await parse(data: data)
    }
    
    /// Parse XMLTV from data
    public func parse(data: Data) async throws -> ParsedEPG {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let parser = XMLTVParserDelegate()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        
        guard xmlParser.parse() else {
            throw ParserError.parseError(xmlParser.parserError?.localizedDescription ?? "Unknown error")
        }
        
        let parseTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return ParsedEPG(
            channels: parser.channels,
            programs: parser.programs,
            parseTime: parseTime
        )
    }
}

/// XMLParser delegate for XMLTV format
private class XMLTVParserDelegate: NSObject, XMLParserDelegate {
    
    var channels: [EPGChannel] = []
    var programs: [Program] = []
    
    private var currentElement = ""
    private var currentChannelId = ""
    private var currentDisplayName = ""
    private var currentIconURL: URL?
    
    private var currentProgram: ProgramBuilder?
    private var currentText = ""
    
    private struct ProgramBuilder {
        var channelId: String
        var start: Date?
        var stop: Date?
        var title: String = ""
        var subtitle: String?
        var description: String?
        var category: String?
        var iconURL: URL?
        var rating: String?
        var episodeNum: String?
        var seasonNum: String?
    }
    
    // Date formatter for XMLTV dates (yyyyMMddHHmmss +0000)
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    private lazy var altDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
        
        switch elementName {
        case "channel":
            currentChannelId = attributeDict["id"] ?? ""
            currentDisplayName = ""
            currentIconURL = nil
            
        case "programme":
            let channelId = attributeDict["channel"] ?? ""
            let startStr = attributeDict["start"] ?? ""
            let stopStr = attributeDict["stop"] ?? ""
            
            currentProgram = ProgramBuilder(
                channelId: channelId,
                start: parseDate(startStr),
                stop: parseDate(stopStr)
            )
            
        case "icon":
            if let src = attributeDict["src"] {
                let url = URL(string: src)
                if currentProgram != nil {
                    currentProgram?.iconURL = url
                } else {
                    currentIconURL = url
                }
            }
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "channel":
            if !currentChannelId.isEmpty && !currentDisplayName.isEmpty {
                let channel = EPGChannel(
                    id: currentChannelId,
                    displayName: currentDisplayName,
                    iconURL: currentIconURL
                )
                channels.append(channel)
            }
            
        case "display-name":
            if currentProgram == nil {
                currentDisplayName = trimmedText
            }
            
        case "programme":
            if var builder = currentProgram,
               let start = builder.start,
               let stop = builder.stop,
               !builder.title.isEmpty {
                let program = Program(
                    channelId: builder.channelId,
                    title: builder.title,
                    subtitle: builder.subtitle,
                    description: builder.description,
                    category: builder.category,
                    startTime: start,
                    endTime: stop,
                    iconURL: builder.iconURL,
                    rating: builder.rating,
                    episodeNumber: builder.episodeNum,
                    seasonNumber: builder.seasonNum
                )
                programs.append(program)
            }
            currentProgram = nil
            
        case "title":
            currentProgram?.title = trimmedText
            
        case "sub-title":
            currentProgram?.subtitle = trimmedText
            
        case "desc":
            currentProgram?.description = trimmedText
            
        case "category":
            currentProgram?.category = trimmedText
            
        case "rating":
            currentProgram?.rating = trimmedText
            
        case "episode-num":
            currentProgram?.episodeNum = trimmedText
            
        default:
            break
        }
        
        currentText = ""
    }
    
    private func parseDate(_ string: String) -> Date? {
        // Try with timezone first
        if let date = dateFormatter.date(from: string) {
            return date
        }
        // Try without timezone
        let cleanString = string.components(separatedBy: " ").first ?? string
        return altDateFormatter.date(from: cleanString)
    }
}

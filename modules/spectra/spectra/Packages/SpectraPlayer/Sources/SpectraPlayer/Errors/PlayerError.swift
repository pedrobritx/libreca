import Foundation
import SpectraCore

/// Player error types with user-friendly descriptions
public enum PlayerError: Error, Sendable, Equatable {
    case invalidURL
    case networkTimeout
    case networkError(code: Int)
    case httpError(statusCode: Int)
    case unsupportedFormat
    case decodingFailed
    case drmProtected
    case geoBlocked
    case serverError
    case unknown(String)
    
    public var title: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkTimeout:
            return "Connection Timeout"
        case .networkError:
            return "Network Error"
        case .httpError(let code):
            switch code {
            case 403: return "Access Denied"
            case 404: return "Stream Not Found"
            case 410: return "Stream No Longer Available"
            case 500...599: return "Server Error"
            default: return "HTTP Error \(code)"
            }
        case .unsupportedFormat:
            return "Unsupported Format"
        case .decodingFailed:
            return "Playback Failed"
        case .drmProtected:
            return "DRM Protected"
        case .geoBlocked:
            return "Geo-Restricted"
        case .serverError:
            return "Server Error"
        case .unknown:
            return "Playback Error"
        }
    }
    
    public var description: String {
        switch self {
        case .invalidURL:
            return "The stream URL is invalid or malformed."
        case .networkTimeout:
            return "The connection timed out. Check your internet connection."
        case .networkError(let code):
            return "Network error occurred (code: \(code)). Check your connection."
        case .httpError(let code):
            switch code {
            case 403:
                return "You don't have permission to access this stream."
            case 404:
                return "The stream could not be found on the server."
            case 410:
                return "This stream has been removed or is no longer available."
            case 500...599:
                return "The streaming server is experiencing issues."
            default:
                return "Server returned error code \(code)."
            }
        case .unsupportedFormat:
            return "This stream format is not supported. Spectra works best with HLS (.m3u8) streams."
        case .decodingFailed:
            return "Unable to decode the stream. The format may be unsupported or corrupted."
        case .drmProtected:
            return "This stream uses DRM protection and cannot be played."
        case .geoBlocked:
            return "This content is not available in your region."
        case .serverError:
            return "The streaming server returned an error."
        case .unknown(let message):
            return message.isEmpty ? "An unknown error occurred." : message
        }
    }
    
    public var isRecoverable: Bool {
        switch self {
        case .networkTimeout, .networkError, .serverError:
            return true
        case .invalidURL, .unsupportedFormat, .drmProtected, .geoBlocked:
            return false
        case .httpError(let code):
            return code >= 500 // Server errors might be temporary
        case .decodingFailed, .unknown:
            return false
        }
    }
    
    /// Map from NSError/AVPlayer error codes
    public static func from(nsError: NSError) -> PlayerError {
        let code = nsError.code
        let domain = nsError.domain
        
        // Network errors
        if domain == NSURLErrorDomain {
            switch code {
            case NSURLErrorTimedOut:
                return .networkTimeout
            case NSURLErrorCannotConnectToHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet:
                return .networkError(code: code)
            case NSURLErrorBadURL:
                return .invalidURL
            default:
                return .networkError(code: code)
            }
        }
        
        // AVFoundation errors
        if domain == "AVFoundationErrorDomain" {
            switch code {
            case -11800: // AVErrorUnknown
                return .unknown(nsError.localizedDescription)
            case -11828: // AVErrorDecoderNotFound
                return .unsupportedFormat
            case -11833: // AVErrorFailedToParse
                return .decodingFailed
            default:
                return .unknown(nsError.localizedDescription)
            }
        }
        
        return .unknown(nsError.localizedDescription)
    }
}

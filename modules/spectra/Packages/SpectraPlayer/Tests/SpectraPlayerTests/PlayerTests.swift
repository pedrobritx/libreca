import Testing
@testable import SpectraPlayer
import Foundation

@Suite("PlayerError Tests")
struct PlayerErrorTests {
    
    @Test("Error titles are user-friendly")
    func errorTitles() {
        #expect(PlayerError.invalidURL.title == "Invalid URL")
        #expect(PlayerError.networkTimeout.title == "Connection Timeout")
        #expect(PlayerError.httpError(statusCode: 403).title == "Access Denied")
        #expect(PlayerError.httpError(statusCode: 404).title == "Stream Not Found")
        #expect(PlayerError.unsupportedFormat.title == "Unsupported Format")
    }
    
    @Test("Recoverability is correct")
    func recoverability() {
        #expect(PlayerError.networkTimeout.isRecoverable == true)
        #expect(PlayerError.serverError.isRecoverable == true)
        #expect(PlayerError.invalidURL.isRecoverable == false)
        #expect(PlayerError.drmProtected.isRecoverable == false)
        #expect(PlayerError.httpError(statusCode: 500).isRecoverable == true)
        #expect(PlayerError.httpError(statusCode: 403).isRecoverable == false)
    }
}

@Suite("PlaybackState Tests")
struct PlaybackStateTests {
    
    @Test("Active states")
    func activeStates() {
        #expect(PlaybackState.playing.isActive == true)
        #expect(PlaybackState.buffering.isActive == true)
        #expect(PlaybackState.paused.isActive == false)
        #expect(PlaybackState.idle.isActive == false)
    }
    
    @Test("Can play states")
    func canPlayStates() {
        #expect(PlaybackState.ready.canPlay == true)
        #expect(PlaybackState.paused.canPlay == true)
        #expect(PlaybackState.ended.canPlay == true)
        #expect(PlaybackState.playing.canPlay == false)
        #expect(PlaybackState.loading.canPlay == false)
    }
}

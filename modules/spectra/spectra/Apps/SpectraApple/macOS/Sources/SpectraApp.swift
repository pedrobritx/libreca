import SwiftUI
import SpectraCore
import SpectraLibrary
import SpectraPlayer
import SpectraSync
import SpectraEPG
import SpectraUI

@main
struct SpectraApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import M3U...") {
                    appState.showImportSheet = true
                }
                .keyboardShortcut("i", modifiers: [.command])
                
                Button("Import from URL...") {
                    appState.showURLImportSheet = true
                }
                .keyboardShortcut("u", modifiers: [.command])
            }
            
            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    NSApp.keyWindow?.firstResponder?
                        .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
            
            CommandMenu("Playback") {
                Button("Play/Pause") {
                    appState.playerEngine.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Divider()
                
                Button("Previous Channel") {
                    appState.previousChannel()
                }
                .keyboardShortcut(.upArrow, modifiers: [])
                
                Button("Next Channel") {
                    appState.nextChannel()
                }
                .keyboardShortcut(.downArrow, modifiers: [])
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

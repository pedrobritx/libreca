import SwiftUI
import SpectraUI

/// Main content view with split navigation
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            ChannelListPane()
        } detail: {
            PlayerPane()
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $appState.showImportSheet) {
            ImportSheetView()
        }
        .sheet(isPresented: $appState.showURLImportSheet) {
            URLImportSheetView()
        }
    }
}

/// Sidebar with sources and folders
struct SidebarView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List(selection: $appState.selectedFolder) {
            Section("Library") {
                Label("All Channels", systemImage: "tv")
                    .tag(nil as Folder?)
                
                Label("Favorites", systemImage: "star.fill")
                    .foregroundColor(.yellow)
                
                Label("Recently Watched", systemImage: "clock")
            }
            
            Section("Folders") {
                ForEach(appState.folders) { folder in
                    FolderRow(
                        folder: folder,
                        channelCount: channelCount(for: folder),
                        isSelected: appState.selectedFolder?.id == folder.id,
                        onTap: { appState.selectedFolder = folder }
                    )
                    .tag(folder as Folder?)
                }
            }
            
            Section("Sources") {
                ForEach(appState.sources) { source in
                    Label(source.name, systemImage: "antenna.radiowaves.left.and.right")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Spectra")
        .toolbar {
            ToolbarItem {
                Button(action: { appState.showImportSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private func channelCount(for folder: Folder) -> Int {
        // Simplified - would need proper implementation
        return appState.channels.count / 10
    }
}

/// Channel list pane
struct ChannelListPane: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ChannelListView(
            searchText: $appState.searchText,
            channels: appState.filteredChannels
        ) { channel in
            ChannelRow(
                channel: channel,
                isPlaying: appState.selectedChannel?.id == channel.id,
                isFavorite: false, // Would check from library
                healthStatus: .unknown, // Would fetch from streams
                nowPlaying: nowPlaying(for: channel),
                onTap: { appState.playChannel(channel) },
                onFavorite: { toggleFavorite(channel) }
            )
        }
        .navigationTitle(appState.selectedFolder?.name ?? "All Channels")
    }
    
    private func nowPlaying(for channel: Channel) -> String? {
        appState.epgCache.nowNext(for: channel.id)?.now?.title
    }
    
    private func toggleFavorite(_ channel: Channel) {
        // Would toggle favorite in library
    }
}

/// Player pane with video
struct PlayerPane: View {
    @EnvironmentObject private var appState: AppState
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            // Video player
            PlayerView(player: appState.playerEngine.player)
                .background(Color.black)
            
            // Controls overlay
            if showControls {
                VStack {
                    Spacer()
                    
                    // Now/Next info
                    if let channel = appState.selectedChannel,
                       let nowNext = appState.epgCache.nowNext(for: channel.id) {
                        HStack {
                            NowNextOverlay(
                                nowNext: nowNext,
                                channelName: channel.name
                            )
                            Spacer()
                        }
                        .padding()
                    }
                }
                
                // Player controls
                PlayerControlsOverlay(
                    isPlaying: appState.playerEngine.isPlaying,
                    channelName: appState.selectedChannel?.name ?? "No Channel",
                    onPlayPause: { appState.playerEngine.togglePlayPause() },
                    onPrevious: { appState.previousChannel() },
                    onNext: { appState.nextChannel() }
                )
            }
        }
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
        .onHover { hovering in
            withAnimation {
                showControls = hovering
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

import SwiftUI

/// Settings view
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            PlaybackSettingsView()
                .tabItem {
                    Label("Playback", systemImage: "play.circle")
                }
            
            SyncSettingsView()
                .tabItem {
                    Label("Sync", systemImage: "icloud")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
        }
        .frame(width: 500, height: 350)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("autoRefreshSources") private var autoRefreshSources = true
    @AppStorage("refreshInterval") private var refreshInterval = 24 // hours
    @AppStorage("showChannelCount") private var showChannelCount = true
    
    var body: some View {
        Form {
            Toggle("Auto-refresh sources", isOn: $autoRefreshSources)
            
            if autoRefreshSources {
                Picker("Refresh interval", selection: $refreshInterval) {
                    Text("Every 6 hours").tag(6)
                    Text("Every 12 hours").tag(12)
                    Text("Every 24 hours").tag(24)
                    Text("Every 48 hours").tag(48)
                }
            }
            
            Divider()
            
            Toggle("Show channel count in sidebar", isOn: $showChannelCount)
        }
        .padding()
    }
}

struct PlaybackSettingsView: View {
    @AppStorage("preferredQuality") private var preferredQuality = "auto"
    @AppStorage("bufferSize") private var bufferSize = 30.0 // seconds
    @AppStorage("autoPlay") private var autoPlay = true
    
    var body: some View {
        Form {
            Picker("Preferred quality", selection: $preferredQuality) {
                Text("Auto").tag("auto")
                Text("1080p").tag("1080p")
                Text("720p").tag("720p")
                Text("480p").tag("480p")
            }
            
            VStack(alignment: .leading) {
                Text("Buffer size: \(Int(bufferSize)) seconds")
                Slider(value: $bufferSize, in: 10...120, step: 5)
            }
            
            Divider()
            
            Toggle("Auto-play when selecting channel", isOn: $autoPlay)
        }
        .padding()
    }
}

struct SyncSettingsView: View {
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = true
    @AppStorage("syncFavorites") private var syncFavorites = true
    @AppStorage("syncFolders") private var syncFolders = true
    @AppStorage("syncHistory") private var syncHistory = false
    
    var body: some View {
        Form {
            Toggle("Enable iCloud Sync", isOn: $cloudSyncEnabled)
            
            if cloudSyncEnabled {
                Section("Sync Options") {
                    Toggle("Favorites", isOn: $syncFavorites)
                    Toggle("Folders", isOn: $syncFolders)
                    Toggle("Watch History", isOn: $syncHistory)
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Sync Now") {
                    // Trigger manual sync
                }
            }
        }
        .padding()
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("enableHealthChecks") private var enableHealthChecks = true
    @AppStorage("healthCheckInterval") private var healthCheckInterval = 60 // minutes
    @AppStorage("userAgent") private var userAgent = "Spectra/1.0"
    
    var body: some View {
        Form {
            Toggle("Enable stream health checks", isOn: $enableHealthChecks)
            
            if enableHealthChecks {
                Picker("Check interval", selection: $healthCheckInterval) {
                    Text("Every 30 minutes").tag(30)
                    Text("Every hour").tag(60)
                    Text("Every 2 hours").tag(120)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Custom User-Agent")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("User-Agent", text: $userAgent)
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            HStack {
                Button("Clear Cache") {
                    // Clear cache
                }
                
                Button("Reset All Settings") {
                    // Reset settings
                }
                .foregroundColor(.red)
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}

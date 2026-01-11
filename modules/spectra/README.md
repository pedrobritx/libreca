# Spectra

A **bring-your-own-source IPTV client** for Apple platforms (macOS, iOS, iPadOS, tvOS).

## Overview

Spectra is a modern IPTV client designed for users who have their own M3U playlists. It provides a premium viewing experience with features like smart folders, EPG integration, CloudKit sync, and stream health monitoring.

**Key differentiator**: Spectra never hosts or curates content. Users bring their own M3U URLs, and the app provides the best possible playback experience.

## Features

### MVP (v1.0)

- ✅ **M3U Import**: Import playlists from URLs or local files
- ✅ **HLS Playback**: First-class HLS streaming support via AVPlayer
- ✅ **Manual Folders**: Organize channels into custom folders
- ✅ **Favorites**: Mark and quickly access favorite channels
- ✅ **CloudKit Sync**: Sync preferences across devices
- ✅ **Stream Health**: Monitor and display stream health status

### Future Releases

- 📺 EPG/XMLTV integration
- 🔍 Smart folders with rule-based filtering
- 📱 iOS/iPadOS/tvOS apps
- ⏪ Catch-up/timeshift support
- 📹 Series/VOD organization

## Architecture

```
spectra/
├── Packages/
│   ├── SpectraCore/      # Pure Swift models, parsing, identity
│   ├── SpectraLibrary/   # Persistence layer (Core Data)
│   ├── SpectraPlayer/    # AVPlayer abstraction, health checks
│   ├── SpectraSync/      # CloudKit integration
│   ├── SpectraEPG/       # XMLTV parsing, channel mapping
│   └── SpectraUI/        # Shared SwiftUI components
├── Apps/
│   └── SpectraApple/
│       ├── macOS/        # macOS app
│       ├── iOS/          # iOS/iPadOS app (future)
│       └── tvOS/         # tvOS app (future)
└── Tools/
    └── Fixtures/         # Test playlists and EPG data
```

## Requirements

- **macOS**: 14.0+ (Sonoma)
- **iOS/iPadOS**: 17.0+ (future)
- **tvOS**: 17.0+ (future)
- **Xcode**: 15.0+
- **Swift**: 5.9+

## Building

### Using Swift Package Manager

```bash
# Build all packages
swift build

# Run tests
swift test

# Build macOS app
cd Apps/SpectraApple/macOS
swift build
```

### Using Xcode

1. Open the workspace: `open spectra.xcworkspace`
2. Select the `Spectra (macOS)` scheme
3. Build and run (⌘R)

## Project Structure

### Packages

| Package            | Purpose                                                                                       |
| ------------------ | --------------------------------------------------------------------------------------------- |
| **SpectraCore**    | Data models (Source, Channel, Stream, Folder), M3U parsing, stable ID generation, rule engine |
| **SpectraLibrary** | LibraryStore protocol, Core Data persistence, import pipeline                                 |
| **SpectraPlayer**  | PlayerEngine (AVPlayer wrapper), playback state machine, stream health checker                |
| **SpectraSync**    | CloudSyncManager, syncable model conformances, conflict resolution                            |
| **SpectraEPG**     | EPGModels, XMLTV parser, channel-to-EPG mapping, EPG cache                                    |
| **SpectraUI**      | Reusable SwiftUI components: ChannelRow, FolderRow, PlayerControls, NowNextOverlay            |

### Key Design Decisions

1. **Stable Channel IDs**: Channels get stable IDs based on `tvg-id` or content hash, surviving source refreshes
2. **CloudKit over iCloud Documents**: Better conflict resolution and cross-device sync
3. **HLS-first playback**: AVPlayer excels at HLS; MPEG-TS fallback via alternate players
4. **Rule-based smart folders**: Filter channels dynamically by group, country, language, health

## Contributing

This is a personal project, but suggestions are welcome via Issues.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Legal

Spectra does not host, distribute, or curate any content. Users are responsible for ensuring they have the right to access any M3U playlists they import.

import SwiftUI
import UniformTypeIdentifiers
import SpectraLibrary

/// Import M3U file sheet
struct ImportSheetView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFileURL: URL?
    @State private var sourceName = ""
    @State private var isImporting = false
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import M3U Playlist")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Source Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("My IPTV Provider", text: $sourceName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("M3U File")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let url = selectedFileURL {
                        Text(url.lastPathComponent)
                            .foregroundColor(.primary)
                    } else {
                        Text("No file selected")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Choose File...") {
                        selectFile()
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Import") {
                    performImport()
                }
                .keyboardShortcut(.return)
                .disabled(selectedFileURL == nil || sourceName.isEmpty || isImporting)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "m3u")!,
            UTType(filenameExtension: "m3u8")!
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            selectedFileURL = panel.url
        }
    }
    
    private func performImport() {
        guard let url = selectedFileURL else { return }
        
        isImporting = true
        error = nil
        
        Task {
            do {
                // Read file data
                let data = try Data(contentsOf: url)
                
                // Create bookmark for future access
                let bookmark = try? url.bookmarkData(options: .withSecurityScope)
                
                _ = try await appState.library.importSource(data: data, name: sourceName, bookmark: bookmark)
                await appState.loadData()
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isImporting = false
        }
    }
}

/// Import from URL sheet
struct URLImportSheetView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var urlString = ""
    @State private var sourceName = ""
    @State private var isImporting = false
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import from URL")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Source Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("My IPTV Provider", text: $sourceName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("M3U URL")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("https://example.com/playlist.m3u", text: $urlString)
                    .textFieldStyle(.roundedBorder)
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Import") {
                    performImport()
                }
                .keyboardShortcut(.return)
                .disabled(urlString.isEmpty || sourceName.isEmpty || isImporting)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
    
    private func performImport() {
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            return
        }
        
        isImporting = true
        error = nil
        
        Task {
            do {
                _ = try await appState.library.importSource(url: url, name: sourceName)
                await appState.loadData()
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isImporting = false
        }
    }
}

#Preview("File Import") {
    ImportSheetView()
        .environmentObject(AppState())
}

#Preview("URL Import") {
    URLImportSheetView()
        .environmentObject(AppState())
}

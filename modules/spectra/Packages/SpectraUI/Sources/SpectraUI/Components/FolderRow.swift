import SwiftUI
import SpectraCore

/// Folder list item
public struct FolderRow: View {
    public let folder: Folder
    public let channelCount: Int
    public let isSelected: Bool
    public let onTap: () -> Void
    
    public init(
        folder: Folder,
        channelCount: Int = 0,
        isSelected: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.folder = folder
        self.channelCount = channelCount
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: SpectraSpacing.md) {
                // Folder icon
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                // Folder name
                Text(folder.name)
                    .font(SpectraTypography.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Channel count
                Text("\(channelCount)")
                    .font(SpectraTypography.subheadline)
                    .foregroundColor(.secondary)
                
                // Smart folder indicator
                if folder.type == .smart {
                    Image(systemName: "wand.and.stars")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            .padding(.vertical, SpectraSpacing.sm)
            .padding(.horizontal, SpectraSpacing.md)
            .background(isSelected ? SpectraColors.accent.opacity(0.15) : Color.clear)
            .cornerRadius(SpectraRadius.md)
        }
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
        if let customIcon = folder.iconName {
            return customIcon
        }
        return folder.type == .smart ? "folder.badge.gearshape" : "folder"
    }
    
    private var iconColor: Color {
        folder.type == .smart ? .purple : SpectraColors.accent
    }
}

/// Folder chip for horizontal display
public struct FolderChip: View {
    public let folder: Folder
    public let isSelected: Bool
    public let onTap: () -> Void
    
    public init(
        folder: Folder,
        isSelected: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.folder = folder
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: SpectraSpacing.xs) {
                Image(systemName: folder.type == .smart ? "wand.and.stars" : "folder")
                    .font(.caption)
                
                Text(folder.name)
                    .font(SpectraTypography.subheadline)
            }
            .padding(.horizontal, SpectraSpacing.md)
            .padding(.vertical, SpectraSpacing.sm)
            .background(isSelected ? SpectraColors.accent : SpectraColors.secondaryBackground)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(SpectraRadius.full)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: SpectraSpacing.md) {
        FolderRow(
            folder: Folder(name: "Sports", type: .manual, iconName: "sportscourt"),
            channelCount: 42,
            isSelected: true,
            onTap: {}
        )
        
        FolderRow(
            folder: Folder(name: "Working Only", type: .smart),
            channelCount: 156,
            isSelected: false,
            onTap: {}
        )
        
        Divider()
        
        HStack {
            FolderChip(folder: Folder(name: "All"), isSelected: true, onTap: {})
            FolderChip(folder: Folder(name: "Sports"), isSelected: false, onTap: {})
            FolderChip(folder: Folder(name: "News"), isSelected: false, onTap: {})
        }
    }
    .padding()
}

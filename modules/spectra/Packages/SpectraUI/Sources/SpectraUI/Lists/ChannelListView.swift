import SwiftUI
import SpectraCore

/// Searchable channel list
public struct ChannelListView<Content: View>: View {
    @Binding public var searchText: String
    public let channels: [Channel]
    public let content: (Channel) -> Content
    
    public init(
        searchText: Binding<String>,
        channels: [Channel],
        @ViewBuilder content: @escaping (Channel) -> Content
    ) {
        self._searchText = searchText
        self.channels = channels
        self.content = content
    }
    
    private var filteredChannels: [Channel] {
        if searchText.isEmpty {
            return channels
        }
        let lowercaseSearch = searchText.lowercased()
        return channels.filter { channel in
            channel.name.lowercased().contains(lowercaseSearch) ||
            channel.group?.lowercased().contains(lowercaseSearch) == true
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search channels...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(SpectraSpacing.md)
            .background(SpectraColors.secondaryBackground)
            .cornerRadius(SpectraRadius.md)
            .padding(SpectraSpacing.md)
            
            // Results count
            if !searchText.isEmpty {
                HStack {
                    Text("\(filteredChannels.count) channels")
                        .font(SpectraTypography.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, SpectraSpacing.md)
            }
            
            // Channel list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredChannels) { channel in
                        content(channel)
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
    }
}

/// Grouped channel list by category
public struct GroupedChannelList<Content: View>: View {
    public let channels: [Channel]
    public let content: (Channel) -> Content
    
    public init(
        channels: [Channel],
        @ViewBuilder content: @escaping (Channel) -> Content
    ) {
        self.channels = channels
        self.content = content
    }
    
    private var groupedChannels: [(String, [Channel])] {
        let grouped = Dictionary(grouping: channels) { $0.group ?? "Uncategorized" }
        return grouped.sorted { $0.key < $1.key }
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedChannels, id: \.0) { group, channels in
                    Section {
                        ForEach(channels) { channel in
                            content(channel)
                            Divider()
                                .padding(.leading, 60)
                        }
                    } header: {
                        HStack {
                            Text(group)
                                .font(SpectraTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(channels.count)")
                                .font(SpectraTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, SpectraSpacing.md)
                        .padding(.vertical, SpectraSpacing.sm)
                        .background(SpectraColors.background)
                    }
                }
            }
        }
    }
}

#Preview {
    ChannelListView(
        searchText: .constant(""),
        channels: [
            Channel(id: "1", name: "ESPN", group: "Sports", sourceId: UUID()),
            Channel(id: "2", name: "CNN", group: "News", sourceId: UUID()),
            Channel(id: "3", name: "HBO", group: "Movies", sourceId: UUID()),
        ]
    ) { channel in
        ChannelRow(
            channel: channel,
            onTap: {},
            onFavorite: {}
        )
    }
}

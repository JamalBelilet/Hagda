import SwiftUI

/// The main feed view displaying sources grouped by type
struct FeedView: View {
    // MARK: - Properties
    
    @State private var searchText = ""
    @Environment(AppModel.self) private var appModel
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if appModel.feedSources.isEmpty {
                EmptyStateView()
                    .accessibilityIdentifier("EmptyStateView")
                    .background(Color(.systemGroupedBackground))
            } else {
                sourcesList
            }
        }
        .navigationTitle("Taila")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: CombinedLibraryView()) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 18))
                        .accessibilityIdentifier("SourcesButton")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search")
    }
    
    // MARK: - UI Components
    
    /// List of sources grouped by type
    private var sourcesList: some View {
        List {
            // Group sources by type
            let groupedSources = Dictionary(grouping: appModel.feedSources) { $0.type }
            
            // Articles section
            createSourceSection(
                for: .article,
                sources: groupedSources[.article, default: []]
            )
            
            // Reddit section
            createSourceSection(
                for: .reddit,
                sources: groupedSources[.reddit, default: []]
            )
            
            // Social media section (Bluesky and Mastodon)
            let blueskySource = groupedSources[.bluesky, default: []]
            let mastodonSource = groupedSources[.mastodon, default: []]
            let socialSources = blueskySource + mastodonSource
            
            if !socialSources.isEmpty {
                Section {
                    ForEach(socialSources) { source in
                        sourceNavigationLink(for: source)
                    }
                } header: {
                    SectionHeaderView(
                        title: "Social Media", 
                        description: "Updates from people you follow",
                        icon: "person.2"
                    )
                }
                .headerProminence(.increased)
            }
            
            // Podcasts section
            createSourceSection(
                for: .podcast,
                sources: groupedSources[.podcast, default: []]
            )
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.visible)
        .background(Color(.systemGroupedBackground))
        .accessibilityIdentifier("FeedList")
    }
    
    // MARK: - Helper Methods
    
    /// Creates a section for a specific source type
    private func createSourceSection(for type: SourceType, sources: [Source]) -> some View {
        Group {
            if !sources.isEmpty {
                Section {
                    ForEach(sources) { source in
                        sourceNavigationLink(for: source)
                    }
                } header: {
                    SectionHeaderView(
                        title: type.sectionTitle,
                        description: type.sectionDescription,
                        icon: type.icon
                    )
                }
                .headerProminence(.increased)
            }
        }
    }
    
    /// Creates a navigation link for a source
    private func sourceNavigationLink(for source: Source) -> some View {
        NavigationLink(destination: SourceView(source: source)) {
            SourceRowView(source: source)
                .accessibilityIdentifier("FeedSource-\(source.name)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeedView()
            .environment(AppModel())
    }
}

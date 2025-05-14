import SwiftUI

struct FeedView: View {
    @State private var searchText = ""
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        NavigationStack {
            Group {
                if appModel.feedSources.isEmpty {
                    EmptyStateView()
                        .accessibilityIdentifier("EmptyStateView")
                        .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        // Group sources by type
                        let groupedSources = Dictionary(grouping: appModel.feedSources) { $0.type }
                        
                        // Articles section
                        if let articles = groupedSources[.article], !articles.isEmpty {
                            Section {
                                ForEach(articles) { source in
                                    NavigationLink(destination: SourceView(source: source)) {
                                        FeedSourceView(source: source)
                                            .accessibilityIdentifier("FeedSource-\(source.name)")
                                    }
                                }
                            } header: {
                                sectionHeader(title: "Top Tech Articles", 
                                             description: "Latest articles from tech news sources",
                                             icon: "doc.text")
                            }
                            .headerProminence(.increased)
                        }
                        
                        // Reddit section
                        if let redditSources = groupedSources[.reddit], !redditSources.isEmpty {
                            Section {
                                ForEach(redditSources) { source in
                                    NavigationLink(destination: SourceView(source: source)) {
                                        FeedSourceView(source: source)
                                            .accessibilityIdentifier("FeedSource-\(source.name)")
                                    }
                                }
                            } header: {
                                sectionHeader(title: "Reddit Communities", 
                                             description: "Trending posts from popular subreddits",
                                             icon: "bubble.left")
                            }
                            .headerProminence(.increased)
                        }
                        
                        // Social media section (Bluesky and Mastodon)
                        let blueskySource = groupedSources[.bluesky, default: []]
                        let mastodonSource = groupedSources[.mastodon, default: []]
                        let socialSources = blueskySource + mastodonSource
                        
                        if !socialSources.isEmpty {
                            Section {
                                ForEach(socialSources) { source in
                                    NavigationLink(destination: SourceView(source: source)) {
                                        FeedSourceView(source: source)
                                            .accessibilityIdentifier("FeedSource-\(source.name)")
                                    }
                                }
                            } header: {
                                sectionHeader(title: "Social Media", 
                                             description: "Updates from people you follow",
                                             icon: "person.2")
                            }
                            .headerProminence(.increased)
                        }
                        
                        // Podcasts section
                        if let podcasts = groupedSources[.podcast], !podcasts.isEmpty {
                            Section {
                                ForEach(podcasts) { source in
                                    NavigationLink(destination: SourceView(source: source)) {
                                        FeedSourceView(source: source)
                                            .accessibilityIdentifier("FeedSource-\(source.name)")
                                    }
                                }
                            } header: {
                                sectionHeader(title: "Tech Podcasts", 
                                             description: "Latest episodes from your favorite shows",
                                             icon: "headphones")
                            }
                            .headerProminence(.increased)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.visible)
                    .background(Color(.systemGroupedBackground))
                    .accessibilityIdentifier("FeedList")
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
    }
    
    private func sectionHeader(title: String, description: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 6)
    }
}

struct FeedSourceView: View {
    let source: Source
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        HStack(spacing: 14) {
            // Source icon
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: source.type.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                )
                
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)
                
                if let handle = source.handle {
                    Text(handle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(source.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Show a badge if this source is selected
                if appModel.isSourceSelected(source) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        
                        Text("Following")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

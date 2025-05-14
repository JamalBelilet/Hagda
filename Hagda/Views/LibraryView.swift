import SwiftUI

struct LibraryView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        List {
            ForEach(appModel.categories.keys.sorted(), id: \.self) { category in
                Section(header: CategoryHeader(title: category, description: getCategoryDescription(category))) {
                    ForEach(appModel.categories[category] ?? []) { source in
                        NavigationLink {
                            // Push to SourceView when tapped for viewing
                            SourceView(source: source)
                        } label: {
                            SourceRow(source: source)
                                .contentShape(Rectangle())
                                .accessibilityIdentifier("Source-\(source.name)")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            // Add toggling option in the context menu
                            Button(action: {
                                appModel.toggleSourceSelection(source)
                            }) {
                                Label(
                                    appModel.isSourceSelected(source) ? "Remove from Feed" : "Add to Feed",
                                    systemImage: appModel.isSourceSelected(source) ? "minus.circle" : "plus.circle"
                                )
                            }
                        }
                        .swipeActions {
                            Button(appModel.isSourceSelected(source) ? "Remove" : "Add") {
                                appModel.toggleSourceSelection(source)
                            }
                            .tint(appModel.isSourceSelected(source) ? .red : .green)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .headerProminence(.increased)
                .accessibilityIdentifier("Category-\(category)")
            }
        }
        .listStyle(.insetGrouped)
        .id("LibraryView")
        .accessibilityIdentifier("LibraryView")
        .accessibilityLabel("Library View")
        .navigationTitle("Taila")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getCategoryDescription(_ category: String) -> String {
        switch category {
        case "Top Tech Articles":
            return "Read the latest articles from the best tech sources."
        case "Popular Subreddits":
            return "Discover trending posts from the most popular subreddits."
        case "Tech Podcasts":
            return "Listen to expert discussions on tech and business."
        case "Tech Influencers":
            return "Stay updated with posts from top tech influencers on social media."
        default:
            return ""
        }
    }
}

struct CategoryHeader: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }
}

struct SourceRow: View {
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
                        .foregroundStyle(.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)
                    .accessibilityIdentifier("SourceName-\(source.name)")
                
                if let handle = source.handle {
                    Text(handle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(typeTitle(for: source.type))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(source.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .accessibilityLabel("Source: \(source.name)")
        .padding(.vertical, 4)
    }
    
    private func typeTitle(for type: SourceType) -> String {
        switch type {
        case .article:
            return "Tech News"
        case .reddit:
            return source.name
        case .bluesky:
            return "Bluesky"
        case .mastodon:
            return "Mastodon"
        case .podcast:
            return "Podcast"
        }
    }
}

// This is now handled via the tab bar in ContentView

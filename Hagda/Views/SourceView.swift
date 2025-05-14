import SwiftUI

struct SourceView: View {
    let source: Source
    @Environment(AppModel.self) private var appModel
    @State private var isFollowing: Bool = false
    
    var body: some View {
        List {
            // Header section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Icon and title
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: source.type.icon)
                                    .font(.system(size: 30))
                                    .foregroundStyle(Color.accentColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let handle = source.handle {
                                Text(handle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Description
                    Text(source.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 16)
                    
                    // Follow button
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                appModel.toggleSourceSelection(source)
                                isFollowing.toggle()
                            }
                        }) {
                            Text(isFollowing ? "Following" : "Follow")
                                .fontWeight(.semibold)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.regular)
                        .accessibilityLabel(isFollowing ? "Unfollow" : "Follow")
                        .accessibilityIdentifier("FollowButton")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // Align button to the left like other content
                }
                .padding(.vertical, 8)
            }
            
            // Content items section
            Section {
                ForEach(getDummyContentItems()) { item in
                    ContentItemRow(item: item)
                }
            } header: {
                sectionHeader(title: "Latest Content", 
                             description: "Recent posts from this source",
                             icon: source.type.icon)
            }
        }
        .navigationTitle(source.name)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.visible)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            isFollowing = appModel.isSourceSelected(source)
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
    
    private func getDummyContentItems() -> [ContentItem] {
        // Generate some dummy content based on source type
        let today = Date()
        let calendar = Calendar.current
        
        return (1...15).map { index in
            let daysAgo = Double(index) / 2.0
            let date = calendar.date(byAdding: .hour, value: -Int(daysAgo * 24), to: today) ?? today
            
            switch source.type {
            case .article:
                return ContentItem(
                    id: UUID(),
                    title: "The Future of \(["AI", "Technology", "Mobile", "Programming", "Web Development"].randomElement()!): What's Next?",
                    subtitle: "\(["Analysis", "Opinion", "Report", "Review"].randomElement()!) by \(["Sarah Johnson", "Mike Chen", "Aisha Patel", "David Kim"].randomElement()!)",
                    date: date,
                    type: .article
                )
            case .reddit:
                return ContentItem(
                    id: UUID(),
                    title: "\(["Anyone else experiencing this issue with...", "Just discovered this amazing...", "What's your opinion on...", "Help needed with..."].randomElement()!)",
                    subtitle: "Posted by u/\(["tech_enthusiast", "code_master", "curious_dev", "web_wizard"].randomElement()!) • \(Int.random(in: 5...500)) comments",
                    date: date,
                    type: .reddit
                )
            case .bluesky:
                return ContentItem(
                    id: UUID(),
                    title: "\(["Just shipped a new feature for...", "Thoughts on the latest tech trends...", "Working on something exciting...", "Anyone going to the tech conference?"].randomElement()!)",
                    subtitle: "@\(["skypro", "techblogger", "devguru", "codemaster"].randomElement()!).bsky.social",
                    date: date,
                    type: .bluesky
                )
            case .mastodon:
                return ContentItem(
                    id: UUID(),
                    title: "\(["Just published my thoughts on...", "Here's my latest project update...", "Interesting development in tech today...", "Anyone else notice this trend?"].randomElement()!)",
                    subtitle: "@\(["techwriter", "opensourcefan", "devrelexpert", "codeartist"].randomElement()!)@mastodon.social",
                    date: date,
                    type: .mastodon
                )
            case .podcast:
                return ContentItem(
                    id: UUID(),
                    title: "Episode \(Int.random(in: 100...350)): \(["The State of Technology", "Interview with Industry Expert", "Deep Dive into New Frameworks", "Tech News Roundup"].randomElement()!)",
                    subtitle: "\(Int.random(in: 30...120)) minutes • \(["Interview", "Solo Episode", "Panel Discussion", "Q&A Session"].randomElement()!)",
                    date: date,
                    type: .podcast
                )
            }
        }
    }
}

struct ContentItem: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let date: Date
    let type: SourceType
}

struct ContentItemRow: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(item.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: sourceTypeIcon(for: item.type))
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                Text(timeAgo(from: item.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
    
    private func sourceTypeIcon(for type: SourceType) -> String {
        switch type {
        case .article: return "doc.text"
        case .reddit: return "bubble.left"
        case .bluesky: return "cloud"
        case .mastodon: return "message"
        case .podcast: return "headphones"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        SourceView(source: Source.sampleSources[0])
    }
}

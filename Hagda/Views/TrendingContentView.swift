import SwiftUI

/// A view that displays all trending/top content from followed sources
struct TrendingContentView: View {
    @Environment(AppModel.self) private var appModel
    @State private var trendingItems: [ContentItem] = []
    @State private var selectedItem: ContentItem?
    @State private var showItemDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if trendingItems.isEmpty {
                    emptyStateView
                } else {
                    ForEach(trendingItems) { item in
                        NavigationLink(destination: ContentDetailView(item: item)) {
                            trendingItemCard(for: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Trending Now")
        .onAppear {
            // Generate trending items
            loadContent()
            
            // Set up notification observer for feed refreshes
            setupNotificationObserver()
        }
    }
    
    // Setup notification observer for feed refreshes
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .feedRefreshed,
            object: nil,
            queue: .main
        ) { _ in
            // When the feed is refreshed, update our content
            loadContent()
        }
    }
    
    // Load content items
    private func loadContent() {
        trendingItems = generateMockTrendingItems()
    }
    
    // Card for a trending content item
    private func trendingItemCard(for item: ContentItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with badge
            HStack {
                Label {
                    Text(item.type.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: item.typeIcon)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
                
                Spacer()
                
                if let metric = topMetric(for: item) {
                    HStack(spacing: 2) {
                        Image(systemName: metricIcon(for: item))
                            .font(.caption)
                        
                        Text(metric)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Text(item.title)
                .font(.headline)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(item.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Text("Popular Now")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(item.relativeTimeString)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
    }
    
    // Empty state when no trending content exists
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Trending Content")
                .font(.headline)
            
            Text("Trending content from your sources will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .padding(.vertical, 60)
    }
    
    // Generate mock trending items
    private func generateMockTrendingItems() -> [ContentItem] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get source types from appModel
        let availableTypes = Set(appModel.feedSources.map { $0.type })
        
        if availableTypes.isEmpty {
            return []
        }
        
        var trendingItems: [ContentItem] = []
        
        // Articles
        if availableTypes.contains(.article) {
            trendingItems.append(ContentItem(
                title: "Quantum Computing in 2024: Real-World Applications Begin to Emerge",
                subtitle: "Ars Technica • 6 min read",
                date: calendar.date(byAdding: .hour, value: -8, to: now) ?? now,
                type: .article
            ))
            
            trendingItems.append(ContentItem(
                title: "Generative AI's Evolution: From Text to Multimodal Problem-Solving",
                subtitle: "MIT Technology Review • 5 min read",
                date: calendar.date(byAdding: .hour, value: -10, to: now) ?? now,
                type: .article
            ))
            
            trendingItems.append(ContentItem(
                title: "The Future of Edge Computing: Processing Data Where It's Created",
                subtitle: "IEEE Spectrum • 7 min read",
                date: calendar.date(byAdding: .hour, value: -15, to: now) ?? now,
                type: .article
            ))
        }
        
        // Reddit posts
        if availableTypes.contains(.reddit) {
            trendingItems.append(ContentItem(
                title: "The convergence of IT and security: Why these teams need to merge in 2024",
                subtitle: "r/cybersecurity • 3.2k upvotes",
                date: calendar.date(byAdding: .hour, value: -5, to: now) ?? now,
                type: .reddit
            ))
            
            trendingItems.append(ContentItem(
                title: "Analysis: Satellite connectivity is finally becoming mainstream for smartphones",
                subtitle: "r/Futurology • 5.6k upvotes",
                date: calendar.date(byAdding: .hour, value: -7, to: now) ?? now,
                type: .reddit
            ))
            
            trendingItems.append(ContentItem(
                title: "I created a tool that automatically generates documentation from code comments - looking for testers",
                subtitle: "r/programming • 2.7k upvotes",
                date: calendar.date(byAdding: .hour, value: -9, to: now) ?? now,
                type: .reddit
            ))
        }
        
        // Social posts
        if availableTypes.contains(.bluesky) {
            trendingItems.append(ContentItem(
                title: "Google's May 2024 update is hitting sites hard. Here's my analysis of what's changed and which industries are most affected...",
                subtitle: "@glenngabe.bsky.social",
                date: calendar.date(byAdding: .hour, value: -3, to: now) ?? now,
                type: .bluesky
            ))
            
            trendingItems.append(ContentItem(
                title: "Just published my deep dive on unified UI frameworks. The gap between web, mobile, and desktop is closing faster than most realize...",
                subtitle: "@techanalyst.bsky.social",
                date: calendar.date(byAdding: .hour, value: -6, to: now) ?? now,
                type: .bluesky
            ))
        }
        
        // Podcasts
        if availableTypes.contains(.podcast) {
            trendingItems.append(ContentItem(
                title: "Inside the Post-Quantum Cryptography Rush: Why Companies Are Adopting PQC Now",
                subtitle: "Hard Fork • Latest episode",
                date: calendar.date(byAdding: .hour, value: -12, to: now) ?? now,
                type: .podcast
            ))
            
            trendingItems.append(ContentItem(
                title: "The Augmented Connected Workforce: Technology's Role in Remote Collaboration",
                subtitle: "This Week in Tech • Most shared",
                date: calendar.date(byAdding: .hour, value: -24, to: now) ?? now,
                type: .podcast
            ))
            
            trendingItems.append(ContentItem(
                title: "Modern Developer Workflows: Tools and Techniques for 10x Productivity",
                subtitle: "The Changelog • Trending episode",
                date: calendar.date(byAdding: .hour, value: -18, to: now) ?? now,
                type: .podcast
            ))
        }
        
        // Return all the trending items
        return trendingItems.shuffled()
    }
    
    // Metric value for the trending item (upvotes, views, etc.)
    private func topMetric(for item: ContentItem) -> String? {
        switch item.type {
        case .article:
            return "\(Int.random(in: 150...5000)) views"
        case .reddit:
            return "\(Int.random(in: 50...2000)) upvotes"
        case .bluesky, .mastodon:
            return "\(Int.random(in: 40...800)) likes"
        case .podcast:
            return "\(Int.random(in: 5...100))K plays"
        }
    }
    
    // Icon for the metric type
    private func metricIcon(for item: ContentItem) -> String {
        switch item.type {
        case .article:
            return "eye"
        case .reddit:
            return "arrow.up"
        case .bluesky, .mastodon:
            return "heart"
        case .podcast:
            return "play.circle"
        }
    }
}

#Preview {
    NavigationStack {
        TrendingContentView()
            .environment(AppModel())
    }
}
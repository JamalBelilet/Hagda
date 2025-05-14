import SwiftUI

// MARK: - Daily Summary Section

/// A view that displays a personalized daily summary of content
struct DailySummaryView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date heading
            HStack {
                Text(dateString)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.yellow)
            }
            
            // Summary text
            Text(generateSummary())
                .font(.body)
                .lineSpacing(5)
            
            // Sources attribution
            HStack(spacing: 0) {
                Text("Based on ")
                Text(generateSourceAttribution())
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.vertical, 4)
        .accessibilityIdentifier("DailySummary")
    }
    
    // Current date string
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // Generate a personalized summary based on followed sources
    private func generateSummary() -> String {
        let sourceCount = appModel.feedSources.count
        
        if sourceCount == 0 {
            return "Welcome to your daily summary! Add sources to get personalized updates and highlights from your favorite content."
        }
        
        let hasArticles = appModel.feedSources.contains(where: { $0.type == .article })
        let hasReddit = appModel.feedSources.contains(where: { $0.type == .reddit })
        let hasSocial = appModel.feedSources.contains(where: { $0.type == .bluesky || $0.type == .mastodon })
        let hasPodcast = appModel.feedSources.contains(where: { $0.type == .podcast })
        
        var summaryParts: [String] = []
        
        if hasArticles {
            summaryParts.append("In tech news today, there's significant interest in AI developments, with several articles highlighting breakthroughs in natural language processing and computer vision applications.")
        }
        
        if hasReddit {
            summaryParts.append("Reddit communities are discussing the latest framework updates, with developers sharing success stories and practical implementation tips.")
        }
        
        if hasSocial {
            summaryParts.append("On social media, tech influencers are debating the merits of new development tools and sharing insights about upcoming tech conferences.")
        }
        
        if hasPodcast {
            summaryParts.append("Recent podcast episodes cover interviews with industry pioneers and deep dives into evolving technology trends.")
        }
        
        if summaryParts.isEmpty {
            return "Your summary is being prepared. Add more sources to get a richer daily briefing tailored to your interests."
        }
        
        return summaryParts.joined(separator: " ")
    }
    
    // Generate source attribution text
    private func generateSourceAttribution() -> String {
        let allSources = appModel.feedSources
        
        if allSources.isEmpty {
            return "your followed sources"
        }
        
        let sourceNames = allSources.prefix(3).map { $0.name }
        
        if allSources.count <= 3 {
            return sourceNames.joined(separator: ", ")
        } else {
            return "\(sourceNames.joined(separator: ", ")) and \(allSources.count - 3) more"
        }
    }
}

// MARK: - Continue Items Section

/// A view that displays content items the user was previously engaging with
struct ContinueItemsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var continueItems: [ContentItem] = []
    
    var body: some View {
        VStack(spacing: 8) {
            if continueItems.isEmpty {
                emptyStateView
            } else {
                ForEach(continueItems) { item in
                    NavigationLink(destination: ContentDetailView(item: item)) {
                        continueItemRow(for: item)
                    }
                    .buttonStyle(.plain)
                    
                    if item != continueItems.last {
                        Divider()
                    }
                }
            }
        }
        .onAppear {
            // Generate mocked continue items
            continueItems = generateMockContinueItems()
        }
    }
    
    // Row for a continue item with progress indicator
    private func continueItemRow(for item: ContentItem) -> some View {
        HStack(spacing: 14) {
            // Type icon with progress circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 2)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: progressValue(for: item))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: item.typeIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(progressText(for: item))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(item.relativeTimeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // Empty state when no continue items exist
    private var emptyStateView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "bookmark.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                
                Text("Nothing to continue")
                    .font(.headline)
                
                Text("Items you've started reading or listening to will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Spacer()
        }
        .frame(height: 150)
    }
    
    // Generate mock continue items for demonstration
    private func generateMockContinueItems() -> [ContentItem] {
        let calendar = Calendar.current
        let now = Date()
        
        // Generate one item for each content type
        let articleItem = ContentItem(
            title: "Designing Effective User Interfaces for Mobile Applications",
            subtitle: "From The Verge • 10 min read",
            date: calendar.date(byAdding: .hour, value: -4, to: now) ?? now,
            type: .article
        )
        
        let podcastItem = ContentItem(
            title: "Episode 254: The Future of Development Frameworks",
            subtitle: "All-In • 45 min remaining",
            date: calendar.date(byAdding: .hour, value: -1, to: now) ?? now,
            type: .podcast
        )
        
        // Pick two random items to show
        let potentialItems = [articleItem, podcastItem]
        return Array(potentialItems.shuffled().prefix(Int.random(in: 0...2)))
    }
    
    // Generate progress value for visual indicator
    private func progressValue(for item: ContentItem) -> CGFloat {
        // Random progress for mock data - in a real app this would be stored
        return item.type == .article ? 0.35 : 0.65
    }
    
    // Generate progress text based on content type
    private func progressText(for item: ContentItem) -> String {
        switch item.type {
        case .article:
            return "35% completed"
        case .podcast:
            return "21:15 remaining"
        default:
            return "In progress"
        }
    }
}

// MARK: - Top Content Section

/// A view that displays top/trending content from followed sources
struct TopContentView: View {
    @Environment(AppModel.self) private var appModel
    @State private var topItems: [ContentItem] = []
    
    var body: some View {
        VStack(spacing: 12) {
            if topItems.isEmpty {
                emptyStateView
            } else {
                // Show top content in a scrollable row with large cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(topItems) { item in
                            NavigationLink(destination: ContentDetailView(item: item)) {
                                topContentCard(for: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            // Generate mock top items
            topItems = generateMockTopItems()
        }
    }
    
    // Card for top content item
    private func topContentCard(for item: ContentItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(item.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack {
                Text("Trending Today")
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
        .frame(width: 280, height: 160)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // Empty state when no top content exists
    private var emptyStateView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "star.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                
                Text("No trending content")
                    .font(.headline)
                
                Text("Popular items from your sources will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Spacer()
        }
        .frame(height: 160)
    }
    
    // Generate mock top items based on followed sources
    private func generateMockTopItems() -> [ContentItem] {
        let result: [ContentItem] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Get source types from appModel
        let availableTypes = Set(appModel.feedSources.map { $0.type })
        
        if availableTypes.isEmpty {
            return result
        }
        
        var topItems: [ContentItem] = []
        
        if availableTypes.contains(.article) {
            topItems.append(ContentItem(
                title: "The Rise of AI-assisted Programming: A Game Changer for Developers",
                subtitle: "TechCrunch • 4 min read",
                date: calendar.date(byAdding: .hour, value: -8, to: now) ?? now,
                type: .article
            ))
        }
        
        if availableTypes.contains(.reddit) {
            topItems.append(ContentItem(
                title: "I created a productivity tool that saved our team 10 hours a week",
                subtitle: "r/programming • 432 upvotes",
                date: calendar.date(byAdding: .hour, value: -5, to: now) ?? now,
                type: .reddit
            ))
        }
        
        if availableTypes.contains(.bluesky) {
            topItems.append(ContentItem(
                title: "Just spoke with the team behind the new framework release. Here's what you need to know about the upcoming changes...",
                subtitle: "@techblogger.bsky.social",
                date: calendar.date(byAdding: .hour, value: -3, to: now) ?? now,
                type: .bluesky
            ))
        }
        
        if availableTypes.contains(.podcast) {
            topItems.append(ContentItem(
                title: "How Modern Development Teams Are Using AI: Insights from 50+ Interviews",
                subtitle: "All-In • Most played episode",
                date: calendar.date(byAdding: .hour, value: -12, to: now) ?? now,
                type: .podcast
            ))
        }
        
        return Array(topItems.shuffled().prefix(3))
    }
    
    // Metric value for the top item (upvotes, views, etc.)
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

// MARK: - Previews

#Preview("Daily Summary") {
    DailySummaryView()
        .environment(AppModel())
        .padding()
}

#Preview("Continue Items") {
    ContinueItemsView()
        .environment(AppModel())
        .padding()
}

#Preview("Top Content") {
    TopContentView()
        .environment(AppModel())
        .padding()
}
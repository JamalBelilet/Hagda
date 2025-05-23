import SwiftUI

// Import the Notification.Name extension from FeedView
import Foundation

// MARK: - Daily Summary Section

/// A view that displays a personalized daily summary of content
struct DailySummaryView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingSettings = false
    
    // Environment state to connect with parent navigation state
    @Binding var showDailyDetails: Bool
    
    // Initialize with a default binding for preview support
    init(showDailyDetails: Binding<Bool> = .constant(false)) {
        self._showDailyDetails = showDailyDetails
    }
    
    var body: some View {
        ZStack {
            Button {
                showDailyDetails = true
            } label: {
                VStack(alignment: .leading, spacing: 16) {
                    // Date heading
                    HStack {
                        Text(dateString)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Summary text
                    Text(generateSummary())
                        .font(.body)
                        .lineSpacing(5)
                    
                    // Sources attribution
                    HStack(spacing: 0) {
                        Text("Curated from ")
                        Text(generateSourceAttribution())
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                    .padding(.top, 4)
                    
                    // "See details" indicator without chevron
                    HStack {
                        Spacer()
                        
                        Text("See details")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("DailySummary")
        }
        // Navigation destination is now handled by the parent view
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                DailySummarySettingsView()
                    .navigationTitle("Customize Your Brief")
                    #if os(iOS) || os(visionOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingSettings = false
                            }
                        }
                    }
            }
            #if os(iOS) || os(visionOS)
            .presentationDetents([.medium, .large])
            #endif
        }
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
            return "Add sources to receive tailored technology updates from content that matters to you."
        }
        
        // Apply settings for content length
        let summaryFactor: Double
        switch appModel.dailySummarySettings.summaryLength {
        case .short:
            summaryFactor = 0.5
        case .medium:
            summaryFactor = 1.0
        case .long:
            summaryFactor = 1.5
        }
        
        // Get prioritized sources and organize by type
        let prioritizedSources = appModel.feedSources.filter { appModel.isSourcePrioritized($0) }
        let standardSources = appModel.feedSources.filter { !appModel.isSourcePrioritized($0) }
        
        // Determine which types we have based on prioritized sources first
        var sourcesToConsider = appModel.feedSources
        
        // If we're using priority sort, arrange priority sources first
        if appModel.dailySummarySettings.sortingOrder == .priority && !prioritizedSources.isEmpty {
            sourcesToConsider = prioritizedSources + standardSources
        }
        
        let hasArticles = sourcesToConsider.contains(where: { $0.type == .article })
        let hasReddit = sourcesToConsider.contains(where: { $0.type == .reddit })
        let hasSocial = sourcesToConsider.contains(where: { $0.type == .bluesky || $0.type == .mastodon })
        let hasPodcast = sourcesToConsider.contains(where: { $0.type == .podcast })
        
        var summaryParts: [String] = []
        
        // Include today's events if enabled
        if appModel.dailySummarySettings.includeTodayEvents {
        }
        
        // Prioritize source types from prioritized sources
        if hasArticles {
            let articlePart = "AI and quantum computing convergence is rapidly accelerating, with real-world enterprise applications now emerging across industries."
            
            // Add prioritized source detail if there's an article source prioritized
            let hasPrioritizedArticle = prioritizedSources.contains(where: { $0.type == .article })
            if hasPrioritizedArticle && appModel.dailySummarySettings.summarizeSource {
                let priorityArticleSources = prioritizedSources.filter { $0.type == .article }
                let priorityNames = priorityArticleSources.map { $0.name }.joined(separator: " and ")
                summaryParts.append("\(articlePart) \(priorityNames) features extensive coverage on this topic.")
            } else {
                summaryParts.append(articlePart)
            }
        }
        
        if hasReddit {
            let redditPart = "IT and security team convergence is trending in cybersecurity discussions, with implementation strategies and risk mitigation approaches being shared."
            
            // Add prioritized source detail if there's a Reddit source prioritized
            let hasPrioritizedReddit = prioritizedSources.contains(where: { $0.type == .reddit })
            if hasPrioritizedReddit && appModel.dailySummarySettings.summarizeSource {
                let priorityRedditSources = prioritizedSources.filter { $0.type == .reddit }
                let subreddits = priorityRedditSources.map { $0.name }.joined(separator: " and ")
                summaryParts.append("\(redditPart) \(subreddits) have particularly active discussions today.")
            } else {
                summaryParts.append(redditPart)
            }
        }
        
        if hasSocial {
            let socialPart = "Satellite connectivity for smartphones is gaining traction, promising to transform rural connectivity and emergency services."
            
            // Add prioritized source detail if there's a social source prioritized
            let hasPrioritizedSocial = prioritizedSources.contains(where: { $0.type == .bluesky || $0.type == .mastodon })
            if hasPrioritizedSocial && appModel.dailySummarySettings.summarizeSource {
                let prioritySocialSources = prioritizedSources.filter { $0.type == .bluesky || $0.type == .mastodon }
                let accounts = prioritySocialSources.map { $0.name }.joined(separator: " and ")
                summaryParts.append("\(socialPart) \(accounts) posted notable updates on this subject.")
            } else {
                summaryParts.append(socialPart)
            }
        }
        
        if hasPodcast {
            let podcastPart = "Generative AI's capability across multiple modalities is evolving rapidly, significantly impacting content creation and organizational productivity."
            
            // Add prioritized source detail if there's a podcast source prioritized
            let hasPrioritizedPodcast = prioritizedSources.contains(where: { $0.type == .podcast })
            if hasPrioritizedPodcast && appModel.dailySummarySettings.summarizeSource {
                let priorityPodcastSources = prioritizedSources.filter { $0.type == .podcast }
                let shows = priorityPodcastSources.map { $0.name }.joined(separator: " and ")
                summaryParts.append("\(podcastPart) \(shows) released new episodes worth listening to.")
            } else {
                summaryParts.append(podcastPart)
            }
        }
        
        if summaryParts.isEmpty {
            return "Add more sources for a richer daily technology overview tailored to your interests."
        }
        
        // Adjust summary length based on settings
        if summaryFactor < 1.0 && summaryParts.count > 1 {
            // For short summaries, just take the first 1-2 parts
            let itemsToKeep = max(1, Int(Double(summaryParts.count) * summaryFactor))
            summaryParts = Array(summaryParts.prefix(itemsToKeep))
        } else if summaryFactor > 1.0 {
            // For long summaries, add additional detail
            if appModel.dailySummarySettings.sortingOrder == .trending {
                summaryParts.append("Key trends: post-quantum cryptography, augmented connected workforce, and sustainable technology practices.")
            }
        }
        
        return summaryParts.joined(separator: " ")
    }
    
    // Generate source attribution text
    private func generateSourceAttribution() -> String {
        let allSources = appModel.feedSources
        
        if allSources.isEmpty {
            return "your followed sources"
        }
        
        // Sort sources for attribution - prioritized first, then others
        let sourcesToShow: [Source]
        
        if appModel.dailySummarySettings.sortingOrder == .priority {
            // Get prioritized sources first
            let prioritizedSources = allSources.filter { appModel.isSourcePrioritized($0) }
            let otherSources = allSources.filter { !appModel.isSourcePrioritized($0) }
            
            // If we have prioritized sources, show them first
            if !prioritizedSources.isEmpty {
                sourcesToShow = prioritizedSources + otherSources
            } else {
                sourcesToShow = allSources
            }
        } else {
            sourcesToShow = allSources
        }
        
        let sourceNames = sourcesToShow.prefix(3).map { source in
            if appModel.isSourcePrioritized(source) {
                return "\(source.name)★" // Add star for prioritized sources
            } else {
                return source.name
            }
        }
        
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
    @State private var isRefreshing = false
    
    // Use parent's navigation state
    @Binding var selectedContentItem: ContentItem?
    @Binding var showContentDetail: Bool
    @Binding var showAllItems: Bool
    
    // Initialize with default bindings for preview support
    init(
        selectedContentItem: Binding<ContentItem?> = .constant(nil),
        showContentDetail: Binding<Bool> = .constant(false),
        showAllItems: Binding<Bool> = .constant(false)
    ) {
        self._selectedContentItem = selectedContentItem
        self._showContentDetail = showContentDetail
        self._showAllItems = showAllItems
    }
    
    // Maximum number of items to show in the feed view
    private let maxItemsInFeed = 3
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if continueItems.isEmpty {
                    emptyStateView
                } else {
                    // Show limited items in the feed
                    let limitedItems = Array(continueItems.prefix(maxItemsInFeed))
                    
                    ForEach(limitedItems) { item in
                        VStack(spacing: 0) {
                            // Main row with content and progress
                            Button {
                                selectedContentItem = item
                                showContentDetail = true
                            } label: {
                                continueItemRow(for: item)
                                    .padding(.bottom, 12)
                            }
                            .buttonStyle(.plain)
                            
                            // Preview of remaining content - separate button with same action
                            Button {
                                selectedContentItem = item
                                showContentDetail = true
                            } label: {
                                RemainingContentPreview(item: item)
                            }
                            .buttonStyle(.plain)
                            
                            // Add spacing after the entire item
                            if item != limitedItems.last {
                                Divider()
                                    .padding(.vertical, 10)
                            }
                            
                            // Add bottom padding for the entire section
                            Spacer()
                                .frame(height: 16)
                        }
                    }
                    
                    // No "See All" button needed as we now use the section header for navigation
                }
            }
            .refreshable {
                await refreshContinueItems()
            }
        }
        // Navigation destinations are now handled by the parent view
        .onAppear {
            // Generate mocked continue items
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
        continueItems = generateMockContinueItems()
    }
    
    // Refresh continue items - simulates a network request with async
    private func refreshContinueItems() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Generate new items
        continueItems = generateMockContinueItems()
    }
    
    // Row for a continue item with progress indicator
    private func continueItemRow(for item: ContentItem) -> some View {
        HStack(spacing: 14) {
            // Type icon with progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
            
            // Chevron indicator for item row
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.4))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

/// Displays a preview of the remaining content for a partially consumed item
struct RemainingContentPreview: View {
    let item: ContentItem
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with title and info with a visual "continue" indicator
            HStack {
                Text(item.remainingContentTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Text(item.remainingContentInfo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            
            // Content preview
            Text(item.remainingContentSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                #if os(iOS) || os(visionOS)
                .background(Color(.secondarySystemBackground))
                #else
                .background(Color.gray.opacity(0.15))
                #endif
                .cornerRadius(10)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle()) // Make entire area tappable
    }
}

extension ContinueItemsView {
    // Empty state when no continue items exist
    private var emptyStateView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "bookmark.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                
                Text("Continue Reading")
                    .font(.headline)
                
                Text("Content you've started reading or listening to will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Spacer()
        }
        .frame(height: 150)
    }
    
    // Generate continue items including real podcast progress
    private func generateMockContinueItems() -> [ContentItem] {
        // Get real podcast progress first
        let podcastProgress = PodcastProgressTracker.shared.getAllInProgressEpisodes()
        let podcastItems = podcastProgress.prefix(5).map { entry in
            PodcastProgressTracker.shared.createContentItem(from: entry)
        }
        
        // Then generate mock items for other types
        let calendar = Calendar.current
        let now = Date()
        
        // Start with real podcast items
        var allItems: [ContentItem] = podcastItems
        
        // Article items
        allItems.append(ContentItem(
            title: "The Evolution of Sustainable Technology: Green Tech in 2024",
            subtitle: "From ZDNet • 8 min read",
            date: calendar.date(byAdding: .hour, value: -4, to: now) ?? now,
            type: .article,
            contentPreview: """
            The article continues with key sustainable technology trends of 2024:
            
            • How HPE's GreenLake platform is revolutionizing energy-efficient cloud services
            • The rise of carbon-aware computing and its impact on enterprise IT strategy
            • Renewable energy innovations powering next-gen data centers
            • Circular economy principles applied to hardware procurement and disposal
            """,
            progressPercentage: 0.35
        ))
        
        allItems.append(ContentItem(
            title: "Web Development Frameworks in 2024: What's Hot and What's Not",
            subtitle: "From DEV Community • 12 min read",
            date: calendar.date(byAdding: .hour, value: -8, to: now) ?? now,
            type: .article,
            contentPreview: """
            This in-depth analysis continues with framework benchmarks:
            
            • Performance comparison across major JavaScript frameworks
            • Developer experience metrics and community support trends
            • Enterprise adoption patterns and migration strategies
            • Emerging micro-frameworks and their specialized use cases
            """,
            progressPercentage: 0.22
        ))
        
        // Reddit items - temporarily removed until we integrate real data
        // TODO: Fetch from user's reading history
        
        // Shuffle all items and return 4-6 items to ensure we have enough to show the "See All" button
        return Array(allItems.shuffled().prefix(Int.random(in: 4...6)))
    }
    
    // Generate progress value for visual indicator
    private func progressValue(for item: ContentItem) -> CGFloat {
        return CGFloat(item.progressPercentage)
    }
    
    // Generate progress text based on content type
    private func progressText(for item: ContentItem) -> String {
        switch item.type {
        case .article:
            return "\(Int(item.progressPercentage * 100))% completed"
        case .podcast:
            let totalSeconds = 45 * 60 // 45 minutes in seconds
            let remainingSeconds = Int(Double(totalSeconds) * (1 - item.progressPercentage))
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return "\(minutes):\(String(format: "%02d", seconds)) remaining"
        default:
            return "\(Int(item.progressPercentage * 100))% completed"
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
                    .padding(.leading, 16)
                    .padding(.trailing, 32)
                }
                .padding(.horizontal, -16)
                .edgesIgnoringSafeArea(.horizontal)
            }
        }
        .onAppear {
            // Load top content
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
        // Generate mock top items with a slight animation
        withAnimation(.easeInOut(duration: 0.3)) {
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
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(item.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
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
        .frame(width: 290, height: 160)
        .background(Color.gray.opacity(0.2))
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
                
                Text("Popular Content")
                    .font(.headline)
                
                Text("Trending content from your sources will appear here")
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
                title: "Quantum Computing in 2024: Real-World Applications Begin to Emerge",
                subtitle: "Ars Technica • 6 min read",
                date: calendar.date(byAdding: .hour, value: -8, to: now) ?? now,
                type: .article
            ))
            
            topItems.append(ContentItem(
                title: "Generative AI's Evolution: From Text to Multimodal Problem-Solving",
                subtitle: "MIT Technology Review • 5 min read",
                date: calendar.date(byAdding: .hour, value: -10, to: now) ?? now,
                type: .article
            ))
        }
        
        // Reddit top items - temporarily removed until we integrate real trending data
        // TODO: Fetch trending Reddit posts from selected subreddits
        
        // Bluesky top items - temporarily removed until we integrate real trending data
        // TODO: Fetch trending Bluesky posts from followed accounts
        
        if availableTypes.contains(.podcast) {
            topItems.append(ContentItem(
                title: "Inside the Post-Quantum Cryptography Rush: Why Companies Are Adopting PQC Now",
                subtitle: "Hard Fork • Latest episode",
                date: calendar.date(byAdding: .hour, value: -12, to: now) ?? now,
                type: .podcast
            ))
            
            topItems.append(ContentItem(
                title: "The Augmented Connected Workforce: Technology's Role in Remote Collaboration",
                subtitle: "This Week in Tech • Most shared",
                date: calendar.date(byAdding: .hour, value: -24, to: now) ?? now,
                type: .podcast
            ))
        }
        
        // Return all items to ensure there's always enough content to scroll
        return topItems
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

#Preview("Remaining Content Preview") {
    VStack(spacing: 20) {
        RemainingContentPreview(item: ContentItem(
            title: "Designing Effective User Interfaces for Mobile Applications",
            subtitle: "From The Verge • 10 min read",
            date: Date().addingTimeInterval(-3600 * 4),
            type: .article,
            contentPreview: """
            The article continues with an exploration of mobile UI best practices:
            
            • Responsive design principles for different screen sizes
            • Accessibility considerations for diverse user needs
            • Color theory and visual hierarchy in mobile interfaces
            • User testing methodologies for validating design decisions
            """,
            progressPercentage: 0.35
        ))
        
        RemainingContentPreview(item: ContentItem(
            title: "Episode 254: The Future of Development Frameworks",
            subtitle: "All-In • 45 min remaining",
            date: Date().addingTimeInterval(-3600 * 1),
            type: .podcast,
            contentPreview: """
            Coming up in this episode:
            
            • Discussion on the evolution of frontend frameworks
            • Interview with the lead architect of a popular framework
            • Practical tips for migrating between frameworks
            • Performance optimization strategies for modern web applications
            """,
            progressPercentage: 0.65
        ))
    }
    .padding()
}

#Preview("Top Content") {
    TopContentView()
        .environment(AppModel())
        .padding()
}

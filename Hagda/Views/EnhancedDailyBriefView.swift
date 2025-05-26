import SwiftUI

/// Enhanced Daily Brief view with improved visual hierarchy and engagement
struct EnhancedDailyBriefView: View {
    @State private var isExpanded = false
    @State private var selectedMode: BriefMode
    @ObservedObject var generator: DailyBriefGenerator
    @Environment(AppModel.self) private var appModel
    
    init(generator: DailyBriefGenerator) {
        self.generator = generator
        self._selectedMode = State(initialValue: generator.currentBrief?.mode ?? .standard)
    }
    
    var body: some View {
        Group {
            if let brief = generator.currentBrief {
                briefCard(brief)
            } else if generator.lastError != nil {
                errorView
            } else {
                loadingView
            }
        }
        .task {
            if generator.currentBrief == nil && !generator.isGenerating {
                await generator.generateBrief()
            }
        }
    }
    
    // MARK: - Brief Card
    
    private func briefCard(_ brief: DailyBrief) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if isExpanded {
                expandedContent(brief)
            } else {
                collapsedContent(brief)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    // MARK: - Collapsed Content
    
    private func collapsedContent(_ brief: DailyBrief) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = true
                HapticManager.shared.impact(.light)
            }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header with mode indicator
                briefHeader(brief, isCollapsed: true)
                
                // Visual preview of content
                contentPreview(brief)
                
                // Engagement metrics
                metricsBar(brief)
            }
            .padding(20)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("DailyBriefCard")
    }
    
    // MARK: - Brief Header
    
    private func briefHeader(_ brief: DailyBrief, isCollapsed: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(brief.mode.color.gradient)
                    .frame(width: 48, height: 48)
                
                Image(systemName: brief.mode.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: isExpanded)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Today's Brief")
                        .font(.headline)
                    
                    if brief.items.contains(where: { isBreaking($0) }) {
                        breakingBadge
                    }
                }
                
                HStack(spacing: 8) {
                    Label("\(brief.items.count) stories", systemImage: "doc.text")
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Label("\(brief.readTimeMinutes) min", systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Mode selector or expand button
            if isCollapsed {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .symbolRenderingMode(.hierarchical)
            } else {
                modeSelector
            }
        }
    }
    
    private var breakingBadge: some View {
        Text("BREAKING")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.gradient)
            .clipShape(Capsule())
    }
    
    // MARK: - Content Preview
    
    private func contentPreview(_ brief: DailyBrief) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Featured story
            if let topStory = brief.items.first(where: { $0.category == .topStories }) {
                featuredStoryCard(topStory)
            }
            
            // Source logos carousel
            sourceLogosRow(brief)
        }
    }
    
    private func featuredStoryCard(_ item: BriefItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SourceLogoView(source: item.content.source, size: .small)
                
                Text(item.content.source.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(item.content.relativeTimeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(item.content.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            if !item.summary.isEmpty {
                Text(item.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func sourceLogosRow(_ brief: DailyBrief) -> some View {
        let uniqueSources = getUniqueSources(from: brief)
        
        return HStack(spacing: 0) {
            HStack(spacing: -8) {
                ForEach(Array(uniqueSources.prefix(5).enumerated()), id: \.offset) { index, source in
                    SourceLogoView(source: source, size: .small)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .zIndex(Double(5 - index))
                }
            }
            
            if uniqueSources.count > 5 {
                Text("+\(uniqueSources.count - 5)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.leading, 12)
            }
            
            Spacer()
            
            Text("Tap to explore →")
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Metrics Bar
    
    private func metricsBar(_ brief: DailyBrief) -> some View {
        HStack(spacing: 16) {
            metricItem(icon: "flame", value: "\(getTrendingCount(brief))", label: "Trending")
            metricItem(icon: "sparkles", value: "\(getNewCount(brief))", label: "New")
            metricItem(icon: "person.2", value: "\(getEngagementScore(brief))%", label: "Relevance")
        }
    }
    
    private func metricItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Expanded Content
    
    private func expandedContent(_ brief: DailyBrief) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sticky header
            VStack(alignment: .leading, spacing: 16) {
                briefHeader(brief, isCollapsed: false)
                
                // Category tabs
                categoryTabs(brief)
            }
            .padding(20)
            .background(Color(.systemBackground))
            
            Divider()
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Group by category
                    ForEach(BriefCategory.allCases, id: \.self) { category in
                        let items = brief.items.filter { $0.category == category }
                        if !items.isEmpty {
                            categorySection(category: category, items: items)
                        }
                    }
                }
                .padding(20)
            }
            .frame(maxHeight: 500)
            
            // Footer actions
            Divider()
            
            footerActions(brief)
        }
    }
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        Menu {
            ForEach(BriefMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                    Task {
                        await generator.generateBrief(mode: mode)
                    }
                } label: {
                    Label(mode.displayName, systemImage: mode.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedMode.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Category Tabs
    
    @State private var selectedCategory: BriefCategory? = nil
    
    private func categoryTabs(_ brief: DailyBrief) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All tab
                TabButton(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    count: brief.items.count
                ) {
                    selectedCategory = nil
                }
                
                // Category tabs
                ForEach(BriefCategory.allCases, id: \.self) { category in
                    let count = brief.items.filter { $0.category == category }.count
                    if count > 0 {
                        TabButton(
                            title: category.displayName,
                            icon: category.icon,
                            isSelected: selectedCategory == category,
                            count: count,
                            color: category.color
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Category Section
    
    private func categorySection(category: BriefCategory, items: [BriefItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.body)
                    .foregroundColor(category.color)
                
                Text(category.displayName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(items) { item in
                    enhancedItemCard(item)
                }
            }
        }
    }
    
    // MARK: - Enhanced Item Card
    
    private func enhancedItemCard(_ item: BriefItem) -> some View {
        NavigationLink(destination: ContentDetailView(item: item.content)) {
            HStack(alignment: .top, spacing: 12) {
                // Source logo
                SourceLogoView(source: item.content.source, size: .medium)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Source and time
                    HStack {
                        Text(item.content.source.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if isBreaking(item) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                        }
                        
                        Spacer()
                        
                        Text(item.content.relativeTimeString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Title
                    Text(item.content.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    // Summary
                    if !item.summary.isEmpty {
                        Text(item.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Reason chip
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text(item.reason)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(item.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.category.color.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                // Media preview
                if item.content.hasMedia {
                    MediaPreviewView(item: item.content, size: .small)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Footer Actions
    
    private func footerActions(_ brief: DailyBrief) -> some View {
        HStack(spacing: 16) {
            Button {
                // Share brief
                HapticManager.shared.impact(.light)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
            }
            
            Spacer()
            
            Button {
                // Mark all as read
                HapticManager.shared.success()
            } label: {
                Label("Mark All Read", systemImage: "checkmark.circle")
                    .font(.subheadline)
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                }
            } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(20)
    }
    
    // MARK: - Loading & Error Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            VStack(spacing: 4) {
                Text("Curating your brief...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Analyzing \(appModel.selectedSources.count) sources")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var errorView: some View {
        ErrorRetryView(
            message: "Unable to generate your brief",
            error: generator.lastError
        ) {
            Task {
                await generator.generateBrief()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private func getUniqueSources(from brief: DailyBrief) -> [Source] {
        var seen = Set<UUID>()
        return brief.items.compactMap { item in
            guard !seen.contains(item.content.source.id) else { return nil }
            seen.insert(item.content.source.id)
            return item.content.source
        }
    }
    
    private func isBreaking(_ item: BriefItem) -> Bool {
        // Consider items less than 30 minutes old as breaking
        return item.content.date.timeIntervalSinceNow > -1800
    }
    
    private func getTrendingCount(_ brief: DailyBrief) -> Int {
        brief.items.filter { $0.category == .trending }.count
    }
    
    private func getNewCount(_ brief: DailyBrief) -> Int {
        let cutoff = Date().addingTimeInterval(-3600) // Last hour
        return brief.items.filter { $0.content.date > cutoff }.count
    }
    
    private func getEngagementScore(_ brief: DailyBrief) -> Int {
        // Mock engagement score based on source diversity and recency
        let sourceCount = getUniqueSources(from: brief).count
        let recentCount = getNewCount(brief)
        return min(95, sourceCount * 10 + recentCount * 5)
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.gradient : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Enhanced Daily Brief") {
    NavigationStack {
        ScrollView {
            EnhancedDailyBriefView(generator: {
                let appModel = AppModel()
                let generator = DailyBriefGenerator(appModel: appModel)
                
                // Create comprehensive mock brief
                let items = [
                    BriefItem(
                        content: ContentItem.sampleItems[0],
                        reason: "Top story from your sources",
                        summary: "Apple announces groundbreaking new framework for building cross-platform applications with SwiftUI.",
                        category: .topStories,
                        priority: 0
                    ),
                    BriefItem(
                        content: ContentItem.sampleItems[1],
                        reason: "Trending in tech community",
                        summary: "Microsoft's latest AI model shows significant improvements in natural language understanding.",
                        category: .trending,
                        priority: 1
                    ),
                    BriefItem(
                        content: ContentItem.sampleItems[2],
                        reason: "From your favorite podcast",
                        summary: "Deep dive into the future of quantum computing and its practical applications.",
                        category: .podcasts,
                        priority: 2
                    )
                ]
                
                generator.currentBrief = DailyBrief(
                    items: items,
                    readTime: 300,
                    mode: .standard
                )
                
                return generator
            }())
            .padding()
        }
        .environment(AppModel())
    }
}
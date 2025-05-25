import SwiftUI

/// The main daily brief view that can be collapsed or expanded
struct DailyBriefView: View {
    @State private var isExpanded = false
    @State private var selectedItem: BriefItem?
    @State private var showContentDetail = false
    @ObservedObject var generator: DailyBriefGenerator
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        Group {
            if let brief = generator.currentBrief {
                if isExpanded {
                    expandedView(brief)
                } else {
                    collapsedView(brief)
                }
            } else {
                loadingView
            }
        }
        .task {
            if generator.currentBrief == nil && !generator.isGenerating {
                await generator.generateBrief()
            }
        }
        .navigationDestination(isPresented: $showContentDetail) {
            if let item = selectedItem {
                ContentDetailView(item: item.content)
            }
        }
    }
    
    // MARK: - Collapsed View
    
    private func collapsedView(_ brief: DailyBrief) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: brief.mode.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Brief")
                            .font(.headline)
                        Text("\(brief.items.count) stories • \(brief.readTimeMinutes) min read")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Preview of first item
                if let firstItem = brief.items.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(firstItem.content.title)
                            .font(.subheadline)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        Text(firstItem.summary)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Category pills
                HStack(spacing: 8) {
                    ForEach(brief.items.prefix(3)) { item in
                        CategoryPill(category: item.category)
                    }
                    
                    if brief.items.count > 3 {
                        Text("+\(brief.items.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Expanded View
    
    private func expandedView(_ brief: DailyBrief) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: brief.mode.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Brief")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text(brief.mode.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("•")
                        Text("\(brief.readTimeMinutes) min read")
                        Text("•")
                        Text(formatDate(brief.date))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.up.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Content sections
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(BriefCategory.allCases, id: \.self) { category in
                        let items = brief.items.filter { $0.category == category }
                        if !items.isEmpty {
                            BriefSection(
                                category: category,
                                items: items,
                                onItemTap: { item in
                                    selectedItem = item
                                    showContentDetail = true
                                    
                                    // Record engagement
                                    generator.recordEngagement(
                                        briefItemId: item.id,
                                        contentId: item.content.id,
                                        timeSpent: 0,
                                        action: .clicked
                                    )
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            
            // Refresh button
            HStack {
                Spacer()
                Button {
                    Task {
                        await generator.generateBrief()
                    }
                } label: {
                    Label("Refresh Brief", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(generator.isGenerating)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Generating your brief...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Brief Section Component

struct BriefSection: View {
    let category: BriefCategory
    let items: [BriefItem]
    let onItemTap: (BriefItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            
            // Items
            VStack(spacing: 12) {
                ForEach(items) { item in
                    BriefItemRow(item: item, onTap: { onItemTap(item) })
                }
            }
        }
    }
}

// MARK: - Brief Item Row

struct BriefItemRow: View {
    let item: BriefItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Source and time
                HStack {
                    Image(systemName: item.content.type.icon)
                        .font(.caption)
                        .foregroundColor(item.content.type.color)
                    
                    Text(item.content.source.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.content.date.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Title
                Text(item.content.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Summary
                Text(item.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Reason for inclusion
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text(item.reason)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                // Context if available
                if let context = item.context {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(context)
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let category: BriefCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            Text(category.displayName)
                .font(.caption2)
        }
        .foregroundColor(category.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    DailyBriefView(generator: {
        let appModel = AppModel()
        let generator = DailyBriefGenerator(appModel: appModel)
        
        // Create mock brief
        let items = [
            BriefItem(
                content: ContentItem.sampleItems[0],
                reason: "Top story from your sources",
                summary: "Apple announces groundbreaking new framework that promises to revolutionize iOS development...",
                category: .topStories,
                priority: 0
            ),
            BriefItem(
                content: ContentItem.sampleItems[1],
                reason: "Trending in your network",
                summary: "Community discusses the implications of the latest SwiftUI updates and what it means for developers...",
                category: .trending,
                priority: 1
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
    .environment(AppModel())
}

#Preview("Expanded") {
    DailyBriefView(generator: {
        let appModel = AppModel()
        let generator = DailyBriefGenerator(appModel: appModel)
        
        // Create comprehensive mock brief
        let items = ContentItem.sampleItems.enumerated().map { index, content in
            BriefItem(
                content: content,
                reason: SelectionReason.topStory.explanation,
                context: index % 2 == 0 ? "Related to your SwiftUI project" : nil,
                summary: "This is a summary of the content that provides key insights in 2-3 sentences. It helps users quickly understand what the article is about.",
                category: {
                    switch content.type {
                    case .article: return .topStories
                    case .reddit: return .trending
                    case .podcast: return .podcasts
                    case .mastodon, .bluesky: return .social
                    }
                }(),
                priority: index
            )
        }
        
        generator.currentBrief = DailyBrief(
            items: items,
            readTime: 600,
            mode: .standard
        )
        
        return generator
    }())
    .padding()
    .environment(AppModel())
}
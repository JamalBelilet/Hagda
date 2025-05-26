import SwiftUI

/// A simplified daily brief view
struct DailyBriefView: View {
    @State private var isExpanded = false
    @ObservedObject var generator: DailyBriefGenerator
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        Group {
            if let brief = generator.currentBrief {
                briefCard(brief)
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
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Collapsed Content
    
    private func collapsedContent(_ brief: DailyBrief) -> some View {
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
                        .accessibilityIdentifier("BriefModeIcon")
                    
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
                
                // Source previews
                sourcePreviewsRow(brief)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("DailyBriefCard")
    }
    
    // MARK: - Source Previews Row
    
    private func sourcePreviewsRow(_ brief: DailyBrief) -> some View {
        let todaysItems = getTodaysItemsBySource(from: brief)
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(todaysItems.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        sourcePreviewItem(item)
                        
                        // Add dot separator except after last item
                        if index < todaysItems.count - 1 {
                            Circle()
                                .fill(Color.secondary.opacity(0.5))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func sourcePreviewItem(_ item: BriefItem) -> some View {
        HStack(spacing: 6) {
            // Source icon
            Image(systemName: item.content.source.type.icon)
                .font(.caption2)
                .foregroundColor(item.category.color)
                .frame(width: 16, height: 16)
            
            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                Text(item.content.source.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(item.content.title)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // Helper function to get today's items grouped by source
    private func getTodaysItemsBySource(from brief: DailyBrief) -> [BriefItem] {
        let calendar = Calendar.current
        _ = Date()
        
        // Filter items published today
        let todaysItems = brief.items.filter { item in
            calendar.isDateInToday(item.content.date)
        }
        
        // Group by source and take first from each
        var seenSources = Set<UUID>()
        var uniqueSourceItems: [BriefItem] = []
        
        for item in todaysItems {
            if !seenSources.contains(item.content.source.id) {
                seenSources.insert(item.content.source.id)
                uniqueSourceItems.append(item)
            }
        }
        
        // If no items from today, show most recent from each source
        if uniqueSourceItems.isEmpty {
            seenSources.removeAll()
            for item in brief.items {
                if !seenSources.contains(item.content.source.id) {
                    seenSources.insert(item.content.source.id)
                    uniqueSourceItems.append(item)
                }
                // Limit to 4 sources for space
                if uniqueSourceItems.count >= 4 {
                    break
                }
            }
        }
        
        return uniqueSourceItems
    }
    
    // MARK: - Expanded Content
    
    private func expandedContent(_ brief: DailyBrief) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: brief.mode.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Brief")
                        .font(.headline)
                    Text("\(brief.mode.displayName) • \(brief.readTimeMinutes) min read")
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
            .padding()
            
            // Items
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(brief.items) { item in
                        itemRow(item)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxHeight: 400)
            .accessibilityIdentifier("BriefItemsScrollView")
        }
    }
    
    // MARK: - Item Row
    
    private func itemRow(_ item: BriefItem) -> some View {
        NavigationLink(destination: ContentDetailView(item: item.content)) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: item.category.icon)
                        .font(.caption)
                        .foregroundColor(item.category.color)
                    
                    Text(item.content.source.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.content.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Title
                Text(item.content.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Summary
                Text(item.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Reason
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text(item.reason)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("BriefItemRow")
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
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DailyBriefView(generator: {
            let appModel = AppModel()
            let generator = DailyBriefGenerator(appModel: appModel)
            
            // Create mock brief
            let items = [
                BriefItem(
                    content: ContentItem.sampleItems[0],
                    reason: "Top story from your sources",
                    summary: "Apple announces groundbreaking new framework...",
                    category: .topStories,
                    priority: 0
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
}
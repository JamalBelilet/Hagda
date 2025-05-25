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
        .background(Color(.systemGray6))
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
                
                // Preview
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
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
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
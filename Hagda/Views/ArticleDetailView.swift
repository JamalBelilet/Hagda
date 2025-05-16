import SwiftUI

/// Type-specific view for articles
struct ArticleDetailView: View {
    let item: ContentItem
    @State private var viewModel: ArticleDetailViewModel
    
    init(item: ContentItem) {
        self.item = item
        self._viewModel = State(initialValue: ArticleDetailViewModel(item: item))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Article metadata
            HStack {
                if !viewModel.authorName.isEmpty {
                    Text(viewModel.authorName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !viewModel.authorName.isEmpty && !viewModel.sourceName.isEmpty {
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !viewModel.sourceName.isEmpty {
                    Text(viewModel.sourceName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(viewModel.estimatedReadingTime) min read")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Loading indicator
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }
            
            // Error message
            if let error = viewModel.error {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("Could not load details")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                }
            }
            
            // Article image
            if viewModel.hasImage, let imageURL = viewModel.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        #if os(iOS) || os(visionOS)
                        .fill(Color(.secondarySystemBackground))
                        #else
                        .fill(Color.gray.opacity(0.2))
                        #endif
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            Image(systemName: "newspaper")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                        )
                }
            } else {
                // Placeholder image
                RoundedRectangle(cornerRadius: 8)
                    #if os(iOS) || os(visionOS)
                    .fill(Color(.secondarySystemBackground))
                    #else
                    .fill(Color.gray.opacity(0.2))
                    #endif
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "newspaper")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                    )
            }
            
            // Article summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)
                    .padding(.top, 8)
                
                Text(viewModel.summary)
                    .font(.body)
                    .lineSpacing(5)
            }
            
            // Next section preview if we have progress
            if viewModel.progressPercentage > 0 {
                upNextSection
            }
            
            // Read more button
            Button {
                // Action to open the full article
            } label: {
                HStack {
                    Text("Read Full Article")
                    Image(systemName: "safari")
                }
                .font(.headline)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                #if os(iOS) || os(visionOS)
                .background(Color(.secondarySystemBackground))
                #else
                .background(Color.gray.opacity(0.2))
                #endif
                .foregroundColor(.primary)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                )
            }
            .padding(.top, 12)
        }
    }
    
    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Up Next in This Article")
                .font(.headline)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(viewModel.remainingReadingTime) min left to read")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentColor)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.progressPercentage * 100))% completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(viewModel.remainingContentSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)
            }
            .padding()
            #if os(iOS) || os(visionOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color.gray.opacity(0.15))
            #endif
            .cornerRadius(10)
        }
    }
}

// MARK: - Preview

#Preview("Article") {
    ArticleDetailView(item: ContentItem(
        title: "The Future of AI Development: What's Next in 2025",
        subtitle: "By John Smith • TechCrunch",
        date: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
        type: .article,
        contentPreview: """
        The article continues with an exploration of advanced AI algorithms and their real-world applications:
        
        • Case studies of successful AI implementations in enterprise
        • Technical breakdown of transformer architecture advancements
        • Ethical considerations for AI deployment
        • Future predictions from leading researchers
        """,
        progressPercentage: 0.35
    ))
}
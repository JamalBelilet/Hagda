import SwiftUI

/// Type-specific view for Reddit posts
struct RedditDetailView: View {
    let item: ContentItem
    @State private var viewModel: RedditDetailViewModel
    @StateObject private var progressTracker = RedditProgressTracker.shared
    @State private var showComments = false
    
    init(item: ContentItem) {
        self.item = item
        self._viewModel = State(initialValue: RedditDetailViewModel(item: item))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Community info
            HStack {
                Text(viewModel.subredditName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    // Join action
                } label: {
                    Text("Join")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        #if os(iOS) || os(visionOS)
                        .background(Color(.secondarySystemBackground))
                        #else
                        .background(Color.gray.opacity(0.2))
                        #endif
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor, lineWidth: 1)
                        )
                }
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
            
            // Post info
            HStack {
                Text("Posted by u/\(viewModel.authorName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(viewModel.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Post content
            Text(viewModel.postContent)
                .font(.body)
                .lineSpacing(5)
                .onAppear {
                    // Mark post as read when content appears
                    progressTracker.markPostAsRead(item: item)
                }
            
            // Optional image
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
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                        )
                }
            }
            
            // Comment stats and actions
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                    Text("\(viewModel.upvoteCount)")
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                    Text("\(viewModel.commentCount) comments")
                }
                
                Spacer()
                
                Button {
                    // Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
            
            // Comment section
            VStack(alignment: .leading, spacing: 16) {
                Text("Top Comments")
                    .font(.headline)
                
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading comments...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if let error = viewModel.error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unable to load comments")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                } else if viewModel.comments.isEmpty {
                    Text("No comments yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.comments) { comment in
                        CommentView(comment: comment, depth: 0)
                    }
                }
            }
        }
        .onAppear {
            progressTracker.startTracking(for: item)
        }
        .onDisappear {
            progressTracker.stopTracking()
        }
    }
}

// MARK: - Comment View

/// View for displaying a single comment with support for nested replies
struct CommentView: View {
    let comment: RedditDetailViewModel.Comment
    let depth: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Comment content
            HStack(alignment: .top, spacing: 0) {
                // Depth indicator
                if depth > 0 {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 2)
                        .padding(.trailing, 8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(comment.authorName)
                            .fontWeight(.bold)
                        
                        Text("• \(comment.timestamp)")
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("↑ \(comment.upvotes)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    
                    Text(comment.content)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.leading, CGFloat(depth * 16))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            #if os(iOS) || os(visionOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color.gray.opacity(0.2))
            #endif
            .cornerRadius(8)
            
            // Nested replies
            ForEach(comment.replies) { reply in
                CommentView(comment: reply, depth: depth + 1)
            }
        }
    }
}

// MARK: - Preview

#Preview("Reddit Post") {
    RedditDetailView(item: ContentItem(
        title: "I built this cool app to track my programming habits",
        subtitle: "Posted by u/dev_enthusiast • r/programming • 42 comments",
        date: Date().addingTimeInterval(-3600 * 24), // 1 day ago
        type: .reddit,
        contentPreview: "I've been working on this project for a while and wanted to share my progress with the community. What do you all think about this approach? Any suggestions for improvements would be greatly appreciated!",
        progressPercentage: 0.0
    ))
}
import SwiftUI

/// Type-specific view for social media posts (Bluesky/Mastodon)
struct SocialDetailView: View {
    let item: ContentItem
    @State private var viewModel: SocialDetailViewModel
    
    init(item: ContentItem) {
        self.item = item
        self._viewModel = State(initialValue: SocialDetailViewModel(item: item))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User info
            HStack(spacing: 10) {
                if let avatarURL = viewModel.authorAvatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            #if os(iOS) || os(visionOS)
                            .fill(Color(.secondarySystemBackground))
                            #else
                            .fill(Color.gray.opacity(0.2))
                            #endif
                            .overlay(
                                Image(systemName: "person")
                                    .foregroundStyle(.tertiary)
                            )
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                } else {
                    Circle()
                        #if os(iOS) || os(visionOS)
                        .fill(Color(.secondarySystemBackground))
                        #else
                        .fill(Color.gray.opacity(0.2))
                        #endif
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "person")
                                .foregroundStyle(.tertiary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(viewModel.authorName.isEmpty ? 
                             (item.type == .bluesky ? "BlueSky User" : "Mastodon User") : 
                                viewModel.authorName)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(viewModel.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(viewModel.authorHandle.isEmpty ? item.subtitle : viewModel.authorHandle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            
            // Post content
            Text(viewModel.postContent)
                .font(.body)
                .lineSpacing(5)
            
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
            
            // Interaction stats
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Image(systemName: "heart")
                    Text("\(viewModel.likeCount)")
                }
                
                HStack(spacing: 6) {
                    // Different icon for Mastodon and BlueSky
                    Image(systemName: item.type == .mastodon ? "arrow.triangle.2.circlepath" : "arrow.2.squarepath")
                    Text("\(viewModel.repostCount)")
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                    Text("\(viewModel.replyCount)")
                }
                
                Spacer()
                
                Image(systemName: "bookmark")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
            
            Divider()
            
            // Reply section
            VStack(alignment: .leading, spacing: 12) {
                Text("Replies")
                    .font(.headline)
                
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading replies...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if let error = viewModel.error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unable to load replies")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                } else if viewModel.replies.isEmpty {
                    Text("No replies yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.replies) { reply in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                if let avatarURL = reply.authorAvatarURL {
                                    AsyncImage(url: avatarURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            #if os(iOS) || os(visionOS)
                                            .fill(Color(.secondarySystemBackground))
                                            #else
                                            .fill(Color.gray.opacity(0.2))
                                            #endif
                                            .overlay(
                                                Image(systemName: "person")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.tertiary)
                                            )
                                    }
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        #if os(iOS) || os(visionOS)
                                        .fill(Color(.secondarySystemBackground))
                                        #else
                                        .fill(Color.gray.opacity(0.2))
                                        #endif
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: "person")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.tertiary)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(reply.authorName)
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Text(reply.timestamp)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Text(reply.authorHandle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Text(reply.content)
                                .font(.subheadline)
                        }
                        .padding()
                        #if os(iOS) || os(visionOS)
                        .background(Color(.secondarySystemBackground))
                        #else
                        .background(Color.gray.opacity(0.2))
                        #endif
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("BlueSky") {
    SocialDetailView(item: ContentItem(
        title: "Just shipped a major update to our app! Would love your feedback on the new UI and performance improvements.",
        subtitle: "@techcreator.bsky.social",
        date: Date().addingTimeInterval(-3600 * 3), // 3 hours ago
        type: .bluesky,
        contentPreview: "The thread continues with details about the technical challenges overcome and a link to the release notes. Several users have already provided positive feedback.",
        progressPercentage: 0.25
    ))
}

#Preview("Mastodon") {
    SocialDetailView(item: ContentItem(
        title: "We've just released a new version of our open source library. Check it out and let us know what you think!",
        subtitle: "@developer@mastodon.social",
        date: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
        type: .mastodon,
        contentPreview: "The post continues with technical details about the update and links to the documentation.",
        progressPercentage: 0.0
    ))
}
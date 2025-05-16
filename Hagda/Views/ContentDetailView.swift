import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#endif

/// A detail view for content items with type-specific layouts
struct ContentDetailView: View {
    let item: ContentItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Common header
                commonHeader
                
                // Divider between header and content
                Divider()
                
                // Type-specific content
                switch item.type {
                case .article:
                    ArticleDetailView(item: item)
                case .reddit:
                    RedditDetailView(item: item)
                case .bluesky, .mastodon:
                    SocialDetailView(item: item)
                case .podcast:
                    PodcastDetailView(item: item)
                }
            }
            .padding()
        }
        .navigationTitle("")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS) || os(visionOS)
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: item.typeIcon)
                        .foregroundStyle(.secondary)
                    Text(item.type.displayName)
                        .font(.headline)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // Share action would go here
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            #else
            ToolbarItem {
                HStack {
                    Image(systemName: item.typeIcon)
                        .foregroundStyle(.secondary)
                    Text(item.type.displayName)
                        .font(.headline)
                }
            }
            
            ToolbarItem {
                Button(action: {
                    // Share action would go here
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            #endif
        }
        .accessibilityIdentifier("ContentDetail-\(item.id)")
    }
    
    /// Common header for all content types
    private var commonHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .font(.title)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(item.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(item.relativeTimeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }
}

/// Type-specific view for articles
struct ArticleDetailView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Article image
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
            
            // Article summary
            Text("Summary")
                .font(.headline)
                .padding(.top, 8)
            
            Text(generateMockContent())
                .font(.body)
                .lineSpacing(5)
            
            // Next section preview if we have progress
            if item.progressPercentage > 0 {
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
                    Text(item.remainingContentInfo)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentColor)
                    
                    Spacer()
                    
                    Text("\(Int(item.progressPercentage * 100))% completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(item.remainingContentSummary)
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
    
    private func generateMockContent() -> String {
        return """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam vulputate velit non enim faucibus, nec ultrices nisi accumsan. Maecenas dignissim lectus id nisi tempus, in efficitur risus fermentum. Sed rhoncus magna ac orci convallis, in imperdiet nibh fermentum.
        
        Donec luctus, est vitae tempus dignissim, nisl lorem tincidunt nisi, vel tristique nisi tellus eu magna. Proin feugiat felis vel lorem faucibus, ac viverra magna sodales. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae.
        """
    }
}

/// Type-specific view for Reddit posts
struct RedditDetailView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Community info
            HStack {
                Text("r/" + (item.subtitle.contains("r/") ? item.subtitle.split(separator: "r/")[1].split(separator: " ")[0] : "subreddit"))
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
            
            // Post content
            Text(generateMockContent())
                .font(.body)
                .lineSpacing(5)
            
            // Possible image content
            if Bool.random() {
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
            
            // Comment stats and actions
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                    Text("3.4k")
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                    Text("124 comments")
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
                
                ForEach(1...3, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("u/user\(i)")
                                .fontWeight(.bold)
                            
                            Text("• \(Int.random(in: 1...12))h ago")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("↑ \(Int.random(in: 10...300))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        
                        Text(i == 1 ? "This is really interesting! I've been following this for a while and it's great to see some quality content on the topic." : "Thanks for sharing, I learned something new today.")
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
    
    private func generateMockContent() -> String {
        return "I've been working on this project for a while and wanted to share my progress with the community. What do you all think about this approach? Any suggestions for improvements would be greatly appreciated!"
    }
}

/// Type-specific view for social media posts (Bluesky/Mastodon)
struct SocialDetailView: View {
    let item: ContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User info
            HStack(spacing: 10) {
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
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.type == .bluesky ? "Jay Doe" : "Jay Mastodon")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(item.relativeTimeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Post content
            Text(item.title)
                .font(.body)
                .lineSpacing(5)
            
            // Optional image
            if Bool.random() {
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
            
            // Interaction stats
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Image(systemName: "heart")
                    Text("\(Int.random(in: 5...200))")
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.2.squarepath")
                    Text("\(Int.random(in: 1...50))")
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                    Text("\(Int.random(in: 1...30))")
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
                
                ForEach(1...2, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
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
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("User \(i)")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(Int.random(in: 1...12))h")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text(item.type == .bluesky ? "@user\(i).bsky.social" : "@user\(i)@mastodon.social")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text(i == 1 ? "Great insights! I'd love to hear more about your perspective on this." : "I've had a similar experience and completely agree with your points.")
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

/// Type-specific view for podcast episodes
struct PodcastDetailView: View {
    let item: ContentItem
    @State private var isPlaying = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Episode artwork
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    #if os(iOS) || os(visionOS)
                    .fill(Color(.secondarySystemBackground))
                    #else
                    .fill(Color.gray.opacity(0.2))
                    #endif
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "headphones")
                            .font(.system(size: 50))
                            .foregroundStyle(.tertiary)
                    )
                
                Text(item.subtitle.contains("minutes") ? item.subtitle : "45 minutes • Interview")
                    .font(.caption)
                    .padding(8)
                    #if os(iOS) || os(visionOS)
                    .background(.ultraThinMaterial)
                    #else
                    .background(Color.gray.opacity(0.15))
                    #endif
                    .cornerRadius(8)
                    .padding(12)
            }
            
            // Player controls
            VStack(spacing: 12) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            #if os(iOS) || os(visionOS)
                            .fill(Color(.systemGray5))
                            #else
                            .fill(Color.gray.opacity(0.2))
                            #endif
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(item.progressPercentage), height: 4)
                            .cornerRadius(2)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                            .offset(x: geometry.size.width * CGFloat(item.progressPercentage) - 7)
                    }
                }
                .frame(height: 20)
                
                // Time indicators
                HStack {
                    Text(formatTime(seconds: Int(1800 * item.progressPercentage)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("-\(formatTime(seconds: Int(1800 * (1 - item.progressPercentage))))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Control buttons
                HStack(spacing: 40) {
                    Button {
                        // Rewind 15s
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 28))
                    }
                    
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                            .font(.system(size: 54))
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    Button {
                        // Forward 15s
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 28))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                
                // Playback options
                HStack(spacing: 40) {
                    Button {
                        // Download
                    } label: {
                        Image(systemName: "arrow.down.circle")
                    }
                    
                    Button {
                        // Speed
                    } label: {
                        Text("1.0x")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            #if os(iOS) || os(visionOS)
                            .background(Color(.secondarySystemBackground))
                            #else
                            .background(Color.gray.opacity(0.2))
                            #endif
                            .cornerRadius(6)
                    }
                    
                    Button {
                        // Sleep timer
                    } label: {
                        Image(systemName: "timer")
                    }
                    
                    Button {
                        // Share
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 20)
            
            // Episode description
            Text("Episode Description")
                .font(.headline)
                .padding(.top, 4)
            
            Text(generateMockContent())
                .font(.body)
                .lineSpacing(5)
            
            // What's coming up next section
            if item.progressPercentage > 0 {
                comingUpNextSection
            }
            
            // Episode notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Show Notes")
                    .font(.headline)
                    .padding(.top, 12)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(1...3, id: \.self) { i in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("Topic \(i): \(["Understanding modern development tools", "Interview with tech expert Anna Johnson", "Discussion on the future of AI"][i-1])")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
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
    
    private var comingUpNextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coming Up Next")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(item.remainingContentInfo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.remainingContentSummary)
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
    
    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func generateMockContent() -> String {
        return """
        In this episode, we dive deep into technology trends that are shaping our digital landscape. Our host interviews industry experts about their insights on emerging technologies, development practices, and predictions for the future.
        
        Topics covered include artificial intelligence, development frameworks, and the changing patterns in how we consume digital content.
        """
    }
}

// MARK: - Preview

#Preview("Article") {
    NavigationStack {
        ContentDetailView(item: ContentItem(
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
}

#Preview("Reddit") {
    NavigationStack {
        ContentDetailView(item: ContentItem(
            title: "I built this cool app to track my programming habits",
            subtitle: "Posted by u/dev_enthusiast • r/programming • 42 comments",
            date: Date().addingTimeInterval(-3600 * 24), // 1 day ago
            type: .reddit,
            contentPreview: "The post continues with implementation details and includes code snippets showing how the tracking mechanism works. Several users have shared their own approaches in the comments.",
            progressPercentage: 0.40
        ))
    }
}

#Preview("Social") {
    NavigationStack {
        ContentDetailView(item: ContentItem(
            title: "Just shipped a major update to our app! Would love your feedback on the new UI and performance improvements.",
            subtitle: "@techcreator.bsky.social",
            date: Date().addingTimeInterval(-3600 * 3), // 3 hours ago
            type: .bluesky,
            contentPreview: "The thread continues with details about the technical challenges overcome and a link to the release notes. Several users have already provided positive feedback.",
            progressPercentage: 0.25
        ))
    }
}

#Preview("Podcast") {
    NavigationStack {
        ContentDetailView(item: ContentItem(
            title: "Episode 245: The State of Modern Development",
            subtitle: "45 minutes • Interview",
            date: Date().addingTimeInterval(-3600 * 36), // 1.5 days ago
            type: .podcast,
            contentPreview: """
            Coming up in this episode:
            
            • Interview with the lead architect of a popular framework
            • Discussion on performance optimization techniques
            • Q&A segment addressing common developer questions
            • Resource recommendations and tools for modern developers
            """,
            progressPercentage: 0.65
        ))
    }
}

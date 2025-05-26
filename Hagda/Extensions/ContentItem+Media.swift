import Foundation
import SwiftUI

// MARK: - Media Support Extensions

extension ContentItem {
    /// Media type for content items
    enum MediaType: String {
        case image = "image"
        case video = "video"
        case audio = "audio"
        case gallery = "gallery"
    }
    
    /// Returns the thumbnail URL if available
    var thumbnailURL: String? {
        metadata["thumbnailURL"] as? String
    }
    
    /// Returns the media type if available
    var mediaType: MediaType? {
        guard let typeString = metadata["mediaType"] as? String else { return nil }
        return MediaType(rawValue: typeString)
    }
    
    /// Returns true if the content has any media
    var hasMedia: Bool {
        thumbnailURL != nil || mediaType != nil
    }
    
    /// Returns the hero image URL if available (for articles)
    var heroImageURL: String? {
        metadata["heroImageURL"] as? String ?? thumbnailURL
    }
    
    /// Returns video duration if available
    var videoDuration: TimeInterval? {
        metadata["videoDuration"] as? TimeInterval
    }
    
    /// Returns the number of images in a gallery
    var galleryImageCount: Int? {
        metadata["galleryImageCount"] as? Int
    }
    
    /// Returns audio URL for podcast episodes
    var audioURL: String? {
        metadata["audioURL"] as? String
    }
    
    /// Returns episode duration for podcasts
    var episodeDuration: TimeInterval? {
        metadata["duration"] as? TimeInterval
    }
}

// MARK: - Media Preview View

struct MediaPreviewView: View {
    let item: ContentItem
    let size: MediaSize
    
    enum MediaSize {
        case small  // 60x60
        case medium // 100x100
        case large  // Full width
        
        var dimension: CGFloat? {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return nil // Full width
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
    }
    
    var body: some View {
        Group {
            if let thumbnailURL = item.thumbnailURL {
                AsyncImage(url: URL(string: thumbnailURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: size == .large ? .fit : .fill)
                            .overlay(mediaTypeOverlay)
                    case .failure(_):
                        placeholderView
                    case .empty:
                        ProgressView()
                            .frame(width: size.dimension, height: size.dimension)
                    @unknown default:
                        placeholderView
                    }
                }
                .frame(
                    width: size.dimension,
                    height: size == .large ? nil : size.dimension
                )
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            } else {
                placeholderView
            }
        }
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(Color(.systemGray5))
            .frame(
                width: size.dimension,
                height: size == .large ? 200 : size.dimension
            )
            .overlay(
                Image(systemName: mediaIcon)
                    .font(.title3)
                    .foregroundColor(.secondary)
            )
    }
    
    @ViewBuilder
    private var mediaTypeOverlay: some View {
        if let mediaType = item.mediaType {
            VStack {
                Spacer()
                HStack {
                    switch mediaType {
                    case .video:
                        if let duration = item.videoDuration {
                            VideoDurationBadge(duration: duration)
                        }
                    case .gallery:
                        if let count = item.galleryImageCount {
                            GalleryCountBadge(count: count)
                        }
                    default:
                        EmptyView()
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
    }
    
    private var mediaIcon: String {
        switch item.mediaType {
        case .video:
            return "play.rectangle"
        case .audio:
            return "waveform"
        case .gallery:
            return "photo.on.rectangle"
        default:
            return "photo"
        }
    }
}

// MARK: - Media Badge Components

struct VideoDurationBadge: View {
    let duration: TimeInterval
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.fill")
                .font(.caption2)
            Text(formatDuration(duration))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.7))
        .clipShape(Capsule())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct GalleryCountBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "photo.stack")
                .font(.caption2)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.7))
        .clipShape(Capsule())
    }
}

// MARK: - Enhanced Item Card with Media

struct EnhancedItemCardWithMedia: View {
    let item: ContentItem
    @State private var isImageLoaded = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Source logo
            SourceLogoView(source: item.source, size: .small)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Source and time
                HStack {
                    Text(item.source.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.relativeTimeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Title
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // Description
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Media preview
            if item.hasMedia {
                MediaPreviewView(item: item, size: .small)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.3), value: isImageLoaded)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation {
                isImageLoaded = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Media Preview") {
    VStack(spacing: 20) {
        // Sample items with different media types
        let videoItem = ContentItem(
            title: "New Video: SwiftUI Advanced Animations",
            subtitle: "Apple Developer",
            date: Date(),
            type: .article,
            metadata: [
                "thumbnailURL": "https://picsum.photos/400/300",
                "mediaType": "video",
                "videoDuration": 185.0
            ],
            source: Source(name: "Apple Developer", type: .article, description: "")
        )
        
        let galleryItem = ContentItem(
            title: "Photo Gallery: WWDC 2024 Highlights",
            subtitle: "TechCrunch",
            date: Date(),
            type: .article,
            metadata: [
                "thumbnailURL": "https://picsum.photos/400/300",
                "mediaType": "gallery",
                "galleryImageCount": 12
            ],
            source: Source(name: "TechCrunch", type: .article, description: "")
        )
        
        EnhancedItemCardWithMedia(item: videoItem)
        EnhancedItemCardWithMedia(item: galleryItem)
    }
    .padding()
}
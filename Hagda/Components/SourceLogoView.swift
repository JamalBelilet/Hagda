import SwiftUI

/// A view that displays a source's logo or icon with proper branding
struct SourceLogoView: View {
    let source: Source
    let size: LogoSize
    
    enum LogoSize {
        case small  // 20x20
        case medium // 32x32
        case large  // 48x48
        
        var dimension: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 32
            case .large: return 48
            }
        }
        
        var iconFont: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title2
            }
        }
    }
    
    var body: some View {
        Group {
            if let artworkUrl = source.artworkUrl {
                // Async image for sources with artwork (e.g., podcasts)
                AsyncImage(url: URL(string: artworkUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderView
                }
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(RoundedRectangle(cornerRadius: size.dimension * 0.2))
            } else {
                // Custom branded icons for known sources
                brandedIcon
            }
        }
    }
    
    @ViewBuilder
    private var brandedIcon: some View {
        ZStack {
            // Background with source type color
            RoundedRectangle(cornerRadius: size.dimension * 0.2)
                .fill(backgroundGradient)
                .frame(width: size.dimension, height: size.dimension)
            
            // Icon or initial
            if let icon = sourceSpecificIcon {
                Image(systemName: icon)
                    .font(size.iconFont)
                    .foregroundColor(.white)
            } else {
                // Fallback to first letter of source name
                Text(String(source.name.prefix(1)))
                    .font(.system(size: size.dimension * 0.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.dimension * 0.2)
                .fill(Color.gray.opacity(0.2))
            
            ProgressView()
                .scaleEffect(0.5)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
    
    private var backgroundGradient: LinearGradient {
        let baseColor = sourceColor
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var sourceColor: Color {
        // Source-specific colors for known sources
        switch source.name.lowercased() {
        case "techcrunch":
            return Color(red: 0.0, green: 0.8, blue: 0.0) // TechCrunch green
        case "the verge":
            return Color(red: 0.8, green: 0.0, blue: 0.4) // Verge magenta
        case "ars technica":
            return Color(red: 1.0, green: 0.4, blue: 0.0) // Ars orange
        case "mit technology review":
            return Color(red: 0.0, green: 0.0, blue: 0.0) // MIT black
        case "zdnet":
            return Color(red: 0.8, green: 0.0, blue: 0.0) // ZDNet red
        case "wired":
            return Color(red: 0.0, green: 0.0, blue: 0.0) // Wired black
        default:
            // Fallback to source type color
            return source.type.color
        }
    }
    
    private var sourceSpecificIcon: String? {
        // Custom icons for specific source types or names
        switch source.type {
        case .reddit:
            return "bubble.left.and.bubble.right.fill"
        case .bluesky:
            return "cloud.fill"
        case .mastodon:
            return "megaphone.fill"
        case .podcast:
            return "mic.fill"
        case .article:
            // Article sources get specific icons based on name
            switch source.name.lowercased() {
            case let name where name.contains("tech"):
                return "cpu"
            case let name where name.contains("science"):
                return "atom"
            case let name where name.contains("business"):
                return "chart.line.uptrend.xyaxis"
            default:
                return "doc.text.fill"
            }
        }
    }
}

// MARK: - Preview

#Preview("Logo Sizes") {
    VStack(spacing: 20) {
        ForEach([SourceLogoView.LogoSize.small, .medium, .large], id: \.dimension) { size in
            HStack(spacing: 16) {
                ForEach(Source.sampleSources.prefix(5), id: \.id) { source in
                    VStack {
                        SourceLogoView(source: source, size: size)
                        Text(source.name)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
    .padding()
}

#Preview("All Source Types") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(SourceType.allCases) { type in
                VStack(alignment: .leading) {
                    Text(type.displayName)
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                        ForEach(Source.sampleSources.filter { $0.type == type }.prefix(6), id: \.id) { source in
                            VStack {
                                SourceLogoView(source: source, size: .medium)
                                Text(source.name)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 80)
                        }
                    }
                }
            }
        }
        .padding()
    }
}
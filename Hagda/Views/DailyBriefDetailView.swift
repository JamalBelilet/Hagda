import SwiftUI

/// A view that displays detailed information about the daily brief
struct DailyBriefDetailView: View {
    @Environment(AppModel.self) private var appModel
    
    // Mock summary text segments with their associated sources
    private struct BriefSegment {
        let content: String
        let sources: [Source]
    }
    
    // Mock data for brief segments - will be dynamically generated in a real implementation
    @State private var briefSegments: [BriefSegment] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with the date
                headerView
                
                // Segment list showing each part of the brief
                segmentsList
            }
            .padding()
        }
        .navigationTitle("Today's Brief Details")
        .onAppear {
            // Generate mock data when the view appears
            generateMockBriefData()
        }
    }
    
    /// Header view with date and source info
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date heading
            Text(dateString)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Summary text
            Text("Your personalized tech brief based on your followed sources and preferences.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(5)
            
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    /// List of brief segments with their sources
    private var segmentsList: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(briefSegments.enumerated()), id: \.offset) { index, segment in
                VStack(alignment: .leading, spacing: 16) {
                    // Brief content
                    Text(segment.content)
                        .font(.body)
                        .lineSpacing(5)
                    
                    // Sources for this segment
                    sourcesListView(for: segment.sources)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }
    
    /// View displaying the sources for a brief segment
    private func sourcesListView(for sources: [Source]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sources for this insight:")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(sources) { source in
                HStack(spacing: 12) {
                    // Source icon
                    Image(systemName: source.type.icon)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Source name
                        Text(source.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        // Source type
                        Text(source.type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // View source button
                    NavigationLink(destination: SourceView(source: source)) {
                        Text("View")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // Current date string
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    // Generate mock brief data with associated sources
    private func generateMockBriefData() {
        // Get available sources from the app model
        let availableSources = appModel.feedSources
        
        if availableSources.isEmpty {
            // If no sources are available, show a placeholder
            briefSegments = [
                BriefSegment(
                    content: "Add sources to receive tailored technology updates from content that matters to you.",
                    sources: []
                )
            ]
            return
        }
        
        // Group sources by type
        let articleSources = availableSources.filter { $0.type == .article }
        let redditSources = availableSources.filter { $0.type == .reddit }
        let socialSources = availableSources.filter { $0.type == .bluesky || $0.type == .mastodon }
        let podcastSources = availableSources.filter { $0.type == .podcast }
        
        // Create brief segments with relevant sources
        var segments: [BriefSegment] = []
        
        if !articleSources.isEmpty {
            segments.append(
                BriefSegment(
                    content: "AI and quantum computing convergence is rapidly accelerating, with real-world enterprise applications now emerging across industries.",
                    sources: articleSources.prefix(2).shuffled()
                )
            )
        }
        
        if !redditSources.isEmpty {
            segments.append(
                BriefSegment(
                    content: "IT and security team convergence is trending in cybersecurity discussions, with implementation strategies and risk mitigation approaches being shared.",
                    sources: redditSources.prefix(2).shuffled()
                )
            )
        }
        
        if !socialSources.isEmpty {
            segments.append(
                BriefSegment(
                    content: "Satellite connectivity for smartphones is gaining traction, promising to transform rural connectivity and emergency services.",
                    sources: socialSources.prefix(2).shuffled()
                )
            )
        }
        
        if !podcastSources.isEmpty {
            segments.append(
                BriefSegment(
                    content: "Generative AI's capability across multiple modalities is evolving rapidly, significantly impacting content creation and organizational productivity.",
                    sources: podcastSources.prefix(2).shuffled()
                )
            )
        }
        
        // Add a trending topic if we have any sources
        if !availableSources.isEmpty {
            segments.append(
                BriefSegment(
                    content: "Key trends: post-quantum cryptography, augmented connected workforce, and sustainable technology practices.",
                    sources: Array(availableSources.shuffled().prefix(2))
                )
            )
        }
        
        // Update state
        briefSegments = segments
    }
}

#Preview {
    NavigationStack {
        DailyBriefDetailView()
            .environment(AppModel())
    }
}
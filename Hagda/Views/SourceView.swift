import SwiftUI

/// A detailed view for a specific source, showing metadata and content
struct SourceView: View {
    // MARK: - Properties
    
    let source: Source
    @Environment(AppModel.self) private var appModel
    @State private var isFollowing: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Header section
            Section {
                sourceHeader
            }
            
            // Content items section
            Section {
                ForEach(appModel.getContentForSource(source)) { item in
                    NavigationLink(destination: ContentDetailView(item: item)) {
                        ContentItemRow(item: item)
                    }
                }
            } header: {
                SectionHeaderView(
                    title: "Latest Content", 
                    description: "Recent posts from this source",
                    icon: source.type.icon
                )
            }
        }
        .navigationTitle(source.name)
        .listStyle(.inset)
        .scrollContentBackground(.visible)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            isFollowing = appModel.isSourceSelected(source)
        }
        .accessibilityIdentifier("SourceView-\(source.name)")
    }
    
    // MARK: - UI Components
    
    /// Header with source metadata and follow button
    private var sourceHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and title
            HStack(spacing: 14) {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: source.type.icon)
                            .font(.system(size: 30))
                            .foregroundStyle(Color.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let handle = source.handle {
                        Text(handle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.bottom, 8)
            
            // Description
            Text(source.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
            
            // Follow button
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        appModel.toggleSourceSelection(source)
                        isFollowing.toggle()
                    }
                }) {
                    Text(isFollowing ? "Following" : "Follow")
                        .fontWeight(.semibold)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
                .accessibilityLabel(isFollowing ? "Unfollow" : "Follow")
                .accessibilityIdentifier("FollowButton")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SourceView(source: Source.sampleSources[0])
            .environment(AppModel())
    }
}

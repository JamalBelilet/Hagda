import SwiftUI

/// A detailed view for a specific source, showing metadata and content
struct SourceView: View {
    // MARK: - Properties
    
    let source: Source
    @Environment(AppModel.self) private var appModel
    @State private var isFollowing: Bool = false
    @State private var contentItems: [ContentItem] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Header section
            Section {
                sourceHeader
            }
            
            // Content items section
            Section {
                if isLoading {
                    ProgressView("Loading content...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .padding(.bottom, 4)
                        
                        Text("Error loading content")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry", action: loadContent)
                            .buttonStyle(.bordered)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else if contentItems.isEmpty {
                    EmptyStateView(
                        icon: source.type.icon,
                        title: "No Content Available",
                        message: "There's currently no content available from this source."
                    )
                    .padding()
                } else {
                    ForEach(contentItems) { item in
                        NavigationLink(destination: ContentDetailView(item: item)) {
                            ContentItemRow(item: item)
                        }
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
        .background(Color(.gray).opacity(0.1))
        .onAppear {
            isFollowing = appModel.isSourceSelected(source)
            loadContent()
        }
        .refreshable {
            await refreshContent()
        }
        .accessibilityIdentifier("SourceView-\(source.name)")
    }
    
    /// Load content from the source
    private func loadContent() {
        // If we're already loading, don't start another request
        guard !isLoading else { return }
        
        // Set loading state
        isLoading = true
        errorMessage = nil
        
        // Clear the content items array if we're not refreshing
        contentItems = []
        
        // Use Task to handle async loading
        Task {
            do {
                // Load content asynchronously
                contentItems = try await appModel.getContentForSource(source)
                errorMessage = nil
            } catch {
                // Handle error
                errorMessage = error.localizedDescription
            }
            
            // Update UI on main thread
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    /// Refresh content asynchronously
    private func refreshContent() async {
        // Set loading state
        isLoading = true
        errorMessage = nil
        
        do {
            // Load content asynchronously
            contentItems = try await appModel.getContentForSource(source)
            errorMessage = nil
        } catch {
            // Handle error
            errorMessage = error.localizedDescription
        }
        
        // Update UI on main thread
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - UI Components
    
    /// Header with source metadata and follow button
    private var sourceHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and title
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
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

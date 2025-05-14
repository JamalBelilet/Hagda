import SwiftUI

/// A combined view that merges the library and source adding functionality
struct CombinedLibraryView: View {
    @Environment(AppModel.self) private var appModel
    
    @State private var searchQuery = ""
    @State private var searchResults: [Source] = []
    @State private var isSearching = false
    @State private var showingResults = false
    @State private var selectedType: SourceType = .article
    
    var body: some View {
        // No NavigationStack needed since we're already in one
        ZStack {
            // Apply background to entire screen
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Content - either library or search results
            if showingResults {
                searchResultsList
            } else {
                libraryList
            }
        }
        .navigationTitle("Add sources")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: searchPlaceholder(for: selectedType))
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search, performSearch)
    }
    
    // MARK: - Views
    
    // Type selector component
    private var typeSelector: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(SourceType.allCases) { type in
                    Button {
                        if selectedType != type {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedType = type
                                searchQuery = ""
                                showingResults = false
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selectedType != type ? Color(.secondaryLabel) : Color(.systemBackground))
                            if selectedType == type {
                                Text(typeTitle(for: type))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .foregroundColor(Color(.systemBackground))
                                    .fixedSize(horizontal: true, vertical: false)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical,14)
                        .frame(maxWidth: selectedType != type ? .infinity : nil)
                        .background(
                            Capsule()
                                .fill(selectedType != type ? Color(.secondarySystemFill) : Color(.label))
                        )
                        .transition(.scale)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedType)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity) // Make sure the entire view takes full width
        .background(Color(.systemGroupedBackground)) // Match the list's background color
    }
    
    private var libraryList: some View {
        List {
            typeSelector
                .listRowInsets(EdgeInsets()) // Remove all insets
                .listRowBackground(Color(.systemGroupedBackground)) // Match system background
                .listSectionSeparator(.hidden, edges: .top) // Hide separator at the top
                .frame(width: UIScreen.main.bounds.width) // Explicitly set to screen width
                .alignmentGuide(.leading) { _ in -20 } // Shift left to align with screen edge
            
            // Get all sources from filtered categories
            let allSources = filteredCategories.values.flatMap { $0 }
            
            if !allSources.isEmpty {
                Section {
                    ForEach(allSources.sorted(by: { $0.name < $1.name })) { source in
                        NavigationLink {
                            SourceView(source: source)
                        } label: {
                            sourceRowView(source: source)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(appModel.isSourceSelected(source) ? "Remove" : "Add") {
                                appModel.toggleSourceSelection(source)
                            }
                            .tint(appModel.isSourceSelected(source) ? .red : .green)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped) // Changed to insetGrouped style
        .scrollContentBackground(.visible)
        .background(Color(.systemGroupedBackground))
        // Make sure scroll behavior is properly tracked with navigation title
        .scrollIndicators(.visible) // Show scroll indicators for better UX
        .overlay {
            if filteredCategories.isEmpty {
                ContentUnavailableView {
                    Label("No Sources", systemImage: selectedType.icon)
                        .font(.title2)
                } description: {
                    Text("Search to find \(typeTitle(for: selectedType).lowercased()) sources.")
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
        }
    }
    
    private var searchResultsList: some View {
        List {
            // Add type selector to search results view
            typeSelector
                .listRowInsets(EdgeInsets()) // Remove all insets
                .listRowBackground(Color(.systemGroupedBackground)) // Match system background
                .listSectionSeparator(.hidden, edges: .top) // Hide separator at the top
                .frame(width: UIScreen.main.bounds.width) // Explicitly set to screen width
                .alignmentGuide(.leading) { _ in -20 } // Shift left to align with screen edge
            
            if isSearching {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                        Spacer()
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                    .padding()
                }
            } else {
                Section {
                    if searchResults.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different search term.")
                        )
                        .listRowBackground(Color(.secondarySystemBackground))
                    } else {
                        ForEach(searchResults) { source in
                            sourceResultRow(source)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped) // Changed to insetGrouped style
        .scrollContentBackground(.visible)
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.visible) // Show scroll indicators for better UX
        .safeAreaInset(edge: .bottom) {
            if !isSearching && showingResults && !searchResults.isEmpty {
                Text("Tap a source to add it to your feed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
            }
        }
    }
    
    // Section header for categories
    private func sectionHeader(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
    
    // Regular source row for the library
    private func sourceRowView(source: Source) -> some View {
        HStack(spacing: 14) {
            // Source icon
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: source.type.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)
                
                if let handle = source.handle {
                    Text(handle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(typeTitle(for: source.type))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(source.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Show a badge if this source is selected
                if appModel.isSourceSelected(source) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        
                        Text("Following")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
    
    // Source row in search results
    private func sourceResultRow(_ source: Source) -> some View {
        Button {
            appModel.addSource(source)
            withAnimation {
                showingResults = false
                searchQuery = ""
            }
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: source.type.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(Color.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.name)
                        .font(.headline)
                    
                    if let handle = source.handle {
                        Text(handle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(typeTitle(for: source.type))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(source.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 22))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper functions
    
    // Filter categories based on the selected type
    private var filteredCategories: [String: [Source]] {
        var result: [String: [Source]] = [:]
        
        switch selectedType {
        case .article:
            if let sources = appModel.categories["Top Tech Articles"] {
                result["Top Tech Articles"] = sources
            }
        case .reddit:
            if let sources = appModel.categories["Popular Subreddits"] {
                result["Popular Subreddits"] = sources
            }
        case .podcast:
            if let sources = appModel.categories["Tech Podcasts"] {
                result["Tech Podcasts"] = sources
            }
        case .bluesky, .mastodon:
            if let sources = appModel.categories["Tech Influencers"] {
                // Filter by specific social media type
                result["Tech Influencers"] = sources.filter { $0.type == selectedType }
            }
        }
        
        return result
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        showingResults = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.searchResults = appModel.searchSources(query: searchQuery, type: selectedType)
            self.isSearching = false
        }
    }
    
    private func getCategoryDescription(_ category: String) -> String {
        switch category {
        case "Top Tech Articles":
            return "Read the latest articles from the best tech sources."
        case "Popular Subreddits":
            return "Discover trending posts from the most popular subreddits."
        case "Tech Podcasts":
            return "Listen to expert discussions on tech and business."
        case "Tech Influencers":
            return "Stay updated with posts from top tech influencers on social media."
        default:
            return ""
        }
    }
    
    // Helper functions for UI text
    private func typeTitle(for type: SourceType) -> String {
        switch type {
        case .article: return "News"
        case .reddit: return "Reddit"
        case .bluesky: return "Bluesky"
        case .mastodon: return "Mastodon"
        case .podcast: return "Podcast"
        }
    }
    
    private func searchPlaceholder(for type: SourceType) -> String {
        switch type {
        case .article: return "Search for news source..."
        case .reddit: return "Enter subreddit name..."
        case .bluesky: return "Enter Bluesky handle..."
        case .mastodon: return "Enter Mastodon handle..."
        case .podcast: return "Search for podcast..."
        }
    }
}

#Preview {
    NavigationStack {
        CombinedLibraryView()
            .environment(AppModel())
    }
}

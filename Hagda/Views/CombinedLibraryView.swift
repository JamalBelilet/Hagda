import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#endif

/// A combined view that merges the library and source adding functionality
struct CombinedLibraryView: View {
    // MARK: - Properties
    
    @Environment(AppModel.self) private var appModel
    
    @State private var searchQuery = ""
    @State private var searchResults: [Source] = []
    @State private var isSearching = false
    @State private var showingResults = false
    @State private var selectedType: SourceType = .article
    @State private var errorMessage: String? = nil
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Apply background to entire screen
            #if os(iOS) || os(visionOS)
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            #else
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            #endif
            
            // Content - either library or search results
            if showingResults {
                searchResultsList
            } else {
                libraryList
            }
        }
        .navigationTitle("Discover Sources")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: selectedType.searchPlaceholder)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search, performSearch)
        #else
        .searchable(text: $searchQuery,
                    prompt: selectedType.searchPlaceholder)
        .autocorrectionDisabled()
        .onSubmit(of: .search, performSearch)
        #endif
        .accessibilityIdentifier("CombinedLibraryView")
    }
    
    // MARK: - UI Components
    
    /// List of sources for the selected type
    private var libraryList: some View {
        List {
            TypeSelectorView(selectedType: $selectedType)
                .asListRow()
            
            // Get all sources from filtered categories
            let allSources = filteredCategories.values.flatMap { $0 }
            
            if !allSources.isEmpty {
                Section {
                    ForEach(allSources.sorted(by: { $0.name < $1.name })) { source in
                        NavigationLink {
                            SourceView(source: source)
                        } label: {
                            SourceRowView(source: source)
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
        .listStyle(.inset)
        .scrollContentBackground(.visible)
        #if os(iOS) || os(visionOS)
        .background(Color(.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        #if os(iOS) || os(visionOS)
        .scrollIndicators(.visible)
        #endif
        .overlay {
            if filteredCategories.isEmpty {
                EmptyStateView(
                    icon: selectedType.icon,
                    title: "Sources Not Found",
                    message: "Search to discover \(selectedType.displayName.lowercased()) sources."
                )
            }
        }
    }
    
    /// List of search results
    private var searchResultsList: some View {
        List {
            // Add type selector to search results view
            TypeSelectorView(selectedType: $selectedType)
                .asListRow()
                .onChange(of: selectedType) { _, _ in
                    if !searchQuery.isEmpty {
                        performSearch()
                    }
                }
            
            if isSearching {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                        Spacer()
                    }
                    .padding()
                }
            } else {
                Section {
                    if let error = errorMessage {
                        EmptyStateView(
                            icon: "exclamationmark.triangle",
                            title: "Search Error",
                            message: error
                        )
                        .frame(height: 200)
                        #if os(iOS) || os(visionOS)
                        .listRowBackground(Color(.secondarySystemBackground))
                        #else
                        .listRowBackground(Color.gray.opacity(0.2))
                        #endif
                    } else if searchResults.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Matches Found",
                            message: {
                                switch selectedType {
                                case .podcast:
                                    return "Try different podcast keywords or check your internet connection."
                                case .reddit:
                                    return "Try different subreddit names or check your internet connection."
                                case .mastodon:
                                    return "Try different Mastodon account names or check your internet connection."
                                case .bluesky:
                                    return "Try different Bluesky account names or check your internet connection."
                                default:
                                    return "Try different keywords, a website URL (e.g., nytimes.com), or an RSS feed URL."
                                }
                            }()
                        )
                        .frame(height: 200)
                        #if os(iOS) || os(visionOS)
                        .listRowBackground(Color(.secondarySystemBackground))
                        #else
                        .listRowBackground(Color.gray.opacity(0.2))
                        #endif
                    } else {
                        ForEach(searchResults) { source in
                            sourceResultRow(source)
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.visible)
        #if os(iOS) || os(visionOS)
        .background(Color(.systemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
        #if os(iOS) || os(visionOS)
        .scrollIndicators(.visible)
        #endif
        .safeAreaInset(edge: .bottom) {
            if !isSearching && showingResults && !searchResults.isEmpty {
                Text("Tap a source to add it to your personalized feed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
            }
        }
    }
    
    /// Row for search results with add button
    private func sourceResultRow(_ source: Source) -> some View {
        SourceResultRowView(
            source: source,
            isAdded: appModel.isSourceSelected(source)
        ) { source in
            appModel.addSource(source)
            // Stay on search results instead of closing
        }
    }
    
    // MARK: - Helper Methods
    
    /// Filter categories based on the selected type
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
    
    /// Perform search with the current query and type
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        showingResults = true
        errorMessage = nil
        
        // Use async API for podcast, reddit, mastodon, bluesky, and news searches
        if selectedType == .podcast || selectedType == .reddit || selectedType == .mastodon || selectedType == .bluesky || selectedType == .article {
            Task {
                do {
                    var results: [Source] = []
                    
                    if selectedType == .podcast {
                        // For podcasts, use the iTunes Search API
                        results = try await appModel.searchPodcasts(query: searchQuery)
                    } else if selectedType == .reddit {
                        // For reddit, use the Reddit API
                        results = try await appModel.searchSubreddits(query: searchQuery)
                    } else if selectedType == .mastodon {
                        // For mastodon, use the Mastodon API
                        results = try await appModel.searchMastodonAccounts(query: searchQuery)
                    } else if selectedType == .bluesky {
                        // For bluesky, use the Bluesky API
                        results = try await appModel.searchBlueSkyAccounts(query: searchQuery)
                    } else if selectedType == .article {
                        // For news sources, use the News API service
                        results = try await appModel.searchNewsSources(query: searchQuery)
                    }
                    
                    // Update UI on the main thread
                    await MainActor.run {
                        self.searchResults = results
                        self.isSearching = false
                    }
                } catch {
                    // Handle errors
                    await MainActor.run {
                        self.searchResults = []
                        self.errorMessage = "Failed to search \(selectedType.displayName.lowercased()): \(error.localizedDescription)"
                        self.isSearching = false
                    }
                }
            }
        } else {
            // For other source types, use the synchronous mock implementation
            // Simulate network delay for consistency with podcast search
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.searchResults = appModel.searchSources(query: searchQuery, type: selectedType)
                self.isSearching = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CombinedLibraryView()
            .environment(AppModel())
    }
}

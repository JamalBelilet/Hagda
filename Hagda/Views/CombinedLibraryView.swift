import SwiftUI

/// A combined view that merges the library and source adding functionality
struct CombinedLibraryView: View {
    // MARK: - Properties
    
    @Environment(AppModel.self) private var appModel
    
    @State private var searchQuery = ""
    @State private var searchResults: [Source] = []
    @State private var isSearching = false
    @State private var showingResults = false
    @State private var selectedType: SourceType = .article
    
    // MARK: - Body
    
    var body: some View {
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
                    prompt: selectedType.searchPlaceholder)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search, performSearch)
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
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.visible)
        .overlay {
            if filteredCategories.isEmpty {
                EmptyStateView(
                    icon: selectedType.icon,
                    title: "No Sources",
                    message: "Search to find \(selectedType.displayName.lowercased()) sources."
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
                    .listRowBackground(Color(.secondarySystemBackground))
                    .padding()
                }
            } else {
                Section {
                    if searchResults.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "Try a different search term."
                        )
                        .frame(height: 200)
                        .listRowBackground(Color(.secondarySystemBackground))
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
        .background(Color(.systemGroupedBackground))
        .scrollIndicators(.visible)
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
    
    /// Row for search results with add button
    private func sourceResultRow(_ source: Source) -> some View {
        SourceResultRowView(source: source) { source in
            appModel.addSource(source)
            withAnimation {
                showingResults = false
                searchQuery = ""
            }
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
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.searchResults = appModel.searchSources(query: searchQuery, type: selectedType)
            self.isSearching = false
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

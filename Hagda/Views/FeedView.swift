import SwiftUI

// Local components

/// The main feed view displaying sources grouped by type
struct FeedView: View {
    // MARK: - Properties
    
    @State private var searchText = ""
    @State private var showContinueAll = false
    @State private var showTrendingAll = false
    @State private var showContentDetail = false
    @State private var selectedContentItem: ContentItem?
    @State private var showSettings = false
    @Environment(AppModel.self) private var appModel
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if appModel.feedSources.isEmpty {
                EmptyStateView()
                    .accessibilityIdentifier("EmptyStateView")
                    .background(Color(.gray).opacity(0.1))
                    .onAppear {
                        // Debug information
                        print("DEBUG: Selected sources count: \(appModel.selectedSources.count)")
                        print("DEBUG: All sources count: \(appModel.sources.count)")
                        for source in appModel.sources {
                            print("DEBUG: Source \(source.name) (ID: \(source.id)) - Selected: \(appModel.selectedSources.contains(source.id))")
                        }
                    }
            } else {
                sourcesList
            }
        }
        .navigationTitle("Hagda")
        .toolbar {
            #if os(iOS) || os(visionOS)
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .accessibilityIdentifier("SettingsButton")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: "library") {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .accessibilityIdentifier("SourcesButton")
                }
                .accessibilityIdentifier("LibraryButton")
            }
            
            // Debug/test button only in development builds
            #if DEBUG
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: "test-onboarding") {
                    Image(systemName: "ladybug")
                        .font(.system(size: 18))
                }
                .accessibilityIdentifier("TestButton")
            }
            #endif
            #else
            ToolbarItem {
                NavigationLink(value: "library") {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .accessibilityIdentifier("SourcesButton")
                }
                .accessibilityIdentifier("LibraryButton")
            }
            
            // Debug/test button only in development builds
            #if DEBUG
            ToolbarItem {
                NavigationLink(value: "test-onboarding") {
                    Image(systemName: "ladybug")
                        .font(.system(size: 18))
                }
                .accessibilityIdentifier("TestButton")
            }
            #endif
            #endif
        }
        .searchable(text: $searchText, prompt: "Search")
        .navigationDestination(for: String.self) { value in
            if value == "library" {
                CombinedLibraryView()
            } else if value == "test-onboarding" {
                TestOnboardingView()
            }
        }
        .navigationDestination(for: Source.self) { source in
            SourceView(source: source)
        }
        // Add these navigation destinations at the root level to avoid warnings
        .navigationDestination(isPresented: $showContinueAll) {
            ContinueReadingView(
                selectedContentItem: $selectedContentItem,
                showContentDetail: $showContentDetail
            )
        }
        .navigationDestination(isPresented: $showTrendingAll) {
            TrendingContentView()
        }
        .navigationDestination(isPresented: $showContentDetail) {
            if let item = selectedContentItem {
                ContentDetailView(item: item)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    // MARK: - UI Components
    
    /// List of sources grouped by type
    private var sourcesList: some View {
        ZStack {
            List {
                // Today's Brief Section
                Section {
                    DailyBriefView(generator: appModel.dailyBriefGenerator)
                        .padding(.vertical, 8)
                } header: {
                    SectionHeaderView(
                        title: "Today's Brief",
                        description: "Your personalized overview for today",
                        icon: "newspaper"
                    )
                }
                .headerProminence(.increased)
                
                // Continue Reading/Listening Section
                Section {
                    ContinueItemsView(
                        selectedContentItem: $selectedContentItem, 
                        showContentDetail: $showContentDetail,
                        showAllItems: $showContinueAll
                    )
                    
                    // View All button at bottom of section - it's the last item so no bottom separator needed
                    ViewAllButton(title: "Continue", action: { showContinueAll = true })
                } header: {
                    SectionHeaderView(
                        title: "Continue",
                        description: "Resume where you left off",
                        icon: "bookmark"
                    )
                }
                .headerProminence(.increased)
                
                // Top Content Section
                Section {
                    TopContentView()
                    
                    // View All button at bottom of section - it's the last item so no bottom separator needed
                    ViewAllButton(title: "Trending", action: { showTrendingAll = true })

                } header: {
                    SectionHeaderView(
                        title: "Trending Now",
                        description: "Popular content from your sources",
                        icon: "star"
                    )
                }
                .headerProminence(.increased)
                
                // Group sources by type
                let groupedSources = Dictionary(grouping: appModel.feedSources) { $0.type }
                
                // Articles section
                createSourceSection(
                    for: .article,
                    sources: groupedSources[.article, default: []]
                )
                
                // Reddit section
                createSourceSection(
                    for: .reddit,
                    sources: groupedSources[.reddit, default: []]
                )
                
                // Social media section (Bluesky and Mastodon)
                let blueskySource = groupedSources[.bluesky, default: []]
                let mastodonSource = groupedSources[.mastodon, default: []]
                let socialSources = blueskySource + mastodonSource
                
                if !socialSources.isEmpty {
                    Section {
                        ForEach(socialSources) { source in
                            sourceNavigationLink(for: source)
                        }
                    } header: {
                        SectionHeaderView(
                            title: "Social Media", 
                            description: "Updates from people you follow",
                            icon: "person.2"
                        )
                    }
                    .headerProminence(.increased)
                }
                
                // Podcasts section
                createSourceSection(
                    for: .podcast,
                    sources: groupedSources[.podcast, default: []]
                )
            }
            .listStyle(.inset)
            .scrollContentBackground(.visible)
            .background(Color(.gray).opacity(0.1))
            .refreshable {
                await refreshFeed()
            }
            .accessibilityIdentifier("FeedList")
        }
        // Navigation destinations moved to the root level of the view
    }
    
    // MARK: - Helper Methods
    
    /// Refreshes the feed content - simulates a network request
    private func refreshFeed() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // In a real app, this would reload content from a server
        // For now, just update any visible state if needed
        
        // Post a notification that other components can observe to refresh their content
        NotificationCenter.default.post(name: .feedRefreshed, object: nil)
    }
    
    /// Creates a section for a specific source type
    private func createSourceSection(for type: SourceType, sources: [Source]) -> some View {
        Group {
            if !sources.isEmpty {
                Section {
                    ForEach(sources) { source in
                        sourceNavigationLink(for: source)
                    }
                } header: {
                    SectionHeaderView(
                        title: type.sectionTitle,
                        description: type.sectionDescription,
                        icon: type.icon
                    )
                }
                .headerProminence(.increased)
            }
        }
    }
    
    /// Creates a navigation link for a source
    private func sourceNavigationLink(for source: Source) -> some View {
        NavigationLink(value: source) {
            SourceRowView(source: source)
                .accessibilityIdentifier("FeedSource-\(source.name)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeedView()
            .environment(AppModel())
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// Posted when the feed is refreshed
    static let feedRefreshed = Notification.Name("feedRefreshed")
}

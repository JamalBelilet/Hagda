import SwiftUI

/// A view that displays all content items the user was previously engaging with
struct ContinueReadingView: View {
    @Environment(AppModel.self) private var appModel
    @State private var continueItems: [ContentItem] = []
    @State private var isRefreshing = false
    
    // Connect to the parent view's navigation state
    @Binding var selectedContentItem: ContentItem?
    @Binding var showContentDetail: Bool
    
    // Initialize with default bindings for preview support
    init(
        selectedContentItem: Binding<ContentItem?> = .constant(nil),
        showContentDetail: Binding<Bool> = .constant(false)
    ) {
        self._selectedContentItem = selectedContentItem
        self._showContentDetail = showContentDetail
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    if continueItems.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(continueItems) { item in
                            VStack(spacing: 0) {
                                // Main row with content and progress
                                Button {
                                    selectedContentItem = item
                                    showContentDetail = true
                                } label: {
                                    continueItemRow(for: item)
                                        .padding(.bottom, 12)
                                }
                                .buttonStyle(.plain)
                                
                                // Preview of remaining content - separate button with same action
                                Button {
                                    selectedContentItem = item
                                    showContentDetail = true
                                } label: {
                                    RemainingContentPreview(item: item)
                                }
                                .buttonStyle(.plain)
                                
                                // Add spacing after the entire item
                                if item != continueItems.last {
                                    Divider()
                                        .padding(.vertical, 10)
                                }
                                
                                // Add bottom padding for the entire section
                                Spacer()
                                    .frame(height: 16)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        // Navigation destination is now handled by the parent view
        .navigationTitle("Continue Reading")
        .refreshable {
            await refreshContinueItems()
        }
        .onAppear {
            // Generate mocked continue items
            loadContent()
            
            // Set up notification observer for feed refreshes
            setupNotificationObserver()
        }
    }
    
    // Setup notification observer for feed refreshes
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .feedRefreshed,
            object: nil,
            queue: .main
        ) { _ in
            // When the feed is refreshed, update our content
            loadContent()
        }
    }
    
    // Load content items
    private func loadContent() {
        continueItems = loadRealContinueItems()
    }
    
    // Refresh continue items - simulates a network request with async
    private func refreshContinueItems() async {
        // Small delay for UI feedback
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Load real items
        continueItems = loadRealContinueItems()
    }
    
    // Load real continue items from progress trackers
    private func loadRealContinueItems() -> [ContentItem] {
        var allItems: [ContentItem] = []
        
        // Get podcast progress items
        let podcastProgress = PodcastProgressTracker.shared.getAllInProgressEpisodes()
        let podcastItems = podcastProgress.map { entry in
            PodcastProgressTracker.shared.createContentItem(from: entry)
        }
        allItems.append(contentsOf: podcastItems)
        
        // Get all other in-progress items from unified tracker
        let progressItems = UnifiedProgressTracker.shared.getAllInProgressItems()
        let otherItems = progressItems.map { progress in
            UnifiedProgressTracker.shared.createContentItem(from: progress)
        }
        allItems.append(contentsOf: otherItems)
        
        // Sort by last accessed date (most recent first) and limit to 15 items
        let sortedItems = allItems.sorted { item1, item2 in
            // Use date for sorting
            item1.date > item2.date
        }
        
        return Array(sortedItems.prefix(15))
    }
    
    // Row for a continue item with progress indicator
    private func continueItemRow(for item: ContentItem) -> some View {
        HStack(spacing: 14) {
            // Type icon with progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: progressValue(for: item))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: item.typeIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(progressText(for: item))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(item.relativeTimeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron indicator for item row
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.4))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
    
    // Empty state when no continue items exist
    private var emptyStateView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "bookmark.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                
                Text("Continue Reading")
                    .font(.headline)
                
                Text("Content you've started reading or listening to will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
            
            Spacer()
        }
    }
    
    
    // Generate progress value for visual indicator
    private func progressValue(for item: ContentItem) -> CGFloat {
        return CGFloat(item.progressPercentage)
    }
    
    // Generate progress text based on content type
    private func progressText(for item: ContentItem) -> String {
        switch item.type {
        case .article:
            return "\(Int(item.progressPercentage * 100))% completed"
        case .podcast:
            let totalSeconds = 45 * 60 // 45 minutes in seconds
            let remainingSeconds = Int(Double(totalSeconds) * (1 - item.progressPercentage))
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return "\(minutes):\(String(format: "%02d", seconds)) remaining"
        default:
            return "\(Int(item.progressPercentage * 100))% completed"
        }
    }
}

#Preview {
    NavigationStack {
        ContinueReadingView()
            .environment(AppModel())
    }
}
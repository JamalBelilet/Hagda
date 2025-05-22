import SwiftUI

/// Second screen of the onboarding flow for selecting content sources
struct SourceSelectionView: View {
    // MARK: - Properties
    
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var searchDebounceTimer: Timer?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            List {
            // Use TypeSelector in the same way as CombinedLibraryView
            TypeSelectorView(selectedType: $coordinator.selectedSourceType)
                .asListRow()
                .accessibilityIdentifier("sourceTypeSelector")
                
            // Description text in its own section
            Section {
                Text("Select at least 3 sources to personalize your feed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("sourceSelectionDescription")
            }
            
            // Content area - either search results, error, or recommended sources
            if coordinator.isSearching {
                // Loading indicator
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                            .padding()
                        Spacer()
                    }
                    .accessibilityIdentifier("searchingIndicator")
                }
            } else if !coordinator.searchResults.isEmpty {
                // Search results
                Section(header: Text("Search Results")) {
                    ForEach(coordinator.searchResults) { source in
                        SourceResultRow(
                            source: source,
                            isSelected: coordinator.isSourceSelected(source),
                            onSelect: {
                                coordinator.toggleSource(source)
                            }
                        )
                    }
                }
                .accessibilityIdentifier("searchResultsList")
            } else if let error = coordinator.errorMessage {
                // Error message
                Section {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                            .padding()
                        
                        Text("Search Error")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .accessibilityIdentifier("searchErrorView")
                }
            } else {
                // Recommended sources in a list section
                Section(header: Text("Recommended Sources")) {
                    ForEach(filteredRecommendedSources) { source in
                        SourceResultRow(
                            source: source,
                            isSelected: coordinator.isSourceSelected(source),
                            onSelect: {
                                coordinator.toggleSource(source)
                            }
                        )
                    }
                }
                .accessibilityIdentifier("recommendedSourcesList")
            }
            
            // Empty spacer at the bottom of the list for padding
            Section {
                Color.clear.frame(height: 80)
            }
            .listRowBackground(Color.clear)
        }
        
        .listStyle(.inset)
        .scrollContentBackground(.visible)
        #if os(iOS) || os(visionOS)
        .searchable(text: $coordinator.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: coordinator.selectedSourceType.searchPlaceholder)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search, coordinator.searchSources)
        #else
        .searchable(text: $coordinator.searchText,
                    prompt: coordinator.selectedSourceType.searchPlaceholder)
        .autocorrectionDisabled()
        .onSubmit(of: .search, coordinator.searchSources)
        #endif
        .onChange(of: coordinator.searchText) { _, newValue in
            // Cancel any existing timer
            searchDebounceTimer?.invalidate()
            
            // Clear results if search text is empty
            if newValue.isEmpty {
                coordinator.searchResults = []
                coordinator.errorMessage = nil
            } else {
                // Set up a new timer to search after a short delay
                searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    coordinator.searchSources()
                }
            }
        }
        .onChange(of: coordinator.selectedSourceType) { _, _ in
            // Store the current search text before clearing
            let currentSearchText = coordinator.searchText
            
            // Clear results and error when type changes
            coordinator.searchResults = []
            coordinator.errorMessage = nil
            
            // If there was a search query, perform the search again for the new type
            if !currentSearchText.isEmpty {
                coordinator.searchSources()
            }
        }
        .accessibilityIdentifier("sourceSelectionScreen")
            
            // Sticky navigation buttons at the bottom
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        coordinator.goTo(step: .welcome)
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.gray.opacity(0.8))
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("backButton")
                    
                    Spacer()
                    
                    Button(action: {
                        coordinator.advance()
                    }) {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                    .opacity(coordinator.selectedSources.count < 1 ? 0.5 : 1.0)
                    .disabled(coordinator.selectedSources.count < 1)
                    .accessibilityLabel("Continue")
                    .accessibilityIdentifier("continueButton")
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.thinMaterial)
                .cornerRadius(16)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Filter recommended sources based on selected type
    private var filteredRecommendedSources: [Source] {
        return AppModel.shared.sources.filter { $0.type == coordinator.selectedSourceType }
    }
}

/// Row for displaying a source in search results
struct SourceResultRow: View {
    // MARK: - Properties
    
    let source: Source
    let isSelected: Bool
    let onSelect: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Source icon and name
            Label {
                VStack(alignment: .leading) {
                    Text(source.name)
                        .font(.headline)
                    
                    if let handle = source.handle {
                        Text(handle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } icon: {
                Image(systemName: source.type.icon)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Add/remove button
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(isSelected ? .primary : .primary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(source.name) \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Tap to \(isSelected ? "remove from" : "add to") selected sources")
    }
}

import SwiftUI

/// Second screen of the onboarding flow for selecting content sources
struct SourceSelectionView: View {
    // MARK: - Properties
    
    @ObservedObject var coordinator: OnboardingCoordinator
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            // Title is now in the navigation bar
            
            Text("Select at least 3 sources to personalize your feed")
                .padding(.top, 20)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityIdentifier("sourceSelectionDescription")
            
            // Source type selector
            TypeSelectorView(selectedType: $coordinator.selectedSourceType)
                .padding(.horizontal)
                .padding(.top)
                .accessibilityIdentifier("sourceTypeSelector")
            
            // Using the native searchable modifier instead of custom search field
            Spacer().frame(height: 16)
            
            if coordinator.isSearching {
                // Loading indicator
                ProgressView()
                    .controlSize(.large)
                    .padding()
                    .accessibilityIdentifier("searchingIndicator")
            } else if !coordinator.searchResults.isEmpty {
                // Search results
                List {
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
                #if os(iOS) || os(visionOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
                .accessibilityIdentifier("searchResultsList")
            } else if let error = coordinator.errorMessage {
                // Error message
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
                .padding()
                .accessibilityIdentifier("searchErrorView")
            } else {
                // Recommended sources
                recommendedSourcesList
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                Button("Back") {
                    coordinator.goTo(step: .welcome)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
                .tint(.gray.opacity(0.8))
                .accessibilityIdentifier("backButton")
                
                Spacer()
                
                Button("Continue") {
                    coordinator.advance()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
                .disabled(coordinator.selectedSources.count < 1) // Typically would require more, reduced for demo
                .accessibilityIdentifier("continueButton")
            }
            .padding()
            .padding(.bottom, 40) // Add bottom padding to ensure buttons are above page indicator
        }
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
        .onChange(of: coordinator.selectedSourceType) { _, _ in
            // Update search placeholder when type changes
            coordinator.searchText = ""
        }
        .accessibilityIdentifier("sourceSelectionScreen")
    }
    
    // MARK: - Recommended Sources List
    
    /// List of recommended sources based on selected type
    private var recommendedSourcesList: some View {
        List {
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
        }
        #if os(iOS) || os(visionOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .accessibilityIdentifier("recommendedSourcesList")
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
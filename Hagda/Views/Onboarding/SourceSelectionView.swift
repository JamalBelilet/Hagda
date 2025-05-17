import SwiftUI

/// Second screen of the onboarding flow for selecting content sources
struct SourceSelectionView: View {
    // MARK: - Properties
    
    @ObservedObject var coordinator: OnboardingCoordinator
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Text("Choose Your Content Sources")
                .font(.title2.bold())
                .padding(.top)
                .accessibilityIdentifier("sourceSelectionTitle")
            
            Text("Select at least 3 sources to personalize your feed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("sourceSelectionDescription")
            
            // Source type selector
            TypeSelectorView(selectedType: $coordinator.selectedSourceType)
                .padding(.horizontal)
                .padding(.top)
                .accessibilityIdentifier("sourceTypeSelector")
            
            // Search bar
            HStack {
                TextField("Search \(coordinator.selectedSourceType.displayName.lowercased()) sources...", text: $coordinator.searchText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        coordinator.searchSources()
                    }
                    .accessibilityIdentifier("sourceSearchField")
                
                Button(action: coordinator.searchSources) {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityIdentifier("searchButton")
            }
            .padding(.horizontal)
            
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
                .listStyle(.insetGrouped)
                .accessibilityIdentifier("searchResultsList")
            } else if let error = coordinator.errorMessage {
                // Error message
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                        .padding()
                    
                    Text("Search Error")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                .buttonStyle(.bordered)
                .accessibilityIdentifier("backButton")
                
                Spacer()
                
                Button("Continue") {
                    coordinator.advance()
                }
                .buttonStyle(.borderedProminent)
                .disabled(coordinator.selectedSources.count < 1) // Typically would require more, reduced for demo
                .accessibilityIdentifier("continueButton")
            }
            .padding()
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
        .listStyle(.insetGrouped)
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
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: source.type.icon)
                    .foregroundStyle(.accent)
            }
            
            Spacer()
            
            // Add/remove button
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundStyle(isSelected ? .green : .accent)
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
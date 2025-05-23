import SwiftUI

/// A view that displays loading, error, or content state for a feed section
struct LoadingFeedSection<Content: View>: View {
    let title: String
    let loadingState: LoadingState<[ContentItem]>
    let onRetry: () async -> Void
    @ViewBuilder let content: ([ContentItem]) -> Content
    
    var body: some View {
        Section {
            switch loadingState {
            case .idle, .loading:
                loadingSkeleton
                
            case .loaded(let items) where items.isEmpty:
                emptyState
                
            case .loaded(let items):
                content(items)
                
            case .error(let error):
                InlineErrorView(
                    message: error.errorDescription ?? "Failed to load content",
                    systemImage: errorIcon(for: error),
                    retryAction: {
                        Task { await onRetry() }
                    }
                )
            }
        } header: {
            Text(title)
        }
    }
    
    private var loadingSkeleton: some View {
        ForEach(0..<3, id: \.self) { _ in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)
                        .overlay(ShimmerView().mask(RoundedRectangle(cornerRadius: 4)))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 14)
                        .frame(width: 150)
                        .overlay(ShimmerView().mask(RoundedRectangle(cornerRadius: 4)))
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No content available")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Button("Refresh") {
                Task { await onRetry() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private func errorIcon(for error: AppError) -> String {
        switch error {
        case .network(.noConnection):
            return "wifi.slash"
        case .network(.timeout):
            return "clock.badge.exclamationmark"
        case .network(.serverError):
            return "exclamationmark.icloud"
        default:
            return "exclamationmark.circle"
        }
    }
}

/// Enhanced feed section with automatic loading on appear
struct AutoLoadingFeedSection<T: LoadingStateViewModel>: View where T.DataType == [ContentItem] {
    @ObservedObject var viewModel: T
    let title: String
    let sourceType: SourceType
    @State private var hasAppeared = false
    
    var body: some View {
        LoadingFeedSection(
            title: title,
            loadingState: viewModel.loadingState,
            onRetry: viewModel.retry
        ) { items in
            ForEach(items) { item in
                NavigationLink(value: item) {
                    ContentItemRow(item: item)
                }
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                Task { await viewModel.load() }
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }
}

/// Loading state for source rows
struct LoadingSourceRow: View {
    let source: Source
    let isLoading: Bool
    let error: AppError?
    let itemCount: Int
    
    var body: some View {
        HStack {
            // Source icon
            Image(systemName: source.type.icon)
                .font(.title2)
                .foregroundStyle(source.type.color)
                .frame(width: 40, height: 40)
                .background(source.type.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Source info
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)
                
                if isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = error {
                    Text(error.errorDescription ?? "Error loading")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text("\(itemCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron or retry button
            if error != nil {
                Button {
                    // Retry action handled by parent
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.accentColor)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Loading State") {
    List {
        LoadingFeedSection(
            title: "Test Section",
            loadingState: .loading,
            onRetry: {}
        ) { _ in
            EmptyView()
        }
    }
}

#Preview("Error State") {
    List {
        LoadingFeedSection(
            title: "Test Section",
            loadingState: .error(.network(.noConnection)),
            onRetry: {}
        ) { _ in
            EmptyView()
        }
    }
}

#Preview("Empty State") {
    List {
        LoadingFeedSection(
            title: "Test Section",
            loadingState: .loaded([]),
            onRetry: {}
        ) { _ in
            EmptyView()
        }
    }
}
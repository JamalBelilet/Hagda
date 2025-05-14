import SwiftUI

/// Displays a placeholder when no content is available
struct EmptyStateView: View {
    // MARK: - Properties
    
    let icon: String
    let title: String
    let message: String
    
    // MARK: - Initialization
    
    init(
        icon: String = "newspaper",
        title: String = "No items yet",
        message: String = "Your feed is empty. Add sources from the library to start seeing content."
    ) {
        self.icon = icon
        self.title = title
        self.message = message
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("EmptyStateIcon")
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .accessibilityIdentifier("EmptyStateTitle")
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .accessibilityIdentifier("EmptyStateDescription")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView()
}

#Preview("Custom Message") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No Results",
        message: "Try searching with different keywords."
    )
}
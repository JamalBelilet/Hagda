import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("EmptyStateIcon")
            
            Text("No items yet")
                .font(.title2)
                .fontWeight(.medium)
                .accessibilityIdentifier("EmptyStateTitle")
            
            Text("Your feed is empty. Add sources from the library to start seeing content.")
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
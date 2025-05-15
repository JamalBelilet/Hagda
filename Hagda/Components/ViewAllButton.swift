import SwiftUI

/// A button that shows "View All" for section lists
struct ViewAllButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: action) {
                HStack(spacing: 4) {
                    Text("View All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("ViewAll-\(title)")
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .listRowSeparatorTint(.clear, edges: .bottom) // Hide just the bottom separator
    }
}

#Preview {
    ViewAllButton(title: "Continue Reading", action: {})
}
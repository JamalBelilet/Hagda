import SwiftUI

/// A button that shows "View All" for section lists
struct ViewAllButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        ZStack {
            // This view has no background or border
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
        }
        // These modifiers help remove any list separators
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    ViewAllButton(title: "Continue Reading", action: {})
}
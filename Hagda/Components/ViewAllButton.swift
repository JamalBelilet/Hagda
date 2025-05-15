import SwiftUI

/// A button that shows "View All" for section lists
struct ViewAllButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("View All \(title)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.accentColor)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .accessibilityIdentifier("ViewAll-\(title)")
    }
}

#Preview {
    ViewAllButton(title: "Continue Reading", action: {})
}
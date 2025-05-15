import SwiftUI

/// A reusable section header component with icon, title and description
struct SectionHeaderView: View {
    let title: String
    let description: String
    let icon: String
    var destination: (() -> AnyView)? = nil
    var viewAllAction: (() -> Void)? = nil
    
    var body: some View {
        headerContent
    }
    
    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if destination != nil || viewAllAction != nil {
                    Button(action: {
                        if let action = viewAllAction {
                            action()
                        } else if let dest = destination {
                            // This will be handled by a navigation link in the parent view
                        }
                    }) {
                        Text("View All")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("ViewAll-\(title)")
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 6)
        .accessibilityIdentifier("SectionHeader-\(title)")
    }
}

#Preview {
    List {
        Section {
            Text("Content goes here")
            Text("More content here")
        } header: {
            SectionHeaderView(
                title: "Sample Section", 
                description: "This is an example header with description text", 
                icon: "star"
            )
        }
        .headerProminence(.increased)
    }
    .listStyle(.inset)
}
import SwiftUI

/// A reusable row component for displaying a source with optional following status
struct SourceRowView: View {
    let source: Source
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        HStack(spacing: 14) {
            // Source icon
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: source.type.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentColor)
                )
                
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)
                
                if let handle = source.handle {
                    Text(handle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(source.type.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(source.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // We don't need to show the following state in the feed view since
                // anything shown in the feed is already being followed by the user
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .accessibilityIdentifier("SourceRow-\(source.name)")
    }
}

/// A variant of SourceRowView that includes an add button for search results
struct SourceResultRowView: View {
    let source: Source
    let onAdd: (Source) -> Void
    
    var body: some View {
        Button {
            onAdd(source)
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: source.type.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(Color.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.name)
                        .font(.headline)
                    
                    if let handle = source.handle {
                        Text(handle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(source.type.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(source.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 22))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("SourceResult-\(source.name)")
    }
}

#Preview("Source Row") {
    SourceRowView(source: Source.sampleSources[0])
        .environment(AppModel())
        .padding()
}

#Preview("Source Result Row") {
    SourceResultRowView(source: Source.sampleSources[0], onAdd: { _ in })
        .padding()
}
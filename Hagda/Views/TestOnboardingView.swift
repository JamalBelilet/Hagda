import SwiftUI

/// A temporary view to test the onboarding source selection fix
struct TestOnboardingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Onboarding Source Selection Test")
                    .font(.title)
                    .bold()
                
                Text("Selected Sources (\(appModel.selectedSources.count))")
                    .font(.headline)
                
                ForEach(appModel.sources.filter { appModel.selectedSources.contains($0.id) }) { source in
                    HStack {
                        Text(source.name)
                            .font(.body)
                        Text(source.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("ID: \(source.id.uuidString.prefix(8))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                Text("Feed Sources (\(appModel.feedSources.count))")
                    .font(.headline)
                
                ForEach(appModel.feedSources) { source in
                    HStack {
                        Text(source.name)
                            .font(.body)
                        Text(source.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("ID: \(source.id.uuidString.prefix(8))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Divider()
                
                Text("All Sources (\(appModel.sources.count))")
                    .font(.headline)
                
                ForEach(appModel.sources) { source in
                    HStack {
                        Text(source.name)
                            .font(.body)
                        Text(source.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("ID: \(source.id.uuidString.prefix(8))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Source Selection Test")
        .toolbar {
            #if os(iOS) || os(visionOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    appModel.saveOnboardingComplete(false)
                    appModel.selectedSources.removeAll()
                    appModel.saveSelectedSources(Set<UUID>())
                    dismiss()
                }) {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 18))
                }
            }
            #else
            ToolbarItem {
                Button(action: {
                    appModel.saveOnboardingComplete(false)
                    appModel.selectedSources.removeAll()
                    appModel.saveSelectedSources(Set<UUID>())
                    dismiss()
                }) {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 18))
                }
            }
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        TestOnboardingView()
            .environment(AppModel())
    }
}
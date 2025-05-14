import SwiftUI

/// A horizontal selector for source types with animated selection
struct TypeSelectorView: View {
    @Binding var selectedType: SourceType
    private let animation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(SourceType.allCases) { type in
                    Button {
                        if selectedType != type {
                            withAnimation(animation) {
                                selectedType = type
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selectedType != type ? Color(.secondaryLabel) : Color(.systemBackground))
                            
                            if selectedType == type {
                                Text(type.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .foregroundColor(Color(.systemBackground))
                                    .fixedSize(horizontal: true, vertical: false)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .frame(maxWidth: selectedType != type ? .infinity : nil)
                        .background(
                            Capsule()
                                .fill(selectedType != type ? Color(.secondarySystemFill) : Color(.label))
                        )
                        .transition(.scale)
                    }
                    .buttonStyle(.plain)
                    .animation(animation, value: selectedType)
                    .accessibilityIdentifier("TypeSelector-\(type.rawValue)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/// An extension to adapt TypeSelectorView for list row usage
extension TypeSelectorView {
    func asListRow() -> some View {
        self
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.systemGroupedBackground))
            .listSectionSeparator(.hidden, edges: .top)
            #if os(iOS)
            .frame(width: UIScreen.main.bounds.width)
            #endif
            .alignmentGuide(.leading) { _ in -20 }
    }
}

#Preview {
    TypeSelectorView(selectedType: .constant(.article))
        .padding(.vertical)
}
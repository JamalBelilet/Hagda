import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#endif

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
                            if selectedType == type {
                                Text(type.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .transition(.opacity)
                            }
                        }
                        #if os(iOS) || os(visionOS)
                        .foregroundColor(selectedType == type ? Color(.systemBackground) : .gray)
                        #else
                        .foregroundColor(selectedType == type ? Color(NSColor.windowBackgroundColor) : .gray)
                        #endif
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .frame(maxWidth: selectedType != type ? .infinity : nil)
                        .background(
                            Capsule()
                                #if os(iOS) || os(visionOS)
                                .fill(selectedType != type ? Color(.secondarySystemBackground) : Color.primary)
                                #else
                                .fill(selectedType != type ? Color.gray.opacity(0.2) : Color.primary)
                                #endif
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
//        .background(Color(.gray).opacity(0.1))
    }
}

/// An extension to adapt TypeSelectorView for list row usage
extension TypeSelectorView {
    func asListRow() -> some View {
        self
            .listRowInsets(EdgeInsets())
//            .listRowBackground(Color(.gray).opacity(0.1))
            .listSectionSeparator(.hidden)
            #if os(iOS) || os(visionOS)
            .frame(width: UIScreen.main.bounds.width)
            #endif
            .alignmentGuide(.leading) { _ in -20 }
    }
}

#Preview {
    TypeSelectorView(selectedType: .constant(.article))
        .padding(.vertical)
}

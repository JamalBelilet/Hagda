import SwiftUI

/// A reusable loading view with different styles
struct LoadingView: View {
    let message: String?
    let style: LoadingStyle
    
    @State private var isAnimating = false
    
    enum LoadingStyle {
        case large
        case medium
        case inline
        case overlay
    }
    
    init(message: String? = nil, style: LoadingStyle = .medium) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .large:
            largeLoadingView
        case .medium:
            mediumLoadingView
        case .inline:
            inlineLoadingView
        case .overlay:
            overlayLoadingView
        }
    }
    
    // MARK: - Loading Styles
    
    private var largeLoadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            
            if let message = message {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
    }
    
    private var mediumLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private var inlineLoadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(0.8)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var overlayLoadingView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                if let message = message {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(30)
            .background(Color.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

/// Content loading shimmer effect
struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.2)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: isAnimating ? 300 : -300)
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

/// Skeleton loader for content
struct SkeletonLoader: View {
    let rows: Int
    
    init(rows: Int = 3) {
        self.rows = rows
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<rows, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    // Title skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                        .frame(maxWidth: .infinity)
                        .overlay(ShimmerView().mask(RoundedRectangle(cornerRadius: 4)))
                    
                    // Subtitle skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .frame(width: 200)
                        .overlay(ShimmerView().mask(RoundedRectangle(cornerRadius: 4)))
                    
                    // Content skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 14)
                        .frame(maxWidth: .infinity)
                        .overlay(ShimmerView().mask(RoundedRectangle(cornerRadius: 4)))
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }
}

/// Pull to refresh modifier
struct PullToRefresh: ViewModifier {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                isRefreshing = true
                await action()
                isRefreshing = false
            }
    }
}

extension View {
    func pullToRefresh(isRefreshing: Binding<Bool>, action: @escaping () async -> Void) -> some View {
        modifier(PullToRefresh(isRefreshing: isRefreshing, action: action))
    }
}

#Preview("Loading Styles") {
    VStack(spacing: 40) {
        LoadingView(message: "Loading content...", style: .large)
            .frame(height: 200)
            .border(Color.gray.opacity(0.3))
        
        LoadingView(message: "Please wait", style: .medium)
            .border(Color.gray.opacity(0.3))
        
        LoadingView(message: "Updating", style: .inline)
            .border(Color.gray.opacity(0.3))
    }
    .padding()
}

#Preview("Skeleton Loader") {
    SkeletonLoader(rows: 4)
}

#Preview("Overlay Loading") {
    ZStack {
        // Background content
        List(0..<10) { i in
            Text("Item \(i)")
        }
        
        LoadingView(message: "Saving...", style: .overlay)
    }
}
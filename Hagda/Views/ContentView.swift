//
//  ContentView.swift
//  Hagda
//
//  Created by Djamaleddine Belilet on 13/05/2025.
//

import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#endif

/// The main content view that serves as the entry point for the app
struct ContentView: View {
    // MARK: - Properties
    
    @Environment(AppModel.self) private var appModel
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                FeedView()
                    // Add padding to account for mini player
                    .safeAreaInset(edge: .bottom) {
                        // Spacer for mini player height
                        Color.clear.frame(height: 64)
                    }
            }
            .accessibilityIdentifier("MainNavigationStack")
            
            // Mini player overlay
            MiniPlayerView()
        }
        .onAppear {
            // Set an accessibility label for UI testing
            #if os(iOS) || os(visionOS)
            UIAccessibility.post(notification: .announcement, argument: "Hagda App Launched")
            #endif
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppModel())
}

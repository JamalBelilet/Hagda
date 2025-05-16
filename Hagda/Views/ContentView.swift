//
//  ContentView.swift
//  Hagda
//
//  Created by Djamaleddine Belilet on 13/05/2025.
//

import SwiftUI
import UIKit

/// The main content view that serves as the entry point for the app
struct ContentView: View {
    // MARK: - Properties
    
    @Environment(AppModel.self) private var appModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            FeedView()
        }
        .accessibilityIdentifier("MainNavigationStack")
        .onAppear {
            // Set an accessibility label for UI testing
            UIAccessibility.post(notification: .announcement, argument: "Hagda App Launched")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppModel())
}

//
//  HagdaApp.swift
//  Hagda
//
//  Created by Djamaleddine Belilet on 13/05/2025.
//

import SwiftUI

@main
struct HagdaApp: App {
    @State private var appModel = AppModel()
    
    init() {
        // Check for UI testing mode
        if CommandLine.arguments.contains("-UITestingMode") {
            // Reset the app state for UI testing
            appModel = AppModel()
            appModel.selectedSources = []
        }
    }
    
    var body: some Scene {
        WindowGroup {
            FeedView()
                .environment(appModel)
                .accessibilityIdentifier("FeedView")
        }
    }
}

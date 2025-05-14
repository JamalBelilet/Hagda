//
//  HagdaApp.swift
//  Hagda
//
//  Created by Djamaleddine Belilet on 13/05/2025.
//

import SwiftUI

@main
struct HagdaApp: App {
    // MARK: - Properties
    
    /// Main app model that is shared across all views
    @State private var appModel: AppModel
    
    // MARK: - Initialization
    
    init() {
        // Check for UI testing mode
        let isTestingMode = CommandLine.arguments.contains("-UITestingMode")
        _appModel = State(initialValue: AppModel(isTestingMode: isTestingMode))
    }
    
    // MARK: - App Scene
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .accessibilityIdentifier("RootView")
        }
    }
}

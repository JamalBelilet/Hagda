//
//  ContentView.swift
//  Hagda
//
//  Created by Djamaleddine Belilet on 13/05/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var appModel = AppModel()
    
    var body: some View {
        NavigationStack {
            FeedView()
                .environment(appModel)
        }
        .environment(appModel)
    }
}

#Preview {
    ContentView()
}

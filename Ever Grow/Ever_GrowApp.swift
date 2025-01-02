//
//  Ever_GrowApp.swift
//  Ever Grow
//
//  Created by Rens Barnhoorn on 31/12/2024.
//

import SwiftUI
import SwiftData

@main
struct Ever_GrowApp: App {
    let container: ModelContainer
    private let highlightManager: HighlightManager
    
    init() {
        do {
            let schema = Schema([
                Highlight.self,
                NotificationSettings.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Initialize HighlightManager immediately
            highlightManager = HighlightManager(modelContext: container.mainContext)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
        }
    }
}

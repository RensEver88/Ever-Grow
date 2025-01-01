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
    @State private var highlightManager: HighlightManager?
    
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
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
                .onAppear {
                    if highlightManager == nil {
                        highlightManager = HighlightManager(modelContext: container.mainContext)
                    }
                }
        }
    }
}

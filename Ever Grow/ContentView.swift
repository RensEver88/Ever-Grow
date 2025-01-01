//
//  ContentView.swift
//  Ever Grow
//
//  Created by Rens Barnhoorn on 31/12/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Highlight.self, NotificationSettings.self])
}

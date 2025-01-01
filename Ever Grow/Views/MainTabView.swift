import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
                .tag(0)
            
            PastView()
                .tabItem {
                    Label("Past", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
        }
        .onChange(of: selectedTab) {
            if selectedTab == 1 { // Past tab is geselecteerd
                copyTopHighlightsToPast()
            }
        }
    }
    
    private func copyTopHighlightsToPast() {
        // Haal eerst de top 3 highlights op
        let todayDescriptor: FetchDescriptor<Highlight> = FetchDescriptor(
            predicate: #Predicate<Highlight> { highlight in
                highlight.isToday && highlight.order <= 3 && !highlight.text.isEmpty
            },
            sortBy: [SortDescriptor(\Highlight.order)]
        )
        
        // Haal alle highlights van vandaag op die al zijn gekopieerd
        let pastDescriptor: FetchDescriptor<Highlight> = FetchDescriptor(
            predicate: #Predicate<Highlight> { highlight in
                !highlight.isToday
            }
        )
        
        do {
            let topHighlights = try modelContext.fetch(todayDescriptor)
            let pastHighlights = try modelContext.fetch(pastDescriptor)
            
            // Check of er al highlights zijn gekopieerd vandaag
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let alreadyCopiedToday = pastHighlights.contains { highlight in
                calendar.startOfDay(for: highlight.date) == today
            }
            
            guard !alreadyCopiedToday else { return }
            
            // Bepaal de hoogste order voor vandaag
            let todayHighlights = pastHighlights.filter { calendar.startOfDay(for: $0.date) == today }
            let startOrder = (todayHighlights.map { $0.order }.max() ?? 0) + 1
            
            // Kopieer de highlights met behoud van relatieve volgorde
            for (index, highlight) in topHighlights.enumerated() {
                let pastHighlight = Highlight(
                    text: highlight.text,
                    date: Date(),
                    order: startOrder + index,  // Behoud relatieve volgorde
                    isToday: false
                )
                modelContext.insert(pastHighlight)
            }
            try modelContext.save()
        } catch {
            print("Error copying highlights: \(error)")
        }
    }
} 
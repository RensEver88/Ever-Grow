import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Highlight> { highlight in
        highlight.isToday
    }, sort: \Highlight.order) private var highlights: [Highlight]
    
    @Query(filter: #Predicate<Highlight> { highlight in
        !highlight.isToday
    }, sort: \Highlight.order) private var pastHighlights: [Highlight]
    
    private var todaysPastHighlights: [Highlight] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return pastHighlights.filter { highlight in
            calendar.startOfDay(for: highlight.date) == today
        }
    }
    
    @State private var isEditing = false
    @State private var selectedHighlight: Highlight?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        Button(isEditing ? "Done" : "Edit") {
                            checkAndRemoveEmptyHighlights()
                            isEditing.toggle()
                        }
                    }
                    .padding(.horizontal)
                    
                    ForEach(highlights) { highlight in
                        HighlightBox(highlight: highlight, 
                                   isEditing: isEditing,
                                   isSelected: selectedHighlight == highlight)
                            .onTapGesture {
                                if isEditing {
                                    selectedHighlight = highlight
                                }
                            }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                if highlights.isEmpty {
                    createInitialHighlights()
                }
            }
            .onDisappear {
                checkAndRemoveEmptyHighlights()
            }
        }
    }
    
    private func createInitialHighlights() {
        for i in 1...3 {
            let highlight = Highlight(order: i)
            modelContext.insert(highlight)
        }
    }
    
    private func checkAndRemoveEmptyHighlights() {
        let highlightsToRemove = highlights.filter { highlight in
            highlight.text.isEmpty &&           // Is leeg
            highlight.order > 3 &&              // Niet één van de eerste drie
            highlight.order != highlights.count  // Niet de laatste
        }
        
        for highlight in highlightsToRemove {
            modelContext.delete(highlight)
        }
        
        // Herorden de overgebleven highlights
        let remainingHighlights = highlights.filter { !highlightsToRemove.contains($0) }
        for (index, highlight) in remainingHighlights.enumerated() {
            highlight.order = index + 1
        }
    }
    
    private func syncWithPastHighlights(_ highlight: Highlight) {
        guard highlight.order <= 3 else { return }
        
        // Zoek de corresponderende past highlight voor vandaag
        let matchingPastHighlight = todaysPastHighlights.first { $0.order == highlight.order }
        
        if let pastHighlight = matchingPastHighlight {
            // Update bestaande highlight
            pastHighlight.text = highlight.text
        } else {
            // Maak nieuwe highlight aan
            let newPastHighlight = Highlight(
                text: highlight.text,
                date: Date(),
                order: highlight.order,
                isToday: false
            )
            modelContext.insert(newPastHighlight)
        }
    }
} 
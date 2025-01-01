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
            let highlight = Highlight(order: i, isPermanent: true)
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
        guard highlight.isPermanent else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Vereenvoudigde predicate
        let descriptor = FetchDescriptor<Highlight>(
            predicate: #Predicate<Highlight> { h in
                !h.isToday
            }
        )
        
        do {
            let pastHighlights = try modelContext.fetch(descriptor)
            // Filter na het ophalen
            let todaysPastHighlight = pastHighlights.first { h in
                h.isPermanent && 
                h.order == highlight.order &&
                calendar.startOfDay(for: h.date) == today
            }
            
            if let existing = todaysPastHighlight {
                existing.text = highlight.text
            } else {
                let newPastHighlight = Highlight(
                    text: highlight.text,
                    date: Date(),
                    order: highlight.order,
                    isToday: false,
                    isPermanent: true
                )
                modelContext.insert(newPastHighlight)
            }
        } catch {
            print("Error syncing highlights: \(error)")
        }
    }
} 
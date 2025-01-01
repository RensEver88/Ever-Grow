import SwiftData
import Combine
import Foundation

class HighlightManager {
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupMidnightReset()
        checkAndResetIfNeeded()
    }
    
    private func setupMidnightReset() {
        let calendar = Calendar.current
        
        // Calculate next midnight
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        components.second = 0
        guard let midnight = calendar.nextDate(after: Date(),
                                             matching: components,
                                             matchingPolicy: .nextTime) else {
            return
        }
        
        // Calculate time interval until midnight
        let timeUntilMidnight = midnight.timeIntervalSince(Date())
        
        // Create a timer that fires at midnight and then every 24 hours
        Timer.publish(every: 24 * 60 * 60, on: .main, in: .common)
            .autoconnect()
            .delay(for: .seconds(timeUntilMidnight), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.resetTodayHighlights()
            }
            .store(in: &cancellables)
    }
    
    private func checkAndResetIfNeeded() {
        let calendar = Calendar.current
        let descriptor = FetchDescriptor<Highlight>(
            predicate: #Predicate<Highlight> { highlight in
                highlight.isToday
            }
        )
        
        do {
            let highlights = try modelContext.fetch(descriptor)
            if let firstHighlight = highlights.first {
                // Check if the highlight is from a previous day
                if !calendar.isDateInToday(firstHighlight.date) {
                    resetTodayHighlights()
                }
            } else {
                // No highlights exist, create initial ones
                for i in 1...3 {
                    let highlight = Highlight(order: i)
                    modelContext.insert(highlight)
                }
                try modelContext.save()
            }
        } catch {
            print("Error checking highlights: \(error)")
        }
    }
    
    private func resetTodayHighlights() {
        let descriptor = FetchDescriptor<Highlight>(
            predicate: #Predicate<Highlight> { highlight in
                highlight.isToday
            }
        )
        
        do {
            let highlights = try modelContext.fetch(descriptor)
            
            // Kopieer eerst de top 3 highlights naar de Past tab
            let topHighlights = highlights.filter { $0.order <= 3 && !$0.text.isEmpty }
            for highlight in topHighlights {
                let pastHighlight = Highlight(
                    text: highlight.text,
                    date: Date(),
                    order: highlight.order,
                    isToday: false
                )
                modelContext.insert(pastHighlight)
            }
            
            // Markeer alle huidige highlights als niet-vandaag
            for highlight in highlights {
                highlight.isToday = false
            }
            
            // Maak nieuwe lege highlights voor vandaag
            for i in 1...3 {
                let newHighlight = Highlight(text: "", order: i)
                modelContext.insert(newHighlight)
            }
            
            try modelContext.save()
        } catch {
            print("Error resetting highlights: \(error)")
        }
    }
} 
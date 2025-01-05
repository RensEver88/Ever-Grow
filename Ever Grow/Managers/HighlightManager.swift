import SwiftData
import Combine
import Foundation
import UIKit

class HighlightManager {
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupMidnightReset()
        checkAndResetIfNeeded()
        
        // Add notification observer for when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkDateOnActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func checkDateOnActivation() {
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
            
            // Check if we have any highlights and if they're from a previous day
            if let firstHighlight = highlights.first {
                if !calendar.isDateInToday(firstHighlight.date) {
                    resetTodayHighlights()
                }
            } else {
                // No highlights exist, create initial three
                createInitialHighlights()
            }
        } catch {
            print("Error checking highlights: \(error)")
        }
    }
    
    private func createInitialHighlights() {
        for i in 1...3 {
            let highlight = Highlight(order: i, isPermanent: true)
            modelContext.insert(highlight)
        }
        try? modelContext.save()
    }
    
    private func resetTodayHighlights() {
        let descriptor = FetchDescriptor<Highlight>(
            predicate: #Predicate<Highlight> { highlight in
                highlight.isToday
            },
            sortBy: [SortDescriptor(\Highlight.order)]
        )
        
        do {
            let highlights = try modelContext.fetch(descriptor)
            
            // Filter eerst op de top 3 en niet-lege highlights
            let topThreeHighlights = highlights
                .filter { $0.order <= 3 && !$0.text.isEmpty }
                .prefix(3)
            
            // Maak een snapshot van de huidige staat
            let snapshotHighlights = Array(topThreeHighlights).map { highlight in
                (order: highlight.order, text: highlight.text)
            }
            
            // Maak nieuwe past highlights met de exacte snapshot data
            let pastHighlights = snapshotHighlights.map { snapshot in
                Highlight(
                    text: snapshot.text,
                    date: Date(),
                    order: snapshot.order,
                    isToday: false,
                    isPermanent: true
                )
            }
            
            // Verwijder alle highlights van vandaag
            for highlight in highlights {
                modelContext.delete(highlight)
            }
            
            // Voeg eerst alle past highlights toe
            for highlight in pastHighlights {
                modelContext.insert(highlight)
            }
            
            // Maak nieuwe lege highlights voor vandaag
            createInitialHighlights()
            
            try modelContext.save()
        } catch {
            print("Error resetting highlights: \(error)")
        }
    }
} 
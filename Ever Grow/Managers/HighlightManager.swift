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
    
    private func syncHighlights(_ highlights: [Highlight]) {
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // 1. Verwijder eerst alle bestaande past highlights van vandaag
            let pastDescriptor = FetchDescriptor<Highlight>(
                predicate: #Predicate<Highlight> { highlight in
                    highlight.isToday == false
                }
            )
            let pastHighlights = try modelContext.fetch(pastDescriptor)
            
            // Verwijder alle past highlights van vandaag
            pastHighlights
                .filter { calendar.startOfDay(for: $0.date) == today }
                .forEach { modelContext.delete($0) }
            
            // 2. Maak nieuwe exacte kopieën voor de top 3
            let topThreeHighlights = highlights
                .filter { $0.order <= 3 }
                .sorted { $0.order < $1.order }
            
            // Maak exacte kopieën
            for highlight in topThreeHighlights {
                let pastHighlight = Highlight(
                    text: highlight.text,
                    date: today,
                    order: highlight.order,
                    isToday: false,
                    isPermanent: true
                )
                modelContext.insert(pastHighlight)
            }
            
            try modelContext.save()
        } catch {
            print("Error syncing highlights: \(error)")
        }
    }
    
    private func resetTodayHighlights() {
        do {
            // Haal alle today highlights op
            let todayDescriptor = FetchDescriptor<Highlight>(
                predicate: #Predicate<Highlight> { highlight in
                    highlight.isToday
                },
                sortBy: [SortDescriptor(\Highlight.order)]
            )
            let todayHighlights = try modelContext.fetch(todayDescriptor)
            
            // Sync voordat we resetten
            syncHighlights(todayHighlights)
            
            // Verwijder alle today highlights
            for highlight in todayHighlights {
                modelContext.delete(highlight)
            }
            
            // Maak nieuwe highlights
            createInitialHighlights()
            
            try modelContext.save()
        } catch {
            print("Error resetting highlights: \(error)")
        }
    }
} 
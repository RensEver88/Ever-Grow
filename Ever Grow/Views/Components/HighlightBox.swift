import SwiftUI
import SwiftData

struct HighlightBox: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var highlight: Highlight
    let isEditing: Bool
    let isSelected: Bool
    
    @FocusState private var isFocused: Bool
    @Query(filter: #Predicate<Highlight> { highlight in
        highlight.isToday
    }) private var highlights: [Highlight]
    
    private var shouldAddNewBox: Bool {
        // Check of de eerste drie boxes gevuld zijn
        let topThreeFilled = highlights.filter { $0.order <= 3 }
            .allSatisfy { !$0.text.isEmpty }
        
        // Check of er een vierde box is
        let hasFourthBox = highlights.contains { $0.order == 4 }
        
        return topThreeFilled && !hasFourthBox
    }
    
    private var allEightBoxesFilled: Bool {
        highlights.count == 8 && highlights.allSatisfy { !$0.text.isEmpty }
    }
    
    private func checkAndRemoveEmptyBoxes() {
        // If one of the top 3 is empty
        if highlights.filter({ $0.order <= 3 }).contains(where: { $0.text.isEmpty }) {
            // Remove empty boxes after the first three, but keep at least one
            let emptyBoxesAfterThree = highlights.filter { highlight in
                highlight.order > 3 && highlight.text.isEmpty
            }
            
            // Only remove if there are at least 2 empty boxes beyond the first three
            if emptyBoxesAfterThree.count > 1 {
                // Keep the first empty box, remove the rest
                let boxesToRemove = Array(emptyBoxesAfterThree.dropFirst())
                
                for highlight in boxesToRemove {
                    modelContext.delete(highlight)
                }
                
                reorderHighlights()
            }
        }
    }
    
    private func checkAndRemoveLowestEmptyBox() {
        let emptyBoxes = highlights.filter { $0.text.isEmpty }
        
        // Only remove if there are more than one empty box
        // AND there will still be at least one empty box left after removal
        if emptyBoxes.count > 1 {
            // Find the empty box with the highest order (lowest in the list)
            if let boxToRemove = emptyBoxes.max(by: { $0.order < $1.order }) {
                // Don't remove if it's one of the first three
                // AND don't remove if it's the only empty box beyond the first three
                if boxToRemove.order > 3 {
                    let emptyBoxesAfterThree = highlights.filter { $0.order > 3 && $0.text.isEmpty }
                    if emptyBoxesAfterThree.count > 1 {
                        modelContext.delete(boxToRemove)
                        reorderHighlights()
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if isEditing {
                    VStack(spacing: 4) {
                        if highlight.order > 1 {
                            Button {
                                moveHighlight(direction: .up)
                            } label: {
                                Image(systemName: "arrowtriangle.up.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("\(highlight.order)")
                            .foregroundColor(.secondary)
                            .frame(width: 25)
                        
                        if highlight.order < 8 {
                            Button {
                                moveHighlight(direction: .down)
                            } label: {
                                Image(systemName: "arrowtriangle.down.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } else {
                    Text("\(highlight.order)")
                        .foregroundColor(.secondary)
                        .frame(width: 25, alignment: .trailing)
                }
                
                ZStack(alignment: .leading) {
                    if highlight.text.isEmpty {
                        Text(LocalizedStrings.enterHighlight.localized)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    
                    TextEditor(text: $highlight.text)
                        .frame(minHeight: 20)
                        .frame(maxHeight: .infinity)
                        .focused($isFocused)
                        .onChange(of: highlight.text) { oldValue, newValue in
                            if highlight.order <= 3 {
                                syncWithPastHighlights()
                                checkAndRemoveEmptyBoxes()
                            }
                            
                            if newValue.isEmpty {
                                checkAndRemoveLowestEmptyBox()
                            } else {
                                checkAndAddNewHighlight()
                            }
                        }
                        .allowsHitTesting(!isEditing)
                }
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    )
                
                if isFocused {
                    Button {
                        isFocused = false // Verberg keyboard
                        
                        // Verwijder lege box (behalve de eerste drie)
                        if highlight.text.isEmpty && highlight.order > 3 {
                            modelContext.delete(highlight)
                            reorderHighlights()
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                }
                
                if isEditing && highlight.order > 3 {
                    Button {
                        modelContext.delete(highlight)
                        reorderHighlights()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            
            if allEightBoxesFilled && highlight.order == 8 {
                Text("Great awareness. Highlights are everywhere!")
                    .foregroundColor(Color(hex: "F88F3B"))
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private enum MoveDirection {
        case up, down
    }
    
    private func moveHighlight(direction: MoveDirection) {
        let targetOrder = direction == .up ? highlight.order - 1 : highlight.order + 1
        
        let descriptor = FetchDescriptor<Highlight>(
            predicate: #Predicate<Highlight> { highlight in
                highlight.isToday && highlight.order == targetOrder
            }
        )
        
        if let targetHighlight = try? modelContext.fetch(descriptor).first {
            // Wissel orders
            targetHighlight.order = highlight.order
            highlight.order = targetOrder
            
            // Sync beide highlights als ze in top 3 zijn
            if highlight.order <= 3 {
                syncWithPastHighlights()
            }
            if targetHighlight.order <= 3 {
                // Sync de andere highlight ook
                let descriptor = FetchDescriptor<Highlight>(
                    predicate: #Predicate<Highlight> { h in
                        !h.isToday
                    }
                )
                if let pastHighlights = try? modelContext.fetch(descriptor) {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let matchingHighlight = pastHighlights.first { h in
                        calendar.startOfDay(for: h.date) == today && h.order == targetHighlight.order
                    }
                    if let pastHighlight = matchingHighlight {
                        pastHighlight.text = targetHighlight.text
                    }
                }
            }
        }
    }
    
    private func reorderHighlights() {
        let descriptor = FetchDescriptor<Highlight>(
            predicate: #Predicate<Highlight> { highlight in
                highlight.isToday
            },
            sortBy: [SortDescriptor(\Highlight.order)]
        )
        
        if let highlights = try? modelContext.fetch(descriptor) {
            for (index, highlight) in highlights.enumerated() {
                highlight.order = index + 1
            }
            
            // Check of we een nieuwe box moeten toevoegen na het herordenen
            if highlights.count == 3 && highlights.allSatisfy({ !$0.text.isEmpty }) {
                let newHighlight = Highlight(
                    text: "",
                    order: 4,
                    isToday: true
                )
                modelContext.insert(newHighlight)
            }
        }
    }
    
    private func checkAndAddNewHighlight() {
        // Als alle velden gevuld zijn en we hebben nog niet het maximum bereikt
        if highlights.count < 8 {
            let allFilled = highlights.allSatisfy { !$0.text.isEmpty }
            if allFilled {
                let newHighlight = Highlight(
                    text: "",
                    order: highlights.count + 1,
                    isToday: true
                )
                modelContext.insert(newHighlight)
            }
        }
    }
    
    private func syncWithPastHighlights() {
        // Haal alle past highlights op
        let descriptor = FetchDescriptor<Highlight>(
            predicate: #Predicate<Highlight> { h in
                !h.isToday
            }
        )
        
        do {
            let pastHighlights = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Filter voor vandaag en juiste order
            let matchingHighlight = pastHighlights.first { h in
                calendar.startOfDay(for: h.date) == today && h.order == highlight.order
            }
            
            if let pastHighlight = matchingHighlight {
                pastHighlight.text = highlight.text
            } else {
                let newPastHighlight = Highlight(
                    text: highlight.text,
                    date: Date(),
                    order: highlight.order,
                    isToday: false
                )
                modelContext.insert(newPastHighlight)
            }
        } catch {
            print("Error syncing highlights: \(error)")
        }
    }
}

// Helper extension voor hex kleur
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
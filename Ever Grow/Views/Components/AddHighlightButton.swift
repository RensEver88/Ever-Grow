import SwiftUI
import SwiftData

struct AddHighlightButton: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Highlight> { highlight in
        highlight.isToday == true
    }) private var highlights: [Highlight]
    
    var body: some View {
        Button {
            addNewHighlight()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Voeg highlight toe")
            }
        }
        .disabled(highlights.count >= 8)
    }
    
    private func addNewHighlight() {
        let newHighlight = Highlight(
            text: "",
            order: highlights.count + 1,
            isToday: true
        )
        modelContext.insert(newHighlight)
    }
} 
import SwiftUI
import SwiftData

struct PastView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Highlight> { highlight in
            !highlight.isToday
        },
        sort: [
            SortDescriptor(\Highlight.date, order: .reverse),
            SortDescriptor(\Highlight.order)
        ]
    ) private var highlights: [Highlight]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedHighlights.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(formatDate(date))) {
                        if let dayHighlights = groupedHighlights[date]?.sorted(by: { $0.order < $1.order }) {
                            ForEach(dayHighlights) { highlight in
                                Text(highlight.text)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            highlightToDelete = highlight
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Verwijder", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            editHighlight(highlight)
                                        } label: {
                                            Label("Bewerk", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Eerdere Highlights")
        }
        .sheet(item: $highlightToEdit) { highlight in
            NavigationStack {
                Form {
                    TextField("Highlight", text: $editText)
                }
                .navigationTitle("Bewerk Highlight")
                .navigationBarItems(
                    leading: Button("Annuleer") {
                        highlightToEdit = nil
                    },
                    trailing: Button("Opslaan") {
                        highlight.text = editText
                        highlightToEdit = nil
                    }
                )
            }
        }
        .confirmationDialog(
            "Weet je zeker dat je deze highlight wilt verwijderen?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Verwijderen", role: .destructive) {
                if let highlight = highlightToDelete {
                    deleteHighlight(highlight)
                }
                highlightToDelete = nil
            }
        }
    }
    
    @State private var highlightToEdit: Highlight?
    @State private var editText = ""
    @State private var showingEditDialog = false
    @State private var showingDeleteConfirmation = false
    @State private var highlightToDelete: Highlight?
    
    private var groupedHighlights: [Date: [Highlight]] {
        Dictionary(grouping: highlights) { highlight in
            Calendar.current.startOfDay(for: highlight.date)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func deleteHighlight(_ highlight: Highlight) {
        showingDeleteConfirmation = true
        highlightToDelete = highlight
    }
    
    private func editHighlight(_ highlight: Highlight) {
        highlightToEdit = highlight
        editText = highlight.text
    }
} 
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
    
    private var groupedHighlights: [Date: [Highlight]] {
        let calendar = Calendar.current
        
        let dict = Dictionary(grouping: highlights) { highlight in
            calendar.startOfDay(for: highlight.date)
        }
        
        // Filter om alleen de eerste 3 highlights per dag te behouden
        return dict.mapValues { highlights in
            highlights
                .sorted { $0.order < $1.order }
                .prefix(3)
                .map { $0 }
        }
    }
    
    var body: some View {
        NavigationStack {
            HighlightsList(
                groupedHighlights: groupedHighlights,
                onDelete: { highlight in
                    highlightToDelete = highlight
                    showingDeleteConfirmation = true
                },
                onEdit: editHighlight
            )
            .navigationTitle(LocalizedStrings.previousHighlights.localized)
        }
        .sheet(item: $highlightToEdit) { highlight in
            EditHighlightView(
                highlight: highlight,
                editText: $editText,
                onDismiss: { highlightToEdit = nil }
            )
        }
        .confirmationDialog(
            LocalizedStrings.deleteConfirmation.localized,
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(LocalizedStrings.delete.localized, role: .destructive) {
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
        
        // Als dit een permanente highlight is, update ook de Today versie
        if highlight.isPermanent {
            // Vereenvoudigde predicate
            let descriptor = FetchDescriptor<Highlight>(
                predicate: #Predicate<Highlight> { h in
                    h.isToday
                }
            )
            
            if let todayHighlights = try? modelContext.fetch(descriptor) {
                // Filter na het ophalen
                let matchingHighlight = todayHighlights.first { h in
                    h.isPermanent && h.order == highlight.order
                }
                
                if let todayHighlight = matchingHighlight {
                    todayHighlight.text = highlight.text
                }
            }
        }
    }
}

// MARK: - Subviews
private struct HighlightsList: View {
    let groupedHighlights: [Date: [Highlight]]
    let onDelete: (Highlight) -> Void
    let onEdit: (Highlight) -> Void
    
    var body: some View {
        List {
            ForEach(groupedHighlights.keys.sorted(by: >), id: \.self) { date in
                if let dayHighlights = groupedHighlights[date] {
                    Section(header: Text(formatDate(date))) {
                        ForEach(dayHighlights) { highlight in
                            HighlightRow(
                                highlight: highlight,
                                onDelete: onDelete,
                                onEdit: onEdit
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

private struct HighlightRow: View {
    let highlight: Highlight
    let onDelete: (Highlight) -> Void
    let onEdit: (Highlight) -> Void
    
    var body: some View {
        Text(highlight.text)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    onDelete(highlight)
                } label: {
                    Label(LocalizedStrings.delete.localized, systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    onEdit(highlight)
                } label: {
                    Label(LocalizedStrings.edit.localized, systemImage: "pencil")
                }
                .tint(.blue)
            }
    }
}

private struct EditHighlightView: View {
    let highlight: Highlight
    @Binding var editText: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField(LocalizedStrings.enterHighlight.localized, text: $editText)
            }
            .navigationTitle(LocalizedStrings.edit.localized)
            .navigationBarItems(
                leading: Button(LocalizedStrings.cancel.localized, action: onDismiss),
                trailing: Button(LocalizedStrings.done.localized) {
                    highlight.text = editText
                    onDismiss()
                }
            )
        }
    }
} 
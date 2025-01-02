import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [NotificationSettings]
    @Query(filter: #Predicate<Highlight> { highlight in
        !highlight.isToday
    }, sort: [
        SortDescriptor(\Highlight.date, order: .reverse)
    ]) private var pastHighlights: [Highlight]
    
    @State private var currentSettings: NotificationSettings?
    @State private var notificationManager = NotificationManager()
    
    // Export states
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text(LocalizedStrings.notifications.localized)) {
                if let settings = currentSettings {
                    Toggle("Turn on notifications", isOn: Binding(
                        get: { settings.isEnabled },
                        set: { newValue in
                            settings.isEnabled = newValue
                            updateNotifications()
                        }
                    ))
                    
                    if settings.isEnabled {
                        Stepper("Number of notifications per day: \(settings.numberOfNotifications)",
                               value: Binding(
                                get: { settings.numberOfNotifications },
                                set: { newValue in
                                    settings.numberOfNotifications = newValue
                                    updateNotificationTimes()
                                }
                               ), in: 1...3)
                        
                        ForEach(0..<settings.numberOfNotifications, id: \.self) { index in
                            DatePicker(
                                "Notification \(index + 1)",
                                selection: binding(for: index, settings: settings),
                                displayedComponents: .hourAndMinute
                            )
                        }
                        
                        WeekdaySelector(selectedDays: Binding(
                            get: { settings.selectedWeekdays },
                            set: { newValue in
                                settings.selectedWeekdays = newValue
                                updateNotifications()
                            }
                        ))
                    }
                }
            }
            
            Section {
                Button(action: exportToCSV) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(LocalizedStrings.export.localized)
                    }
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    Text("Version 0.3")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    Spacer()
                }
            }
        }
        .navigationTitle(LocalizedStrings.settings.localized)
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
                    .presentationDetents([.medium])
                    .ignoresSafeArea()
            }
        }
        .alert("Export Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            notificationManager.requestAuthorization()
            if currentSettings == nil {
                if let existing = settings.first {
                    currentSettings = existing
                } else {
                    let new = NotificationSettings()
                    modelContext.insert(new)
                    currentSettings = new
                }
            }
        }
    }
    
    private func binding(for index: Int, settings: NotificationSettings) -> Binding<Date> {
        Binding(
            get: {
                if index < settings.notificationTimes.count {
                    return settings.notificationTimes[index]
                }
                let date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
                settings.notificationTimes.append(date)
                return date
            },
            set: { newValue in
                while settings.notificationTimes.count <= index {
                    settings.notificationTimes.append(Date())
                }
                settings.notificationTimes[index] = newValue
                updateNotifications()
            }
        )
    }
    
    private func updateNotificationTimes() {
        guard let settings = currentSettings else { return }
        while settings.notificationTimes.count > settings.numberOfNotifications {
            settings.notificationTimes.removeLast()
        }
        updateNotifications()
    }
    
    private func updateNotifications() {
        guard let settings = currentSettings else { return }
        notificationManager.updateNotifications(with: settings)
    }
    
    private func exportToCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale(identifier: "nl_NL")
        
        var csvString = "Datum,Highlight 1,Highlight 2,Highlight 3\n"
        
        let groupedHighlights = Dictionary(grouping: pastHighlights) { highlight in
            Calendar.current.startOfDay(for: highlight.date)
        }
        
        for date in groupedHighlights.keys.sorted(by: >) {
            if let dayHighlights = groupedHighlights[date] {
                let sortedHighlights = dayHighlights.sorted { $0.order < $1.order }
                let dateString = dateFormatter.string(from: date)
                
                var highlightTexts = Array(sortedHighlights.prefix(3)).map { $0.text }
                while highlightTexts.count < 3 {
                    highlightTexts.append("")
                }
                
                let escapedTexts = highlightTexts.map { text in
                    let escaped = text
                        .replacingOccurrences(of: "\"", with: "\"\"")
                        .replacingOccurrences(of: "\n", with: " ")
                    return "\"\(escaped)\""
                }
                
                csvString += "\(dateString),\(escapedTexts.joined(separator: ","))\n"
            }
        }
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        
        let filename = "Highlights_\(timestamp).csv"
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(filename)
            
            do {
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                exportURL = fileURL
                showingExportSheet = true
            } catch {
                errorMessage = "Error creating file: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// Helper view voor het delen van bestanden
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
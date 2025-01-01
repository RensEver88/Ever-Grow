import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [NotificationSettings]
    @State private var notificationManager = NotificationManager()
    
    @State private var currentSettings: NotificationSettings?
    
    var body: some View {
        Form {
            Section(header: Text("Notificaties")) {
                if let settings = currentSettings {
                    Toggle("Notificaties inschakelen", isOn: Binding(
                        get: { settings.isEnabled },
                        set: { newValue in
                            settings.isEnabled = newValue
                            updateNotifications()
                        }
                    ))
                    
                    if settings.isEnabled {
                        Stepper("Aantal notificaties per dag: \(settings.numberOfNotifications)",
                               value: Binding(
                                get: { settings.numberOfNotifications },
                                set: { newValue in
                                    settings.numberOfNotifications = newValue
                                    updateNotificationTimes()
                                }
                               ), in: 1...3)
                        
                        ForEach(0..<settings.numberOfNotifications, id: \.self) { index in
                            DatePicker(
                                "Notificatie \(index + 1)",
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
                HStack {
                    Spacer()
                    Text("Versie 0.11")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    Spacer()
                }
            }
        }
        .navigationTitle("Instellingen")
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
} 
import UserNotifications
import SwiftData

class NotificationManager {
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    func updateNotifications(with settings: NotificationSettings) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard settings.isEnabled else { return }
        
        // Validate and sort notification times
        let sortedTimes = settings.notificationTimes
            .prefix(settings.numberOfNotifications)
            .sorted()
        
        for time in sortedTimes {
            for weekday in settings.selectedWeekdays {
                scheduleNotification(at: time, weekday: weekday, with: settings.notificationText)
            }
        }
    }
    
    private func scheduleNotification(at time: Date, weekday: Int, with text: String) {
        let content = UNMutableNotificationContent()
        content.title = "Ever Grow"
        content.body = text
        content.sound = .default
        
        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.weekday = weekday
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "highlight-reminder-\(weekday)-\(components.hour ?? 0)-\(components.minute ?? 0)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
} 
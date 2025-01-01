import Foundation
import SwiftData

@Model
final class NotificationSettings {
    var isEnabled: Bool
    var numberOfNotifications: Int
    var notificationTimes: [Date]
    var selectedWeekdays: [Int]
    var notificationText: String
    
    init(isEnabled: Bool = false,
         numberOfNotifications: Int = 1,
         notificationTimes: [Date] = [],
         selectedWeekdays: [Int] = Array(1...7),
         notificationText: String = "Any highlights to enter and save?") {
        self.isEnabled = isEnabled
        self.numberOfNotifications = numberOfNotifications
        self.notificationTimes = notificationTimes
        self.selectedWeekdays = selectedWeekdays
        self.notificationText = notificationText
    }
} 
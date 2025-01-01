import Foundation

enum LocalizedStrings {
    case settings
    case notifications
    case enableNotifications
    case notificationsPerDay
    case notification
    case today
    case past
    case previousHighlights
    case enterHighlight
    case export
    case version
    case edit
    case done
    case enable
    case delete
    case cancel
    case deleteConfirmation
    
    var localized: String {
        switch self {
        case .settings:
            return "Settings"
        case .notifications:
            return "Notifications"
        case .enableNotifications:
            return "Enable notifications"
        case .notificationsPerDay:
            return "Notifications per day"
        case .notification:
            return "Notification"
        case .today:
            return "Today"
        case .past:
            return "Past"
        case .previousHighlights:
            return "Previous Highlights"
        case .enterHighlight:
            return "Enter a highlight"
        case .export:
            return "Export highlights to CSV"
        case .version:
            return "Version"
        case .edit:
            return "Edit"
        case .done:
            return "Done"
        case .enable:
            return "On"
        case .delete:
            return "Delete"
        case .cancel:
            return "Cancel"
        case .deleteConfirmation:
            return "Are you sure you want to delete this highlight?"
        }
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
} 
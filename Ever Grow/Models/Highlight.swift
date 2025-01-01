import Foundation
import SwiftData

@Model
final class Highlight {
    var text: String
    var date: Date
    var order: Int
    var isToday: Bool
    
    init(text: String = "", date: Date = Date(), order: Int, isToday: Bool = true) {
        self.text = text
        self.date = date
        self.order = order
        self.isToday = isToday
    }
} 
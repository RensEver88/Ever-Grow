import SwiftUI

struct WeekdaySelector: View {
    @Binding var selectedDays: [Int]
    
    private let weekdays = [
        "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"
    ]
    
    var body: some View {
        HStack {
            ForEach(1...7, id: \.self) { day in
                Button {
                    toggleDay(day)
                } label: {
                    Text(weekdays[day - 1])
                        .padding(8)
                        .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
            selectedDays.sort()
        }
    }
} 
import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let hasWorkout: Bool
    let isSelected: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(cellBackground)
                    .frame(width: 34, height: 34)

                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundStyle(cellForeground)
            }

            Circle()
                .fill(isSelected ? Color.white : Color.orange)
                .frame(width: 4, height: 4)
                .opacity(hasWorkout ? 1 : 0)
        }
        .frame(height: 44)
    }

    private var cellBackground: Color {
        if isSelected { return .orange }
        if isToday    { return .orange.opacity(0.15) }
        return .clear
    }

    private var cellForeground: Color {
        if isSelected { return .white }
        if isToday    { return .orange }
        return .primary
    }
}

import SwiftUI

struct CalendarView: View {

    @Environment(WorkoutStore.self) private var store

    @State private var displayedMonth = Date()
    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current
    private let columns  = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthCard
                    if let date = selectedDate {
                        dayDetailCard(date: date)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Calendar")
            .animation(.spring(response: 0.3), value: selectedDate)
            .animation(.spring(response: 0.3), value: displayedMonth)
        }
    }

    // MARK: - Month Card

    private var monthCard: some View {
        VStack(spacing: 12) {
            monthNavHeader
            weekdayHeader
            Divider()
            calendarGrid
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var monthNavHeader: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                if let date {
                    let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    let hasWorkout = store.hasSession(on: date)
                    let isToday   = calendar.isDateInToday(date)

                    CalendarDayCell(
                        date: date,
                        hasWorkout: hasWorkout,
                        isSelected: isSelected,
                        isToday: isToday
                    )
                    .onTapGesture {
                        selectedDate = isSelected ? nil : date
                    }
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    // MARK: - Day Detail

    @ViewBuilder
    private func dayDetailCard(date: Date) -> some View {
        let sessions = store.sessions(on: date)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.headline)
                Spacer()
                if sessions.isEmpty {
                    Text("Rest Day")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground), in: Capsule())
                }
            }

            if sessions.isEmpty {
                HStack {
                    Image(systemName: "moon.zzz")
                        .foregroundStyle(.secondary)
                    Text("No workouts on this day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(sessions) { session in
                    SessionDetailRow(session: session)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Days in Month (Monday-first grid)

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }

        // Offset for Monday-first grid: Mon=0 … Sun=6
        let weekday = calendar.component(.weekday, from: monthInterval.start)
        let offset  = (weekday + 5) % 7  // converts Sun=1…Sat=7 → Mon=0…Sun=6

        var days: [Date?] = Array(repeating: nil, count: offset)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

// MARK: - Calendar Day Cell

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

// MARK: - Session Detail Row

struct SessionDetailRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: session.type == .push ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(session.type == .push ? .orange : .blue)
                Text("\(session.type.rawValue) Day")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(session.formattedDuration)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                HStack {
                    Text("Volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f kg", session.totalVolume))
                        .font(.caption.weight(.semibold))
                }
                HStack {
                    Text("Total Reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(session.totalReps) reps · \(session.totalSets) sets")
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(10)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            if !session.entries.isEmpty {
                VStack(spacing: 3) {
                    ForEach(session.entries) { entry in
                        HStack {
                            Text("· \(entry.exercise.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(entry.setCount) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    CalendarView()
        .environment(WorkoutStore())
}

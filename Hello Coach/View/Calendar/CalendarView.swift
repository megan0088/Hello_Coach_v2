import SwiftUI

struct CalendarView: View {

    @Environment(CalendarViewModel.self) private var vm

    private let calendar = Calendar.current
    private let columns  = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthCard
                    if let date = vm.selectedDate {
                        dayDetailCard(date: date)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Calendar")
            .animation(.spring(response: 0.3), value: vm.selectedDate)
            .animation(.spring(response: 0.3), value: vm.displayedMonth)
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
                vm.displayedMonth = calendar.date(byAdding: .month, value: -1, to: vm.displayedMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(vm.displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)

            Spacer()

            Button {
                vm.displayedMonth = calendar.date(byAdding: .month, value: 1, to: vm.displayedMonth)!
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
                    let isSelected = vm.selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    let hasWorkout = vm.hasSession(on: date)
                    let isToday   = calendar.isDateInToday(date)

                    CalendarDayCell(
                        date: date,
                        hasWorkout: hasWorkout,
                        isSelected: isSelected,
                        isToday: isToday
                    )
                    .onTapGesture {
                        vm.selectedDate = isSelected ? nil : date
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
        let sessions = vm.sessions(on: date)

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
        guard let monthInterval = calendar.dateInterval(of: .month, for: vm.displayedMonth) else { return [] }

        let weekday = calendar.component(.weekday, from: monthInterval.start)
        let offset  = (weekday + 5) % 7

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

#Preview {
    let store = WorkoutStore.preview
    CalendarView()
        .environment(CalendarViewModel(store: store))
}

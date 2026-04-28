import SwiftUI
import Charts

struct AnalyticsView: View {

    @Environment(WorkoutStore.self) private var store

    @State private var selectedExercise: Exercise?
    @State private var timeRange: TimeRange = .sixMonths

    enum TimeRange: String, CaseIterable {
        case oneMonth    = "1M"
        case threeMonths = "3M"
        case sixMonths   = "6M"
        case oneYear     = "1Y"
        case all         = "ALL"

        var days: Int? {
            switch self {
            case .oneMonth:    return 30
            case .threeMonths: return 90
            case .sixMonths:   return 180
            case .oneYear:     return 365
            case .all:         return nil
            }
        }
    }

    private let musclePalette: [Color] = [.orange, .blue, .green, .purple, .red]

    private var currentExercise: Exercise {
        selectedExercise ?? store.trackedExercises.first ?? .benchPress
    }

    private var filteredHistory: [(date: Date, totalVolume: Double, totalReps: Int)] {
        let history = store.history(for: currentExercise)
        guard let days = timeRange.days else { return history }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return history.filter { $0.date >= cutoff }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    exercisePicker
                    timeRangePicker
                    progressCard
                    weeklyVolumeCard
                    muscleFocusCard
                    topPerformancesCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Analytics")
        }
    }

    // MARK: - Exercise Picker

    private var exercisePicker: some View {
        Menu {
            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                Section(category.rawValue) {
                    ForEach(Exercise.exercises(for: category)) { exercise in
                        Button(exercise.displayName) {
                            withAnimation { selectedExercise = exercise }
                        }
                    }
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentExercise.subgroup.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange)
                        .tracking(0.5)
                    Text(currentExercise.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.25)) { timeRange = range }
                } label: {
                    Text(range.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(timeRange == range ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            timeRange == range ? Color.orange : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Progress Card

    @ViewBuilder
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Volume Progress")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if let last = filteredHistory.last {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.0f", last.totalVolume))
                                .font(.title2.weight(.bold))
                            Text("kg")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No data")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let change = volumeChangeLabel {
                    Text(change)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1), in: Capsule())
                }
            }

            chartView
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private static let ghostData: [(date: Date, totalVolume: Double)] = {
        let cal = Calendar.current
        return [0, 20, 45, 30, 60, 40].enumerated().map { i, vol in
            let date = cal.date(byAdding: .month, value: i - 5, to: Date())!
            return (date: date, totalVolume: vol)
        }
    }()

    @ViewBuilder
    private var chartView: some View {
        if filteredHistory.isEmpty {
            Chart(Self.ghostData, id: \.date) { item in
                LineMark(x: .value("Date", item.date), y: .value("Volume", item.totalVolume))
                    .foregroundStyle(Color.secondary.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Date", item.date), y: .value("Volume", item.totalVolume))
                    .foregroundStyle(Color.secondary.opacity(0.08))
                    .interpolationMethod(.catmullRom)
            }
            .frame(height: 140)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Record some sets to see progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        } else {
            Chart(filteredHistory, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Volume", item.totalVolume)
                )
                .foregroundStyle(Color.orange)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Volume", item.totalVolume)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange.opacity(0.25), .orange.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 140)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
    }

    private var volumeChangeLabel: String? {
        guard filteredHistory.count >= 2,
              let first = filteredHistory.first?.totalVolume,
              let last  = filteredHistory.last?.totalVolume,
              first > 0 else { return nil }
        let pct = ((last - first) / first) * 100
        return String(format: "%+.0f%%", pct)
    }

    // MARK: - Weekly Volume

    private var weeklyVolumeCard: some View {
        let data = store.weeklyVolume()
        let total = data.reduce(0.0) { $0 + $1.volume }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Weekly Volume")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f kg", total))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart(data, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day, unit: .day),
                    y: .value("Volume", max(item.volume, total > 0 ? 0 : 1))
                )
                .foregroundStyle(
                    Calendar.current.isDateInToday(item.day)
                        ? Color.orange
                        : Color.orange.opacity(0.3)
                )
                .cornerRadius(4)
            }
            .frame(height: 80)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                }
            }
            .chartYAxis(.hidden)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Muscle Focus

    private var muscleFocusCard: some View {
        let focus = store.muscleFocus()
        let top   = Array(focus.prefix(5))

        return VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Focus")
                .font(.headline)

            if top.isEmpty {
                Text("Complete a session to see muscle breakdown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                HStack(alignment: .center, spacing: 20) {
                    Chart(top, id: \.muscle) { item in
                        SectorMark(
                            angle: .value("Pct", item.percentage),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(by: .value("Muscle", item.muscle.rawValue))
                    }
                    .chartForegroundStyleScale(
                        domain: top.map { $0.muscle.rawValue },
                        range: musclePalette
                    )
                    .chartLegend(.hidden)
                    .frame(width: 110, height: 110)

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(Array(top.enumerated()), id: \.offset) { idx, item in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(musclePalette[idx % musclePalette.count])
                                    .frame(width: 10, height: 10)
                                Text(item.muscle.rawValue)
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.0f%%", item.percentage))
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Top Performances

    private var topPerformancesCard: some View {
        let records: [(Date, RepSet)] = store.completedSessions
            .flatMap { session in
                session.entries
                    .filter { $0.exercise == currentExercise }
                    .flatMap { entry in entry.sets.map { (session.startTime, $0) } }
            }
            .sorted { $0.1.volume > $1.1.volume }

        let top5 = Array(records.prefix(5))

        return VStack(alignment: .leading, spacing: 12) {
            Text("Top Performances")
                .font(.headline)

            if top5.isEmpty {
                Text("No sets recorded yet for \(currentExercise.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("Date")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Weight")
                            .frame(width: 72, alignment: .trailing)
                        Text("Reps")
                            .frame(width: 50, alignment: .trailing)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                    ForEach(Array(top5.enumerated()), id: \.offset) { _, pair in
                        let (date, set) = pair
                        Divider()
                        HStack {
                            Text(date, format: .dateTime.month(.abbreviated).day().year())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(String(format: "%.0f kg", set.weightKg))
                                .frame(width: 72, alignment: .trailing)
                            Text("×\(set.reps)")
                                .frame(width: 50, alignment: .trailing)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 9)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    AnalyticsView()
        .environment(WorkoutStore())
}

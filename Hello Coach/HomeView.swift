import SwiftUI
import Charts

struct HomeView: View {

    @Environment(WorkoutStore.self) private var store
    @EnvironmentObject private var watchSession: PhoneSessionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if store.isWorkoutActive {
                        activeWorkoutCard
                    } else {
                        streakCard
                        startSessionCTA
                    }
                    weeklyVolumeCard
                    if !store.trackedExercises.isEmpty {
                        recentPRsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    connectionDot
                }
            }
        }
    }

    // MARK: - Toolbar

    private var connectionDot: some View {
        Circle()
            .fill(watchSession.isWatchReachable ? Color.green : Color.secondary.opacity(0.4))
            .frame(width: 10, height: 10)
            .overlay(
                Circle().strokeBorder(.background, lineWidth: 1.5)
            )
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 14) {
            Text(store.currentStreak > 0 ? "🔥" : "💤")
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.currentStreak > 0
                     ? "\(store.currentStreak) day streak"
                     : "No active streak")
                    .font(.title3.weight(.bold))

                if let last = store.lastSession {
                    Text("Last: \(last.startTime, format: .relative(presentation: .named)) · \(last.type.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Start your first session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.orange.opacity(store.currentStreak > 0 ? 0.35 : 0), lineWidth: 1)
                )
        )
    }

    // MARK: - Start Session CTA

    private var startSessionCTA: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Start Today's Session")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)
                Text("Open Hello Coach on your Apple Watch")
                    .font(.caption)
                    .foregroundStyle(.black.opacity(0.6))
            }
            Spacer()
            Image(systemName: "applewatch")
                .font(.title2)
                .foregroundStyle(.black.opacity(0.7))
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.orange, Color(red: 0.95, green: 0.6, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Active Workout Card

    private var activeWorkoutCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Live Session", systemImage: "record.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                Spacer()
                Text(store.currentSession?.type.rawValue.uppercased() ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 0) {
                StatCell(label: "Reps", value: "\(store.liveRepCount)")
                Divider().frame(height: 40)
                StatCell(label: "Sets", value: "\(store.currentSession?.totalSets ?? 0)")
                Divider().frame(height: 40)
                StatCell(label: "Volume", value: {
                    let v = Double(store.liveRepCount) * store.activeWeightKg
                    return v > 0 ? String(format: "%.0f kg", v) : "—"
                }())
            }

            if let exercise = store.activeExercise {
                HStack {
                    Text(exercise.displayName)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if store.activeWeightKg > 0 {
                        Text(String(format: "%.0f kg", store.activeWeightKg))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Weekly Volume Chart

    private var weeklyVolumeCard: some View {
        let data = store.weeklyVolume()
        let total = data.reduce(0.0) { $0 + $1.volume }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Weekly Volume")
                    .font(.headline)
                Spacer()
                Text(total > 0 ? String(format: "%.0f KG TOTAL", total) : "No data yet")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
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
                .cornerRadius(5)
            }
            .frame(height: 100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                }
            }
            .chartYAxis(.hidden)
            .chartPlotStyle { plot in
                plot.background(Color.clear)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Recent PRs

    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent PRs")
                .font(.headline)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.trackedExercises.prefix(8)) { exercise in
                        if let pr = store.personalRecord(for: exercise) {
                            PRCard(exercise: exercise, pr: pr)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - PR Card

struct PRCard: View {
    let exercise: Exercise
    let pr: RepSet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
                Text(exercise.subgroup.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.orange)
                    .tracking(0.5)
            }

            Text(exercise.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", pr.weightKg))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text("kg")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text("×\(pr.reps) · \(pr.timestamp, format: .relative(presentation: .named))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 140, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Cell (shared helper)

struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
        .environment(WorkoutStore())
        .environmentObject(PhoneSessionManager())
}

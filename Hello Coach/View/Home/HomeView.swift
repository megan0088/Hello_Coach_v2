import SwiftUI
import Charts

struct HomeView: View {

    @Environment(HomeViewModel.self) private var vm
    @EnvironmentObject private var watchSession: PhoneSessionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if vm.isWorkoutActive {
                        activeWorkoutCard
                    } else {
                        streakCard
                        startSessionCTA
                    }
                    weeklyVolumeCard
                    if !vm.trackedExercises.isEmpty {
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
            .overlay(Circle().strokeBorder(.background, lineWidth: 1.5))
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 14) {
            Text(vm.currentStreak > 0 ? "🔥" : "💤")
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.currentStreak > 0
                     ? "\(vm.currentStreak) day streak"
                     : "No active streak")
                    .font(.title3.weight(.bold))

                if let last = vm.lastSession {
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
                        .strokeBorder(Color.orange.opacity(vm.currentStreak > 0 ? 0.35 : 0), lineWidth: 1)
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
                Text(vm.currentSession?.type.rawValue.uppercased() ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 0) {
                StatCell(label: "Reps", value: "\(vm.liveRepCount)")
                Divider().frame(height: 40)
                StatCell(label: "Sets", value: "\(vm.currentSession?.totalSets ?? 0)")
                Divider().frame(height: 40)
                StatCell(label: "Volume", value: {
                    let v = Double(vm.liveRepCount) * vm.activeWeightKg
                    return v > 0 ? String(format: "%.0f kg", v) : "—"
                }())
            }

            if let exercise = vm.activeExercise {
                HStack {
                    Text(exercise.displayName)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if vm.activeWeightKg > 0 {
                        Text(String(format: "%.0f kg", vm.activeWeightKg))
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
        let data = vm.weeklyVolume()
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
            .chartPlotStyle { plot in plot.background(Color.clear) }
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
                    ForEach(vm.trackedExercises.prefix(8)) { exercise in
                        if let pr = vm.personalRecord(for: exercise) {
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

#Preview {
    let store = WorkoutStore.preview
    HomeView()
        .environment(HomeViewModel(store: store))
        .environmentObject(PhoneSessionManager())
}

//
//  ContentView.swift
//  Hello Coach
//
//  Main iPhone dashboard: shows live rep count from watch,
//  current workout summary, and past workout history.
//

import SwiftUI

struct ContentView: View {

    // WorkoutStore uses @Observable, so @State is the right wrapper here.
    @State private var store = WorkoutStore()

    // PhoneSessionManager uses ObservableObject/Published (it inherits NSObject
    // for WCSessionDelegate), so we use @StateObject.
    @StateObject private var watchSession = PhoneSessionManager()

    private let healthKit = HealthKitManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    repCounterCard
                    connectionStatusBar
                    debugControlPanel
                    if store.isWorkoutActive { activeWorkoutCard }
                    if !store.completedSessions.isEmpty { pastWorkoutsSection }

                }
                .padding()
            }
            .navigationTitle("Hello Coach")
            // Request HealthKit access once at launch
            .task { try? await healthKit.requestAuthorization() }
            // Watch started or stopped a workout
            .onChange(of: watchSession.isWatchWorkoutActive) { _, active in
                handleWorkoutToggle(active: active)
            }
            // Mirror live reps from watch into store
            .onChange(of: watchSession.repCount) { _, count in
                store.updateRepCount(count)
            }
        }
    }

    // MARK: - Subviews

    /// Large animated rep counter — the hero element of the screen.
    private var repCounterCard: some View {
        VStack(spacing: 6) {
            Text("LIVE REPS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(2)

            Text("\(watchSession.repCount)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: watchSession.repCount)

            Text("Bicep Curl")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
    }

    /// Small indicator showing watch reachability and recording status.
    private var connectionStatusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(watchSession.isWatchReachable ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(watchSession.isWatchReachable ? "Apple Watch connected" : "Apple Watch not reachable")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if store.isWorkoutActive {
                Label("Recording", systemImage: "record.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
    }

    /// Shows stats for the workout currently in progress.
    private var activeWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Active Workout", systemImage: "figure.strengthtraining.traditional")
                .font(.headline)

            HStack(spacing: 0) {
                StatCell(label: "Reps", value: "\(store.liveRepCount)")
                Divider().frame(height: 36)
                StatCell(label: "Sets", value: "\(max(1, store.currentSession?.setCount ?? 1))")
                Divider().frame(height: 36)
                StatCell(label: "Exercise", value: "Bicep Curl")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    /// List of all finished workout sessions.
    private var pastWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Past Workouts")
                .font(.headline)

            ForEach(store.completedSessions.reversed()) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.startTime, format: .dateTime.month().day().hour().minute())
                            .font(.subheadline.weight(.medium))
                        Text("Duration: \(session.formattedDuration)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(session.totalReps) reps")
                            .font(.subheadline.weight(.semibold))
                        Text("\(session.setCount) set\(session.setCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                if session.id != store.completedSessions.first?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Debug Panel

    /// Simulates Apple Watch input so you can test without a physical watch.
    private var debugControlPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundStyle(.orange)
                Text("Debug — Simulate Watch")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Spacer()
            }

            HStack(spacing: 10) {
                // Start workout
                Button {
                    watchSession.debugSimulateWorkoutState(active: true)
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(watchSession.isWatchWorkoutActive ? Color.gray : Color.green,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(watchSession.isWatchWorkoutActive)
                .buttonStyle(.plain)

                // Add one rep
                Button {
                    watchSession.debugSimulateRep()
                } label: {
                    Label("+1 Rep", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(watchSession.isWatchWorkoutActive ? Color.blue : Color.gray,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!watchSession.isWatchWorkoutActive)
                .buttonStyle(.plain)

                // Stop workout
                Button {
                    watchSession.debugSimulateWorkoutState(active: false)
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(watchSession.isWatchWorkoutActive ? Color.red : Color.gray,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!watchSession.isWatchWorkoutActive)
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Actions

    private func handleWorkoutToggle(active: Bool) {
        if active {
            store.startWorkout()
        } else if store.isWorkoutActive {
            store.endWorkout()
            // Save the session that just ended to HealthKit
            guard let lastSession = store.completedSessions.last else { return }
            Task {
                do {
                    try await healthKit.saveWorkout(session: lastSession)
                } catch {
                    print("[ContentView] HealthKit save failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Helper Views

/// A single labelled statistic cell used inside cards.
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
    ContentView()
}

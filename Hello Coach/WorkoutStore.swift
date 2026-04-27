//
//  WorkoutStore.swift
//  Hello Coach
//
//  Data models and in-memory store for workout sessions.
//

import Foundation
import Observation

// MARK: - Models

/// A single set of repetitions within a workout.
struct RepSet: Identifiable {
    let id = UUID()
    let reps: Int
    let timestamp: Date
}

/// A complete workout session containing one or more sets.
struct WorkoutSession: Identifiable {
    let id = UUID()
    var sets: [RepSet] = []
    let startTime: Date
    var endTime: Date?

    var totalReps: Int { sets.reduce(0) { $0 + $1.reps } }
    var setCount: Int { sets.count }

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        guard let d = duration else { return "--" }
        let minutes = Int(d) / 60
        let seconds = Int(d) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Store

/// Holds all workout state for the iPhone app.
/// Kept simple and in-memory — no persistence layer needed for a starter.
@Observable
class WorkoutStore {
    var currentSession: WorkoutSession?
    var completedSessions: [WorkoutSession] = []

    /// Live rep count mirrored from the Apple Watch.
    var liveRepCount: Int = 0
    var isWorkoutActive: Bool = false

    func startWorkout() {
        currentSession = WorkoutSession(startTime: Date())
        liveRepCount = 0
        isWorkoutActive = true
        print("[WorkoutStore] Workout started")
    }

    func endWorkout() {
        guard isWorkoutActive else { return }
        currentSession?.endTime = Date()

        // Record the final rep count as the last set
        if liveRepCount > 0 {
            currentSession?.sets.append(RepSet(reps: liveRepCount, timestamp: Date()))
        }

        if let session = currentSession {
            completedSessions.append(session)
            print("[WorkoutStore] Workout ended — Reps: \(session.totalReps), Sets: \(session.setCount), Duration: \(session.formattedDuration)")
        }

        currentSession = nil
        isWorkoutActive = false
        liveRepCount = 0
    }

    func updateRepCount(_ count: Int) {
        liveRepCount = count
    }
}

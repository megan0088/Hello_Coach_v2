//
//  HealthKitManager.swift
//  Hello Coach
//
//  Handles HealthKit authorization and saving workout data.
//

import HealthKit
import Foundation

class HealthKitManager {

    private let store = HKHealthStore()

    // MARK: - Authorization

    /// Request write access to workout data.
    /// Call this once at app launch (usually in .task modifier on ContentView).
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[HealthKit] Not available on this device")
            return
        }

        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]

        try await store.requestAuthorization(toShare: typesToShare, read: [])
        print("[HealthKit] Authorization granted")
    }

    // MARK: - Save Workout

    /// Save a completed WorkoutSession to HealthKit as a Traditional Strength Training workout.
    /// Attaches reps, sets, and exercise type as metadata.
    func saveWorkout(session: WorkoutSession) async throws {
        guard let endTime = session.endTime else {
            print("[HealthKit] Skipping save — no end time on session")
            return
        }

        // Build the workout configuration
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())

        // Collect data between start and end times
        try await builder.beginCollection(at: session.startTime)
        try await builder.endCollection(at: endTime)

        // Attach custom metadata: reps, sets, exercise name
        let metadata: [String: Any] = [
            HKMetadataKeyExternalUUID: session.id.uuidString,
            "totalReps": session.totalReps,
            "totalSets": session.totalSets,
            "sessionType": session.type.rawValue,
            "exercises": session.exerciseSummary
        ]
        try await builder.addMetadata(metadata)

        // Finalize and save to the HealthKit store
        if let workout = try await builder.finishWorkout() {
            print("[HealthKit] Saved workout — Reps: \(session.totalReps), Sets: \(session.totalSets), ID: \(workout.uuid)")
        } else {
            print("[HealthKit] Workout saved (no workout object returned)")
        }
    }
}

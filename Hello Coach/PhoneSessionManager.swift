//
//  PhoneSessionManager.swift
//  Hello Coach
//
//  Menerima semua payload dari Apple Watch via WatchConnectivity.
//
//  Protocol payload menggunakan key "action":
//    sessionType      → user memilih Push/Pull Day di Watch
//    exerciseSelected → user memilih exercise + berat
//    setCompleted     → satu set selesai
//    repCount         → live update rep count
//    workoutEnded     → user mengakhiri workout
//
//  Swift 6.2 note: SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor, jadi class ini
//  adalah @MainActor. WCSession callback datang dari background thread —
//  semua delegate method ditandai `nonisolated` dan hop ke MainActor via Task.
//

import WatchConnectivity
import Combine
import Foundation

@MainActor
class PhoneSessionManager: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var repCount: Int = 0
    @Published var isWatchWorkoutActive: Bool = false
    @Published var isWatchReachable: Bool = false

    // MARK: - Callbacks (set by ContentView to wire into WorkoutStore)

    var onSessionType: ((ExerciseCategory) -> Void)?
    var onExerciseSelected: ((Exercise, Double) -> Void)?
    var onSetCompleted: ((Exercise, Double, Int) -> Void)?
    var onRepCountUpdated: ((Int) -> Void)?
    var onWorkoutEnded: (() -> Void)?

    // MARK: - Init

    override init() {
        super.init()
        guard WCSession.isSupported() else {
            print("[PhoneSession] WatchConnectivity not supported")
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
        print("[PhoneSession] WCSession activating…")
    }
}

// MARK: - WCSessionDelegate

extension PhoneSessionManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("[PhoneSession] Activation error: \(error.localizedDescription)")
        } else {
            print("[PhoneSession] Activated — state: \(activationState.rawValue)")
        }
        Task { @MainActor in self.isWatchReachable = session.isReachable }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in self.isWatchReachable = reachable }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.handlePayload(message) }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in self.handlePayload(applicationContext) }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        Task { @MainActor in self.handlePayload(userInfo) }
    }
}

// MARK: - Payload Handler

private extension PhoneSessionManager {

    func handlePayload(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else {
            // Legacy fallback (tanpa "action" key)
            if let count = payload["repCount"] as? Int { repCount = count }
            if let active = payload["workoutActive"] as? Bool { isWatchWorkoutActive = active }
            return
        }

        switch action {

        case "sessionType":
            guard let typeStr = payload["type"] as? String,
                  let type = ExerciseCategory(rawValue: typeStr) else { return }
            isWatchWorkoutActive = true
            onSessionType?(type)
            print("[PhoneSession] sessionType → \(typeStr)")

        case "exerciseSelected":
            guard let exerciseStr = payload["exercise"] as? String,
                  let exercise = Exercise(rawValue: exerciseStr),
                  let weight = payload["weightKg"] as? Double else { return }
            onExerciseSelected?(exercise, weight)
            print("[PhoneSession] exerciseSelected → \(exerciseStr) @ \(weight)kg")

        case "setCompleted":
            guard let exerciseStr = payload["exercise"] as? String,
                  let exercise = Exercise(rawValue: exerciseStr),
                  let weight = payload["weightKg"] as? Double,
                  let reps = payload["reps"] as? Int else { return }
            repCount = reps
            onSetCompleted?(exercise, weight, reps)
            print("[PhoneSession] setCompleted → \(reps) reps × \(weight)kg [\(exerciseStr)]")

        case "repCount":
            guard let count = payload["repCount"] as? Int else { return }
            repCount = count
            onRepCountUpdated?(count)

        case "workoutEnded":
            isWatchWorkoutActive = false
            repCount = 0
            onWorkoutEnded?()
            print("[PhoneSession] workoutEnded")

        default:
            print("[PhoneSession] Unknown action: \(action)")
        }
    }
}

// MARK: - Debug Simulation

extension PhoneSessionManager {

    func debugSimulateSessionType(_ type: ExerciseCategory) {
        isWatchWorkoutActive = true
        onSessionType?(type)
        print("[PhoneSession][DEBUG] sessionType → \(type.rawValue)")
    }

    func debugSimulateExercise(_ exercise: Exercise, weight: Double) {
        onExerciseSelected?(exercise, weight)
        print("[PhoneSession][DEBUG] exerciseSelected → \(exercise.rawValue) @ \(weight)kg")
    }

    func debugSimulateRep() {
        repCount += 1
        onRepCountUpdated?(repCount)
        print("[PhoneSession][DEBUG] rep → \(repCount)")
    }

    func debugSimulateSetCompleted(exercise: Exercise, weight: Double) {
        onSetCompleted?(exercise, weight, repCount)
        print("[PhoneSession][DEBUG] setCompleted → \(repCount) reps")
    }

    func debugSimulateWorkoutEnded() {
        isWatchWorkoutActive = false
        repCount = 0
        onWorkoutEnded?()
        print("[PhoneSession][DEBUG] workoutEnded")
    }
}

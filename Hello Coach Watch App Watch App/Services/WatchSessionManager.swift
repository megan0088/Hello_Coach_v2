import Foundation
import WatchConnectivity

// MARK: - WatchSessionManager
//
// Singleton yang mengirim semua payload dari Watch ke iPhone.
// Payload key "action" menentukan jenis event:
//   sessionType      → user memilih Push/Pull Day
//   exerciseSelected → user memilih exercise + berat
//   setCompleted     → satu set selesai (reps + weight)
//   repCount         → live update rep count saat latihan
//   workoutEnded     → user mengakhiri workout
//

@MainActor
class WatchSessionManager: NSObject {

    static let shared = WatchSessionManager()

    private let session: WCSession

    private override init() {
        session = .default
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Public Send Methods

    func sendSessionType(_ type: ExerciseCategory) {
        send(["action": "sessionType", "type": type.rawValue])
    }

    func sendExerciseSelected(_ exercise: Exercise, weightKg: Double) {
        saveLastWeight(weightKg, for: exercise)
        send([
            "action": "exerciseSelected",
            "exercise": exercise.rawValue,
            "weightKg": weightKg
        ])
    }

    func sendSetCompleted(exercise: Exercise, weightKg: Double, reps: Int) {
        send([
            "action": "setCompleted",
            "exercise": exercise.rawValue,
            "weightKg": weightKg,
            "reps": reps
        ])
    }

    func sendRepCount(_ count: Int) {
        send(["action": "repCount", "repCount": count])
    }

    func sendWorkoutEnded() {
        send(["action": "workoutEnded"])
    }

    // MARK: - Last Used Weight (Watch-side UserDefaults)

    func lastWeight(for exercise: Exercise) -> Double {
        let dict = UserDefaults.standard.dictionary(forKey: "watchLastWeight") as? [String: Double] ?? [:]
        return dict[exercise.rawValue] ?? 0
    }

    private func saveLastWeight(_ weight: Double, for exercise: Exercise) {
        var dict = UserDefaults.standard.dictionary(forKey: "watchLastWeight") as? [String: Double] ?? [:]
        dict[exercise.rawValue] = weight
        UserDefaults.standard.set(dict, forKey: "watchLastWeight")
    }

    // MARK: - Transport

    private func send(_ payload: [String: Any]) {
        guard session.activationState == .activated else { return }
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak self] _ in
                self?.session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any]) {}

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        replyHandler([:])
    }
}

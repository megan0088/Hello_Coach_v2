//
//  PhoneSessionManager.swift
//  Hello Coach
//
//  Receives rep count and workout state from the Apple Watch via WatchConnectivity.
//
//  Swift 6.2 note: With SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor the whole class
//  is @MainActor. WCSession delivers delegate callbacks on its own background thread,
//  so delegate methods are marked `nonisolated` and hop back to MainActor via Task.
//

import WatchConnectivity
import Combine
import Foundation

@MainActor
class PhoneSessionManager: NSObject, ObservableObject {

    @Published var repCount: Int = 0
    @Published var isWatchWorkoutActive: Bool = false
    @Published var isWatchReachable: Bool = false

    override init() {
        super.init()
        guard WCSession.isSupported() else {
            print("[PhoneSession] WatchConnectivity not supported on this device")
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
        print("[PhoneSession] WCSession activating…")
    }
}

// MARK: - WCSessionDelegate
// Conformance is in an extension so we can mark individual methods `nonisolated`
// without affecting the rest of the @MainActor class.

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
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("[PhoneSession] Session inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Required on iOS: re-activate after the user switches Apple Watch.
        WCSession.default.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        print("[PhoneSession] Reachability: \(reachable)")
        Task { @MainActor in
            self.isWatchReachable = reachable
        }
    }

    /// Real-time message from the Watch (watch app in foreground, phone nearby).
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handlePayload(message)
        }
    }

    /// Queued context update (background / watch not immediately reachable).
    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            self.handlePayload(applicationContext)
        }
    }

    /// transferUserInfo — lebih andal dari applicationContext di simulator.
    /// Dijamin terkirim meski app tidak aktif, dan tidak overwrite data sebelumnya.
    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        print("[PhoneSession] Terima userInfo: \(userInfo)")
        Task { @MainActor in
            self.handlePayload(userInfo)
        }
    }
}

// MARK: - Debug Simulation (no Watch needed)

extension PhoneSessionManager {

    /// Simulate the Watch adding one rep — for testing without a physical Apple Watch.
    func debugSimulateRep() {
        repCount += 1
        print("[PhoneSession][DEBUG] Simulated rep → \(repCount)")
    }

    /// Simulate the Watch starting or stopping a workout.
    func debugSimulateWorkoutState(active: Bool) {
        isWatchWorkoutActive = active
        if !active { repCount = 0 }
        print("[PhoneSession][DEBUG] Simulated workoutActive → \(active)")
    }
}

// MARK: - Private

private extension PhoneSessionManager {

    func handlePayload(_ payload: [String: Any]) {
        if let count = payload["repCount"] as? Int {
            repCount = count
            print("[PhoneSession] repCount → \(count)")
        }
        if let active = payload["workoutActive"] as? Bool {
            isWatchWorkoutActive = active
            print("[PhoneSession] workoutActive → \(active)")
        }
    }
}

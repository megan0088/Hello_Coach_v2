//
//  WatchSessionManager.swift
//  Hello Coach Watch App
//
//  Kirim rep count dan status workout ke iPhone via WatchConnectivity.
//  Watch hanya bertugas sebagai "sensor input" — semua data disimpan di iPhone.
//

import WatchConnectivity
import Foundation

@MainActor
class WatchSessionManager: NSObject {

    static let shared = WatchSessionManager()

    private override init() {
        super.init()
        guard WCSession.isSupported() else {
            print("[WatchSession] WCSession tidak tersedia")
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
        print("[WatchSession] Aktivasi WCSession...")
    }

    // MARK: - Kirim ke iPhone

    /// Kirim jumlah rep terkini ke iPhone secara real-time.
    func sendRepCount(_ count: Int) {
        send(["repCount": count])
    }

    /// Beritahu iPhone bahwa workout dimulai (true) atau selesai (false).
    func sendWorkoutState(active: Bool) {
        send(["workoutActive": active])
    }

    // MARK: - Private

    private func send(_ payload: [String: Any]) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            print("[WatchSession] Belum aktif, skip kirim")
            return
        }

        if session.isReachable {
            // Opsi 1 — Real-time (iPhone app aktif di foreground)
            session.sendMessage(payload, replyHandler: nil) { error in
                print("[WatchSession] sendMessage gagal: \(error.localizedDescription), coba transferUserInfo...")
                session.transferUserInfo(payload)
            }
        } else {
            // Opsi 2 — transferUserInfo: dijamin terkirim meski tidak reachable.
            // Lebih andal dari updateApplicationContext di simulator.
            session.transferUserInfo(payload)
            print("[WatchSession] Tidak reachable — pakai transferUserInfo: \(payload)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {

    // Pada watchOS hanya method ini yang wajib diimplementasi
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("[WatchSession] Error aktivasi: \(error.localizedDescription)")
        } else {
            print("[WatchSession] Aktif — state: \(activationState.rawValue)")
        }
    }
}

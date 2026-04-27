//
//  ContentView.swift
//  Hello Coach Watch App
//
//  UI di layar Apple Watch:
//  - Tombol Start / Stop workout
//  - Counter rep yang update real-time
//  - Debug nilai Y accelerometer
//
//  Watch HANYA mengumpulkan input — semua data disimpan di iPhone.
//

import SwiftUI

struct ContentView: View {

    @State private var motion = MotionManager()
    private let watchSession = WatchSessionManager.shared

    /// Nilai crown — dipakai untuk deteksi perubahan rotasi
    @State private var crownValue: Double = 0.0
    @State private var lastCrownStep: Int = 0

    var body: some View {
        VStack(spacing: 10) {

            // ── Rep Counter ──────────────────────────────────────────
            VStack(spacing: 2) {
                Text("\(motion.repCount)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(motion.isTracking ? .blue : .secondary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: motion.repCount)

                Text("REPS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(2)
            }

            // ── Tombol Start / Stop ──────────────────────────────────
            Button(action: toggleWorkout) {
                Text(motion.isTracking ? "Stop" : "Start")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        motion.isTracking ? Color.red : Color.green,
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)

            // ── Tombol manual rep (untuk simulator / testing) ────────
            if motion.isTracking {
                Button {
                    motion.simulateRep()
                    watchSession.sendRepCount(motion.repCount)
                } label: {
                    Label("+1 Rep", systemImage: "plus.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.8), in: Capsule())
                }
                .buttonStyle(.plain)

                // Debug sensor — pakai ini untuk tuning threshold
                VStack(spacing: 2) {
                    Text("G.Y: \(motion.debugGravityY, specifier: "%.3f")")
                    Text("Peak: \(motion.debugPeak, specifier: "%.3f")")
                    Text("Phase: \(motion.debugPhase)")
                        .foregroundStyle(motion.debugPhase == "flexed" ? Color.green : Color.secondary)
                }
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        // Digital Crown: putar untuk tambah rep (berguna di simulator & testing)
        .digitalCrownRotation(
            $crownValue,
            from: 0,
            through: 9999,
            by: 1,
            sensitivity: .medium,
            isContinuous: true
        )
        .focusable()
        .onChange(of: crownValue) { _, newValue in
            guard motion.isTracking else { return }
            let step = Int(newValue)
            if step > lastCrownStep {
                let added = step - lastCrownStep
                for _ in 0..<added {
                    motion.simulateRep()
                    watchSession.sendRepCount(motion.repCount)
                }
            }
            lastCrownStep = step
        }
        // Setiap rep baru → kirim ke iPhone langsung
        .onChange(of: motion.repCount) { _, newCount in
            watchSession.sendRepCount(newCount)
        }
    }

    // MARK: - Actions

    private func toggleWorkout() {
        if motion.isTracking {
            // Hentikan workout
            motion.stopTracking()
            watchSession.sendWorkoutState(active: false)
            watchSession.sendRepCount(0)  // Reset counter di iPhone
        } else {
            // Mulai workout
            motion.startTracking()
            watchSession.sendWorkoutState(active: true)
        }
    }
}

#Preview {
    ContentView()
}

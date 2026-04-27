//
//  MotionManager.swift
//  Hello Coach Watch App
//
//  Algoritma berdasarkan referensi:
//  github.com/aparande/workout-tracker
//
//  Pendekatan:
//  1. Gunakan gravity.y — langsung encode sudut lengan (bukan percepatan)
//  2. DifferenceFilter — hitung turunan sinyal (kapan lengan bergerak)
//  3. MaximumFilter — sliding window max untuk haluskan noise
//  4. State machine .rest ↔ .flexed — hitung rep saat arm kembali ke bawah
//
//  Kenapa gravity lebih baik dari userAcceleration:
//  • userAcceleration = gaya yang dirasakan (dipengaruhi kecepatan gerakan)
//  • gravity = arah gravitasi relatif terhadap Watch = POSISI LENGAN langsung
//  • Tidak peduli seberapa cepat atau lambat gerakan → lebih akurat
//

import CoreMotion
import Observation

// MARK: - Filters

/// Hitung turunan sinyal: y[n] = direction × (x[n] - x[n-1])
/// Positif = sinyal naik, Negatif = sinyal turun
private struct DifferenceFilter {
    private var prevValue: Double = 0
    private var sampleCount: Int = 0
    let direction: Double  // +1 atau -1

    init(direction: Double) { self.direction = direction }

    var hasBoundaryEffect: Bool { sampleCount <= 1 }

    mutating func filter(_ x: Double) -> Double {
        let out = direction * (x - prevValue)
        prevValue = x
        sampleCount += 1
        return out
    }
}

/// Sliding window maximum — ambil nilai dengan abs terbesar dalam window
/// Window 25 sampel @ 50Hz = 0.5 detik → haluskan spike noise
private struct MaximumFilter {
    private var window: [Double]
    private var absWindow: [Double]
    private var sampleCount: Int = 0

    var hasBoundaryEffect: Bool { sampleCount <= window.count }

    init(windowSize: Int = 25) {
        window = Array(repeating: 0, count: windowSize)
        absWindow = Array(repeating: 0, count: windowSize)
    }

    mutating func filter(_ x: Double) -> Double {
        window.removeFirst()
        absWindow.removeFirst()
        window.append(x)
        absWindow.append(abs(x))
        sampleCount += 1

        // Ambil index nilai absolut terbesar, kembalikan nilai aslinya (dengan tanda)
        guard let maxIdx = absWindow.indices.max(by: { absWindow[$0] < absWindow[$1] }) else { return 0 }
        return window[maxIdx]
    }
}

// MARK: - MotionManager

@Observable
class MotionManager {

    // MARK: - UI Properties

    var repCount: Int = 0
    var isTracking: Bool = false

    /// Debug — tampilkan di layar Watch untuk monitoring
    var debugGravityY: Double = 0.0
    var debugPeak: Double = 0.0
    var debugPhase: String = "rest"

    // MARK: - Private

    private let cm = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.hellocoach.motion"
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInteractive
        return q
    }()

    // MARK: - Kontrol

    func startTracking() {
        repCount = 0
        isTracking = true

        guard cm.isDeviceMotionAvailable else {
            print("[Motion] DeviceMotion tidak tersedia (simulator mode)")
            return
        }

        cm.deviceMotionUpdateInterval = 1.0 / 50.0  // 50 Hz

        // ── Parameter ─────────────────────────────────────────────────
        // threshold: seberapa besar perubahan gravity untuk dianggap gerakan
        // Gravity berubah 0~1G → turunan per sampel biasanya 0.01~0.05
        // Naikkan jika terlalu sensitif, turunkan jika sering miss
        let threshold = 0.012

        // direction = -1: arm naik → gravity.y turun → output positif
        var diffFilter  = DifferenceFilter(direction: -1)
        var maxFilter   = MaximumFilter(windowSize: 25)
        var phase       = "rest"   // "rest" | "flexed"
        var sampleIdx   = 0

        cm.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }

            sampleIdx += 1

            // ── Step 1: Ambil gravity.y ─────────────────────────────────
            // gravity.y ≈ -1.0 saat lengan lurus ke bawah
            // gravity.y ≈  0.0 saat lengan horizontal (fully curled)
            let gravityY = motion.gravity.y

            // ── Step 2: DifferenceFilter ────────────────────────────────
            // Hitung turunan: menangkap kapan lengan mulai bergerak
            let diff = diffFilter.filter(gravityY)
            guard !diffFilter.hasBoundaryEffect else { return }

            // ── Step 3: MaximumFilter ───────────────────────────────────
            // Sliding window max: haluskan turunan dari noise spike
            let peak = maxFilter.filter(diff)
            guard !maxFilter.hasBoundaryEffect else { return }

            // ── Step 4: State Machine ───────────────────────────────────
            //
            //   peak < -threshold → lengan NAIK  → phase = "flexed"
            //   peak > +threshold → lengan TURUN → phase = "rest"
            //
            //   Transisi: flexed → rest = 1 rep selesai ✓
            //
            var counted = false
            if abs(peak) >= threshold {
                let newPhase = peak > 0 ? "rest" : "flexed"

                if newPhase == "rest" && phase == "flexed" {
                    // Lengan kembali ke posisi bawah setelah curl → rep!
                    counted = true
                }
                phase = newPhase
            }

            // ── Step 5: Update UI (10x/detik) ───────────────────────────
            if counted {
                Task { @MainActor in
                    self.repCount += 1
                    print("[Motion] ✓ Rep #\(self.repCount) — peak: \(String(format: "%.3f", peak))")
                }
            } else if sampleIdx % 5 == 0 {
                let g = gravityY
                let p = peak
                let ph = phase
                Task { @MainActor in
                    self.debugGravityY = g
                    self.debugPeak = p
                    self.debugPhase = ph
                }
            }
        }

        print("[Motion] Mulai — Gravity-based rep detection, threshold: \(threshold)")
    }

    func stopTracking() {
        cm.stopDeviceMotionUpdates()
        isTracking = false
        print("[Motion] Berhenti — Total rep: \(repCount)")
    }

    /// Simulasi rep manual — untuk Watch Simulator.
    func simulateRep() {
        repCount += 1
        print("[Motion][SIM] Rep #\(repCount)")
    }
}

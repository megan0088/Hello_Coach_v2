import Foundation
import SwiftData

@Model
final class RepSet {
    var id: UUID = UUID()
    var reps: Int
    var weightKg: Double
    var timestamp: Date

    var volume: Double { Double(reps) * weightKg }

    init(reps: Int, weightKg: Double, timestamp: Date = Date()) {
        self.reps = reps
        self.weightKg = weightKg
        self.timestamp = timestamp
    }
}

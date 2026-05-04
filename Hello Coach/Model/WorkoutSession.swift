import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var typeRawValue: String
    @Relationship(deleteRule: .cascade) var entries: [ExerciseEntry] = []
    var startTime: Date
    var endTime: Date?

    var type: ExerciseCategory { ExerciseCategory(rawValue: typeRawValue) ?? .push }
    var totalReps: Int      { entries.reduce(0) { $0 + $1.totalReps } }
    var totalVolume: Double { entries.reduce(0) { $0 + $1.totalVolume } }
    var totalSets: Int      { entries.reduce(0) { $0 + $1.setCount } }

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        guard let d = duration else { return "--" }
        let m = Int(d) / 60
        let s = Int(d) % 60
        return String(format: "%d:%02d", m, s)
    }

    var exerciseSummary: String {
        entries.map { $0.exercise.displayName }.joined(separator: ", ")
    }

    init(type: ExerciseCategory) {
        self.typeRawValue = type.rawValue
        self.startTime = Date()
    }
}

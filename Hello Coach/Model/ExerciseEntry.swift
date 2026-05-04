import Foundation
import SwiftData

@Model
final class ExerciseEntry {
    var id: UUID = UUID()
    var exerciseRawValue: String
    @Relationship(deleteRule: .cascade) var sets: [RepSet] = []

    var exercise: Exercise { Exercise(rawValue: exerciseRawValue) ?? .benchPress }
    var totalReps: Int      { sets.reduce(0) { $0 + $1.reps } }
    var totalVolume: Double { sets.reduce(0) { $0 + $1.volume } }
    var setCount: Int       { sets.count }
    var bestSet: RepSet?    { sets.max(by: { $0.volume < $1.volume }) }

    init(exercise: Exercise) {
        self.exerciseRawValue = exercise.rawValue
    }
}

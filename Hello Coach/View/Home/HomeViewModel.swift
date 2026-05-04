import Foundation
import Observation

@Observable
final class HomeViewModel {
    private let store: WorkoutStore

    init(store: WorkoutStore) { self.store = store }

    var currentStreak: Int              { store.currentStreak }
    var lastSession: WorkoutSession?    { store.lastSession }
    var isWorkoutActive: Bool           { store.isWorkoutActive }
    var currentSession: WorkoutSession? { store.currentSession }
    var liveRepCount: Int               { store.liveRepCount }
    var activeExercise: Exercise?       { store.activeExercise }
    var activeWeightKg: Double          { store.activeWeightKg }
    var trackedExercises: [Exercise]    { store.trackedExercises }

    func personalRecord(for exercise: Exercise) -> RepSet? {
        store.personalRecord(for: exercise)
    }

    func weeklyVolume() -> [(day: Date, volume: Double)] {
        store.weeklyVolume()
    }
}

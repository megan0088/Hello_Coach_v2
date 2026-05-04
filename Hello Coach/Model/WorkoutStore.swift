import Foundation
import Observation
import SwiftData

// MARK: - WorkoutStore

@Observable
class WorkoutStore {

    // MARK: Active session state

    var currentSession: WorkoutSession?
    var isWorkoutActive: Bool = false
    var activeExercise: Exercise?
    var activeWeightKg: Double = 0
    var liveRepCount: Int = 0

    // MARK: History

    private(set) var completedSessions: [WorkoutSession] = []

    // MARK: Last used weight per exercise

    private(set) var lastUsedWeight: [String: Double] = {
        (UserDefaults.standard.dictionary(forKey: "lastUsedWeight") as? [String: Double]) ?? [:]
    }()

    // MARK: SwiftData

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchSessions()
    }

    private func fetchSessions() {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endTime != nil },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        completedSessions = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Session lifecycle

    func startWorkout(type: ExerciseCategory) {
        let session = WorkoutSession(type: type)
        modelContext.insert(session)
        currentSession = session
        liveRepCount = 0
        isWorkoutActive = true
    }

    func endWorkout() {
        guard isWorkoutActive else { return }
        finalizeCurrentSet()
        currentSession?.endTime = Date()
        try? modelContext.save()
        fetchSessions()
        currentSession = nil
        isWorkoutActive = false
        liveRepCount = 0
        activeExercise = nil
    }

    // MARK: - Exercise selection

    func selectExercise(_ exercise: Exercise, weightKg: Double) {
        saveLastUsedWeight(weightKg, for: exercise)
        activeExercise = exercise
        activeWeightKg = weightKg
        liveRepCount = 0

        if currentSession?.entries.last?.exercise != exercise {
            let entry = ExerciseEntry(exercise: exercise)
            modelContext.insert(entry)
            currentSession?.entries.append(entry)
        }
    }

    // MARK: - Set management

    func updateRepCount(_ count: Int) {
        liveRepCount = count
    }

    func finalizeCurrentSet() {
        guard let exercise = activeExercise, liveRepCount > 0 else { return }
        let newSet = RepSet(reps: liveRepCount, weightKg: activeWeightKg)
        modelContext.insert(newSet)
        if let idx = currentSession?.entries.lastIndex(where: { $0.exercise == exercise }) {
            currentSession?.entries[idx].sets.append(newSet)
        }
        liveRepCount = 0
    }

    // MARK: - Weight persistence

    func lastWeight(for exercise: Exercise) -> Double {
        lastUsedWeight[exercise.rawValue] ?? 0
    }

    private func saveLastUsedWeight(_ weight: Double, for exercise: Exercise) {
        lastUsedWeight[exercise.rawValue] = weight
        UserDefaults.standard.set(lastUsedWeight, forKey: "lastUsedWeight")
    }

    var lastSession: WorkoutSession? { completedSessions.last }

    // MARK: - Analytics: Streak

    var currentStreak: Int {
        let calendar = Calendar.current
        let days = Set(completedSessions.map { calendar.startOfDay(for: $0.startTime) })
            .sorted(by: >)
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var expected = calendar.startOfDay(for: Date())

        if !days.contains(expected) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: expected),
                  days.contains(yesterday) else { return 0 }
            expected = yesterday
        }

        for day in days.sorted(by: >) {
            if day == expected {
                streak += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected)!
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Analytics: Personal Records

    func personalRecord(for exercise: Exercise) -> RepSet? {
        completedSessions
            .flatMap { $0.entries }
            .filter { $0.exercise == exercise }
            .flatMap { $0.sets }
            .max(by: { $0.volume < $1.volume })
    }

    var trackedExercises: [Exercise] {
        var seen: [Exercise] = []
        for session in completedSessions.reversed() {
            for entry in session.entries where !seen.contains(entry.exercise) {
                seen.append(entry.exercise)
            }
        }
        return seen
    }

    // MARK: - Analytics: Weekly Volume

    func weeklyVolume() -> [(day: Date, volume: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { offset -> (Date, Double) in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let vol = completedSessions
                .filter { calendar.startOfDay(for: $0.startTime) == day }
                .reduce(0.0) { $0 + $1.totalVolume }
            return (day, vol)
        }.reversed()
    }

    // MARK: - Analytics: Muscle Focus

    func muscleFocus(in sessions: [WorkoutSession]? = nil) -> [(muscle: MuscleGroup, percentage: Double)] {
        let target = sessions ?? completedSessions
        var counts: [MuscleGroup: Double] = [:]

        for session in target {
            for entry in session.entries {
                for muscle in entry.exercise.primaryMuscles {
                    counts[muscle, default: 0] += 1.0
                }
                for muscle in entry.exercise.secondaryMuscles {
                    counts[muscle, default: 0] += 0.5
                }
            }
        }

        let total = counts.values.reduce(0, +)
        guard total > 0 else { return [] }

        return counts
            .map { (muscle: $0.key, percentage: ($0.value / total) * 100) }
            .sorted { $0.percentage > $1.percentage }
    }

    // MARK: - Analytics: Progress per Exercise

    func history(for exercise: Exercise) -> [(date: Date, totalVolume: Double, totalReps: Int)] {
        completedSessions
            .filter { $0.entries.contains(where: { $0.exercise == exercise }) }
            .compactMap { session -> (Date, Double, Int)? in
                let entries = session.entries.filter { $0.exercise == exercise }
                let vol = entries.reduce(0) { $0 + $1.totalVolume }
                let reps = entries.reduce(0) { $0 + $1.totalReps }
                return (session.startTime, vol, reps)
            }
            .sorted { $0.0 < $1.0 }
    }

    // MARK: - Calendar

    func sessions(on date: Date) -> [WorkoutSession] {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        return completedSessions.filter {
            calendar.startOfDay(for: $0.startTime) == day
        }
    }

    func hasSession(on date: Date) -> Bool {
        !sessions(on: date).isEmpty
    }
}

// MARK: - Preview Helper

extension WorkoutStore {
    static var preview: WorkoutStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: WorkoutSession.self, ExerciseEntry.self, RepSet.self,
            configurations: config
        )
        return WorkoutStore(modelContext: container.mainContext)
    }
}

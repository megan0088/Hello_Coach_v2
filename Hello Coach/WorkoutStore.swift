import Foundation
import Observation

// MARK: - RepSet

struct RepSet: Identifiable, Codable, Hashable {
    let id: UUID
    let reps: Int
    let weightKg: Double
    let timestamp: Date

    init(reps: Int, weightKg: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.reps = reps
        self.weightKg = weightKg
        self.timestamp = timestamp
    }

    var volume: Double { Double(reps) * weightKg }
}

// MARK: - ExerciseEntry

struct ExerciseEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let exercise: Exercise
    var sets: [RepSet]

    init(exercise: Exercise) {
        self.id = UUID()
        self.exercise = exercise
        self.sets = []
    }

    var totalReps: Int    { sets.reduce(0) { $0 + $1.reps } }
    var totalVolume: Double { sets.reduce(0) { $0 + $1.volume } }
    var setCount: Int     { sets.count }

    /// Best set by volume (reps × weight).
    var bestSet: RepSet?  { sets.max(by: { $0.volume < $1.volume }) }
}

// MARK: - WorkoutSession

struct WorkoutSession: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ExerciseCategory
    var entries: [ExerciseEntry]
    let startTime: Date
    var endTime: Date?

    init(type: ExerciseCategory) {
        self.id = UUID()
        self.type = type
        self.entries = []
        self.startTime = Date()
    }

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

    /// Short summary of exercises performed, e.g. "Bench Press, Lateral Raise"
    var exerciseSummary: String {
        entries.map { $0.exercise.displayName }.joined(separator: ", ")
    }
}

// MARK: - WorkoutStore

@Observable
class WorkoutStore {

    // MARK: Active session state

    var currentSession: WorkoutSession?
    var isWorkoutActive: Bool = false

    /// Exercise currently being performed on the Watch.
    var activeExercise: Exercise?
    /// Weight set for the current exercise.
    var activeWeightKg: Double = 0
    /// Live rep count mirrored from Watch.
    var liveRepCount: Int = 0

    // MARK: History

    var completedSessions: [WorkoutSession] = []

    // MARK: Last used weight per exercise (persisted across launches)

    private(set) var lastUsedWeight: [String: Double] = {
        (UserDefaults.standard.dictionary(forKey: "lastUsedWeight") as? [String: Double]) ?? [:]
    }()

    // MARK: - Session lifecycle

    func startWorkout(type: ExerciseCategory) {
        currentSession = WorkoutSession(type: type)
        liveRepCount = 0
        isWorkoutActive = true
    }

    func endWorkout() {
        guard isWorkoutActive else { return }
        finalizeCurrentSet()
        currentSession?.endTime = Date()
        if let session = currentSession {
            completedSessions.append(session)
        }
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

        // Add a new entry only if this is a different exercise from the last one.
        if currentSession?.entries.last?.exercise != exercise {
            currentSession?.entries.append(ExerciseEntry(exercise: exercise))
        }
    }

    // MARK: - Set management

    func updateRepCount(_ count: Int) {
        liveRepCount = count
    }

    /// Saves current liveRepCount as a completed set and resets the counter.
    func finalizeCurrentSet() {
        guard let exercise = activeExercise, liveRepCount > 0 else { return }
        let newSet = RepSet(reps: liveRepCount, weightKg: activeWeightKg)
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

        // Allow streak to start from yesterday if no session today yet.
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

    /// Best set (by volume) for a given exercise across all history.
    func personalRecord(for exercise: Exercise) -> RepSet? {
        completedSessions
            .flatMap { $0.entries }
            .filter { $0.exercise == exercise }
            .flatMap { $0.sets }
            .max(by: { $0.volume < $1.volume })
    }

    /// All exercises that have at least one recorded set, sorted by most recent.
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

    /// Total volume (reps × kg) grouped by day for the past 7 days.
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

    /// Distribution of muscle groups across given sessions (default: all history).
    /// Primary muscle = 1.0 point, Secondary = 0.5 point.
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

    /// All sets for a given exercise sorted by date, for the progress line chart.
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

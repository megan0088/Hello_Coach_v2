import Foundation
import Observation

@Observable
final class AnalyticsViewModel {
    private let store: WorkoutStore

    var selectedExercise: Exercise?
    var timeRange: TimeRange = .sixMonths

    enum TimeRange: String, CaseIterable {
        case oneMonth    = "1M"
        case threeMonths = "3M"
        case sixMonths   = "6M"
        case oneYear     = "1Y"
        case all         = "ALL"

        var days: Int? {
            switch self {
            case .oneMonth:    return 30
            case .threeMonths: return 90
            case .sixMonths:   return 180
            case .oneYear:     return 365
            case .all:         return nil
            }
        }
    }

    init(store: WorkoutStore) { self.store = store }

    var currentExercise: Exercise {
        selectedExercise ?? store.trackedExercises.first ?? .benchPress
    }

    var filteredHistory: [(date: Date, totalVolume: Double, totalReps: Int)] {
        let history = store.history(for: currentExercise)
        guard let days = timeRange.days else { return history }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return history.filter { $0.date >= cutoff }
    }

    var volumeChangeLabel: String? {
        guard filteredHistory.count >= 2,
              let first = filteredHistory.first?.totalVolume,
              let last  = filteredHistory.last?.totalVolume,
              first > 0 else { return nil }
        let pct = ((last - first) / first) * 100
        return String(format: "%+.0f%%", pct)
    }

    func muscleFocus() -> [(muscle: MuscleGroup, percentage: Double)] {
        store.muscleFocus()
    }

    func weeklyVolume() -> [(day: Date, volume: Double)] {
        store.weeklyVolume()
    }

    var topPerformances: [(date: Date, set: RepSet)] {
        store.completedSessions
            .flatMap { session in
                session.entries
                    .filter { $0.exercise == currentExercise }
                    .flatMap { entry in entry.sets.map { (session.startTime, $0) } }
            }
            .sorted { $0.1.volume > $1.1.volume }
    }

    var trackedExercises: [Exercise] { store.trackedExercises }
}

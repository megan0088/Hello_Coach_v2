import Foundation
import Observation

@Observable
final class CalendarViewModel {
    private let store: WorkoutStore

    var displayedMonth: Date = Date()
    var selectedDate: Date? = nil

    init(store: WorkoutStore) { self.store = store }

    func sessions(on date: Date) -> [WorkoutSession] {
        store.sessions(on: date)
    }

    func hasSession(on date: Date) -> Bool {
        store.hasSession(on: date)
    }
}

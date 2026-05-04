import SwiftUI
import SwiftData

@main
struct Hello_CoachApp: App {
    let container: ModelContainer
    let store: WorkoutStore
    let homeVM: HomeViewModel
    let analyticsVM: AnalyticsViewModel
    let calendarVM: CalendarViewModel

    init() {
        let schema = Schema([WorkoutSession.self, ExerciseEntry.self, RepSet.self])
        let modelConfig = ModelConfiguration(schema: schema)
        container = try! ModelContainer(for: schema, configurations: modelConfig)
        store = WorkoutStore(modelContext: container.mainContext)
        homeVM = HomeViewModel(store: store)
        analyticsVM = AnalyticsViewModel(store: store)
        calendarVM = CalendarViewModel(store: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(store)
                .environment(homeVM)
                .environment(analyticsVM)
                .environment(calendarVM)
        }
    }
}

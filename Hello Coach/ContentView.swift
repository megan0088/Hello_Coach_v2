import SwiftUI

struct ContentView: View {

    @Environment(WorkoutStore.self) private var store
    @StateObject private var watchSession = PhoneSessionManager()
    private let healthKit = HealthKitManager()

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.line.uptrend.xyaxis") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
        }
        .environmentObject(watchSession)
        .task { try? await healthKit.requestAuthorization() }
        .onAppear { wireCallbacks() }
        .onChange(of: watchSession.repCount) { _, count in
            store.updateRepCount(count)
        }
    }

    // MARK: - Wiring

    private func wireCallbacks() {
        watchSession.onSessionType = { type in
            store.startWorkout(type: type)
        }
        watchSession.onExerciseSelected = { exercise, weight in
            store.selectExercise(exercise, weightKg: weight)
        }
        watchSession.onRepCountUpdated = { count in
            store.updateRepCount(count)
        }
        watchSession.onSetCompleted = { _, _, reps in
            store.updateRepCount(reps)
            store.finalizeCurrentSet()
        }
        watchSession.onWorkoutEnded = {
            store.endWorkout()
            guard let lastSession = store.completedSessions.last else { return }
            Task { try? await healthKit.saveWorkout(session: lastSession) }
        }
    }
}

#Preview {
    let store = WorkoutStore.preview
    ContentView()
        .environment(store)
        .environment(HomeViewModel(store: store))
        .environment(AnalyticsViewModel(store: store))
        .environment(CalendarViewModel(store: store))
}

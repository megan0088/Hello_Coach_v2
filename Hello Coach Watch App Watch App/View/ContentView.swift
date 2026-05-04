import SwiftUI

enum WatchFlowStep: Hashable {
    case exercisePicker(ExerciseCategory)
    case weightInput(ExerciseCategory, Exercise)
    case repCounting(ExerciseCategory, Exercise, Double)
    case setComplete(ExerciseCategory, Exercise, Double, Int)
}

struct ContentView: View {
    @State private var path = NavigationPath()
    @State private var motion = MotionManager()
    @State private var setNumber = 0
    private let watchSession = WatchSessionManager.shared

    var body: some View {
        NavigationStack(path: $path) {
            SessionTypeView { type in
                watchSession.sendSessionType(type)
                path.append(WatchFlowStep.exercisePicker(type))
            }
            .navigationDestination(for: WatchFlowStep.self) { step in
                stepView(step)
            }
        }
    }

    @ViewBuilder
    private func stepView(_ step: WatchFlowStep) -> some View {
        switch step {

        case .exercisePicker(let type):
            ExercisePickerView(category: type) { exercise in
                path.append(WatchFlowStep.weightInput(type, exercise))
            }

        case .weightInput(let type, let exercise):
            WeightInputView(
                exercise: exercise,
                initialWeight: watchSession.lastWeight(for: exercise)
            ) { weight in
                watchSession.sendExerciseSelected(exercise, weightKg: weight)
                motion.startTracking()
                path.append(WatchFlowStep.repCounting(type, exercise, weight))
            }

        case .repCounting(let type, let exercise, let weight):
            RepCountingView(exercise: exercise, weight: weight, motion: motion) { reps in
                setNumber += 1
                motion.stopTracking()
                watchSession.sendSetCompleted(exercise: exercise, weightKg: weight, reps: reps)
                path.append(WatchFlowStep.setComplete(type, exercise, weight, reps))
            }

        case .setComplete(let type, let exercise, let weight, let reps):
            SetCompleteView(
                setNumber: setNumber,
                exercise: exercise,
                weight: weight,
                reps: reps,
                onNextSet: {
                    path.removeLast(2)
                },
                onChangeExercise: {
                    path.removeLast(3)
                },
                onEndWorkout: {
                    watchSession.sendWorkoutEnded()
                    setNumber = 0
                    path = NavigationPath()
                }
            )
        }
    }
}

#Preview {
    ContentView()
}

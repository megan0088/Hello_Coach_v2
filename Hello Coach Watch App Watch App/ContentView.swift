import SwiftUI

// MARK: - Navigation Steps

enum WatchFlowStep: Hashable {
    case exercisePicker(ExerciseCategory)
    case weightInput(ExerciseCategory, Exercise)
    case repCounting(ExerciseCategory, Exercise, Double)
    case setComplete(ExerciseCategory, Exercise, Double, Int)
}

// MARK: - Root View

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
                    // Pop setComplete + repCounting → kembali ke weightInput
                    path.removeLast(2)
                },
                onChangeExercise: {
                    // Pop ke exercisePicker
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

// MARK: - Screen 1: Session Type

struct SessionTypeView: View {
    let onSelect: (ExerciseCategory) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Hari Ini")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1)

            Button { onSelect(.push) } label: {
                VStack(spacing: 3) {
                    Text("PUSH")
                        .font(.headline.weight(.bold))
                    Text("Dada · Bahu · Triceps")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Button { onSelect(.pull) } label: {
                VStack(spacing: 3) {
                    Text("PULL")
                        .font(.headline.weight(.bold))
                    Text("Punggung · Bahu · Biceps")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .navigationTitle("Hello Coach")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Screen 2: Exercise Picker

struct ExercisePickerView: View {
    let category: ExerciseCategory
    let onSelect: (Exercise) -> Void

    var body: some View {
        List {
            ForEach(Exercise.grouped(for: category), id: \.subgroup) { group in
                Section(group.subgroup) {
                    ForEach(group.exercises) { exercise in
                        Button {
                            onSelect(exercise)
                        } label: {
                            Text(exercise.displayName)
                                .font(.body)
                        }
                    }
                }
            }
        }
        .listStyle(.carousel)
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Screen 3: Weight Input

struct WeightInputView: View {
    let exercise: Exercise
    let onStart: (Double) -> Void

    @State private var weightKg: Double
    @State private var crownValue: Double
    @FocusState private var crownFocused: Bool

    init(exercise: Exercise, initialWeight: Double, onStart: @escaping (Double) -> Void) {
        self.exercise = exercise
        self.onStart = onStart
        let w = max(0, initialWeight)
        _weightKg = State(initialValue: w)
        _crownValue = State(initialValue: w)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(exercise.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer()

            // Crown rotation attached to the weight display — bukan button,
            // sehingga focus tidak diperebutkan dengan tombol lain.
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", weightKg))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.2), value: weightKg)
                Text("kg")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .focusable()
            .focused($crownFocused)
            .digitalCrownRotation(
                $crownValue,
                from: 0,
                through: 300,
                by: 2.5,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: crownValue) { _, newValue in
                weightKg = newValue
            }

            Text("Putar crown untuk ubah berat")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)

            Spacer()

            Button {
                onStart(weightKg)
            } label: {
                Text("Start Set")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.green, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .onAppear { crownFocused = true }
        .navigationTitle("Berat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Screen 4: Rep Counting

struct RepCountingView: View {
    let exercise: Exercise
    let weight: Double
    var motion: MotionManager
    let onDoneSet: (Int) -> Void

    private let watchSession = WatchSessionManager.shared

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(exercise.displayName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("·")
                Text(String(format: "%.0f kg", weight))
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)

            Spacer()

            Text("\(motion.repCount)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(motion.isTracking ? .blue : .primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.25), value: motion.repCount)

            Text("REPS")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(2)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    motion.simulateRep()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)

                Button {
                    onDoneSet(motion.repCount)
                } label: {
                    Text("Done Set")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(motion.repCount > 0 ? Color.red : Color.gray, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(motion.repCount == 0)
            }
        }
        .padding(.horizontal)
        .onChange(of: motion.repCount) { _, count in
            watchSession.sendRepCount(count)
        }
        .onDisappear {
            if motion.isTracking { motion.stopTracking() }
        }
        .navigationTitle(exercise.subgroup)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Screen 5: Set Complete

struct SetCompleteView: View {
    let setNumber: Int
    let exercise: Exercise
    let weight: Double
    let reps: Int
    let onNextSet: () -> Void
    let onChangeExercise: () -> Void
    let onEndWorkout: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                VStack(spacing: 2) {
                    Label("Set \(setNumber) Done!", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)

                    Text("\(reps) reps × \(String(format: "%.0f", weight)) kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                Divider()

                Button {
                    onNextSet()
                } label: {
                    Label("Next Set", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    onChangeExercise()
                } label: {
                    Label("Change Exercise", systemImage: "arrow.left.arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    onEndWorkout()
                } label: {
                    Label("End Workout", systemImage: "stop.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Set Complete")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}

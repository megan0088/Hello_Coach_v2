import SwiftUI

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

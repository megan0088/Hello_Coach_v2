import SwiftUI

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

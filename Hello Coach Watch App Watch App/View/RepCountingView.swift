import SwiftUI

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

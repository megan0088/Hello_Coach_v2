import SwiftUI

struct SessionDetailRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: session.type == .push ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(session.type == .push ? .orange : .blue)
                Text("\(session.type.rawValue) Day")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(session.formattedDuration)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                HStack {
                    Text("Volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f kg", session.totalVolume))
                        .font(.caption.weight(.semibold))
                }
                HStack {
                    Text("Total Reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(session.totalReps) reps · \(session.totalSets) sets")
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(10)
            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            if !session.entries.isEmpty {
                VStack(spacing: 3) {
                    ForEach(session.entries) { entry in
                        HStack {
                            Text("· \(entry.exercise.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(entry.setCount) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

import SwiftUI

struct PRCard: View {
    let exercise: Exercise
    let pr: RepSet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
                Text(exercise.subgroup.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.orange)
                    .tracking(0.5)
            }

            Text(exercise.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.0f", pr.weightKg))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text("kg")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text("×\(pr.reps) · \(pr.timestamp, format: .relative(presentation: .named))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 140, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

import SwiftUI

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

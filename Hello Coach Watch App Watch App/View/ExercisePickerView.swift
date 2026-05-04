import SwiftUI

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

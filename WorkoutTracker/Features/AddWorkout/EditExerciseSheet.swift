import SwiftUI

struct EditExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var exercise: Exercise

    var body: some View {
        NavigationStack {
            Form {
                Section("Øvelse") {
                    TextField("Navn", text: $exercise.name)
                }

                Section {
                    ForEach(exercise.sets.indices, id: \.self) { i in
                        EditSetRow(index: i, set: $exercise.sets[i])
                    }
                    .onDelete { exercise.sets.remove(atOffsets: $0) }

                    Button {
                        let last = exercise.sets.last ?? WorkingSet(reps: 10, weight: 0)
                        exercise.sets.append(WorkingSet(reps: last.reps, weight: last.weight))
                    } label: {
                        Label("Legg til sett", systemImage: "plus")
                    }
                } header: {
                    Text("Sett")
                } footer: {
                    Text("Sveip for å slette et sett.")
                }
            }
            .navigationTitle("Rediger øvelse")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ferdig") { dismiss() }
                }
            }
        }
    }
}

private struct EditSetRow: View {
    let index: Int
    @Binding var set: WorkingSet

    var body: some View {
        HStack(spacing: 12) {
            Text("Sett \(index + 1)")
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .leading)

            Spacer()

            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)

            Text("kg")
                .foregroundStyle(.secondary)

            Divider()
                .frame(height: 22)
                .padding(.horizontal, 4)

            Stepper(value: $set.reps, in: 1...50) {
                Text("\(set.reps) reps")
                    .frame(width: 64, alignment: .trailing)
            }
        }
    }
}

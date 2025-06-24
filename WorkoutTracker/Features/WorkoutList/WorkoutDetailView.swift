import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        List {
            // Øvelser‐seksjon
            Section(header: Text(LocalizedStringKey("Øvelser"))) {
                if workout.exercises.isEmpty {
                    // Placeholder når ingen øvelser er lagt til
                    Text(LocalizedStringKey("Ingen øvelser"))
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(workout.exercises) { ex in
                        // Formater vekten før Text‐kallet
                        let weightString = String(format: "%.1f", ex.weight)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ex.name)
                                .font(.headline)

                            Text(
                                LocalizedStringKey(
                                    "Sett: \(ex.sets), Reps: \(ex.reps), Vekt: \(weightString) kg"
                                )
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Notater‐seksjon (vises kun om notater finnes)
            if !workout.notes.isEmpty {
                Section(header: Text(LocalizedStringKey("Notater"))) {
                    Text(workout.notes)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(workout.type.capitalized)
    }
}

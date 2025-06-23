import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        List {
            // Øvelser
            Section(header: Text("Øvelser")) {
                ForEach(workout.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                        Text("Sett: \(exercise.sets), Reps: \(exercise.reps), Vekt: \(exercise.weight, specifier: "%.1f") kg")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Notater (kun om det finnes)
            if !workout.notes.isEmpty {
                Section(header: Text("Notater")) {
                    Text(workout.notes)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(workout.type)
    }
}

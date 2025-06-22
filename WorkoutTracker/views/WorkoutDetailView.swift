import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        List {
            ForEach(workout.exercises) { exercise in
                VStack(alignment: .leading) {
                    Text(exercise.name).font(.headline)
                    Text("Sett: \(exercise.sets), Reps: \(exercise.reps), Vekt: \(exercise.weight, specifier: "%.1f") kg")
                }
            }
        }
        .navigationTitle(workout.type)
    }
}
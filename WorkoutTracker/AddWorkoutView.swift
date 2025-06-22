import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var workouts: [Workout]

    @State private var type = ""
    @State private var exercises: [Exercise] = []
    @State private var showExerciseSheet = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Type")) {
                    TextField("Push / Pull / Bein", text: $type)
                }

                Section(header: Text("Øvelser")) {
                    ForEach(exercises) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.name).bold()
                            Text("Sett: \(exercise.sets), Reps: \(exercise.reps), Vekt: \(exercise.weight, specifier: "%.1f") kg")
                        }
                    }

                    Button {
                        showExerciseSheet = true
                    } label: {
                        Label("Legg til øvelse", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Ny økt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") {
                        let newWorkout = Workout(date: .now, type: type, exercises: exercises)
                        workouts.append(newWorkout)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExerciseSheet) {
                NewExerciseSheet(exercises: $exercises)
            }
        }
    }
}

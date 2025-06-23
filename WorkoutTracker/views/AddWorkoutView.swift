import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var workouts: [Workout]

    @State private var type = ""
    @State private var category: WorkoutCategory = .strength
    @State private var exercises: [Exercise] = []

    @State private var showExerciseSheet = false
    @State private var editingExerciseIndex: IdentifiableInt? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Type og kategori")) {
                    TextField("F.eks. Push / Bein / Øktnavn", text: $type)

                    Picker("Kategori", selection: $category) {
                        ForEach(WorkoutCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                }

                Section(header: Text("Øvelser")) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.name).bold()
                            Text("Sett: \(exercise.sets), Reps: \(exercise.reps), Vekt: \(exercise.weight, specifier: "%.1f") kg")
                        }
                        .onTapGesture {
                            editingExerciseIndex = IdentifiableInt(value: index)
                        }
                    }
                    .onDelete { indexSet in
                        exercises.remove(atOffsets: indexSet)
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
                        let newWorkout = Workout(date: .now, type: type, category: category, exercises: exercises)
                        workouts.append(newWorkout)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExerciseSheet) {
                NewExerciseSheet(exercises: $exercises)
            }
            .sheet(item: $editingExerciseIndex) { index in
                EditExerciseSheet(exercise: $exercises[index.value])
            }
        }
    }
}

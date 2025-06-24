import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: AddWorkoutViewModel

    // Init med WorkoutStore slik at VM kan lagre
    init(store: WorkoutStore) {
        _vm = StateObject(wrappedValue: AddWorkoutViewModel(store: store))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Type og kategori") {
                    TextField("F.eks. Push / Bein / Øktnavn", text: $vm.type)
                    Picker("Kategori", selection: $vm.category) {
                        ForEach(WorkoutCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                }

                Section("Øvelser") {
                    ForEach(Array(vm.exercises.enumerated()), id: \.element.id) { index, exercise in
                        // 1) Formater vekten i en egen variabel
                        let weightString = String(format: "%.1f", exercise.weight)

                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)

                            // 2) Bruk den ferdige strengen i Text
                            Text("Sett: \(exercise.sets), Reps: \(exercise.reps), Vekt: \(weightString) kg")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture {
                            vm.editingExerciseIndex = IdentifiableInt(value: index)
                        }
                    }
                    .onDelete { vm.exercises.remove(atOffsets: $0) }

                    Button {
                        vm.showExerciseSheet = true
                    } label: {
                        Label("Legg til øvelse", systemImage: "plus.circle")
                    }
                }

                Section("Notater") {
                    TextEditor(text: $vm.notes)
                        .frame(minHeight: 100)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.5))
                        )
                }
            }
            .navigationTitle("Ny økt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") {
                        vm.save()
                        dismiss()
                    }
                    .disabled(vm.isSaveDisabled)
                }
            }
            // Ark for å legge til ny øvelse
            .sheet(isPresented: $vm.showExerciseSheet) {
                NewExerciseSheet(exercises: $vm.exercises)
            }
            // Ark for å redigere en øvelse
            .sheet(item: $vm.editingExerciseIndex) { index in
                EditExerciseSheet(exercise: $vm.exercises[index.value])
            }
        }
    }
}

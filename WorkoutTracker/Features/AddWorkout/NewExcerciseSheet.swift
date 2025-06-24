import SwiftUI

struct NewExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercises: [Exercise]

    @StateObject private var vm = ExercisesViewModel()

    private let predefinedExercises = ["Benkpress", "Nedtrekk"]

    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = 0.0
    @State private var newCustomExercise = ""
    @State private var showEditSheet = false

    // Alle valg — kombinasjon av forhåndsdefinerte + egendefinerte
    private var allExercises: [String] {
        predefinedExercises + vm.exercises
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Velg eller skriv inn øvelse") {
                    Picker("Velg øvelse", selection: $name) {
                        Text("Egendefinert").tag("")
                        ForEach(allExercises, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        TextField("Skriv inn ny øvelse", text: $newCustomExercise)
                        Button {
                            vm.add(newCustomExercise)
                            name = newCustomExercise
                            newCustomExercise = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newCustomExercise.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Detaljer") {
                    Stepper("Sett: \(sets)", value: $sets, in: 1...10)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...30)
                    TextField("Vekt (kg)", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button("Rediger egendefinerte øvelser") {
                        showEditSheet = true
                    }
                }
            }
            .navigationTitle("Ny øvelse")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lagre") {
                        let new = Exercise(name: name, sets: sets, reps: reps, weight: weight)
                        exercises.append(new)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Sett default navn til første i listen
                if name.isEmpty {
                    name = allExercises.first ?? ""
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditCustomExercisesView(vm: vm)
            }
        }
    }
}

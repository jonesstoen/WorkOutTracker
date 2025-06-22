import SwiftUI

struct NewExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var exercises: [Exercise]

    private let predefinedExercises: [String] = ["Benkpress", "Nedtrekk"]

    @State private var customExercises: [String] = []
    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = 0.0
    @State private var newCustomExercise = ""
    @State private var showEditSheet = false

    var allExercises: [String] {
        predefinedExercises + customExercises
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Velg eller skriv inn øvelse")) {
                    Picker("Velg øvelse", selection: $name) {
                        Text("Egendefinert").tag("")
                        ForEach(allExercises, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Eller skriv ny øvelse", text: $newCustomExercise)

                    Button("Legg til egendefinert øvelse") {
                        let trimmed = newCustomExercise.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        if !customExercises.contains(trimmed) && !predefinedExercises.contains(trimmed) {
                            customExercises.append(trimmed)
                            name = trimmed
                            newCustomExercise = ""
                            saveCustomExercises()
                        }
                    }
                }

                Section(header: Text("Detaljer")) {
                    Stepper("Sett: \(sets)", value: $sets, in: 1...10)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...30)
                    TextField("Vekt (kg)", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                }
                Button("Rediger egendefinerte øvelser") {
                    showEditSheet = true
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
                loadCustomExercises()
                if name.isEmpty {
                    name = allExercises.first ?? ""
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditCustomExercisesView(customExercises: $customExercises)
        }
    }

    private func saveCustomExercises() {
        UserDefaults.standard.set(customExercises, forKey: "customExercises")
    }

    private func loadCustomExercises() {
        customExercises = UserDefaults.standard.stringArray(forKey: "customExercises") ?? []
    }
}

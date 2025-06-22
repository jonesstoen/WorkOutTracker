//
//  NewExcerciseSheet.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 22/06/2025.
//

import SwiftUI

struct NewExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var exercises: [Exercise]

    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = 0.0

    var body: some View {
        NavigationView {
            Form {
                TextField("Øvelse", text: $name)
                Stepper("Sett: \(sets)", value: $sets, in: 1...10)
                Stepper("Reps: \(reps)", value: $reps, in: 1...30)
                TextField("Vekt (kg)", value: $weight, format: .number)
                    .keyboardType(.decimalPad)
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
                }
            }
        }
    }
}

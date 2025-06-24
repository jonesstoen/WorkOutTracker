//
//  EditExerciseSheet.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 22/06/2025.
//


import SwiftUI

struct EditExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var exercise: Exercise

    var body: some View {
        NavigationView {
            Form {
                TextField("Øvelse", text: $exercise.name)
                Stepper("Sett: \(exercise.sets)", value: $exercise.sets, in: 1...10)
                Stepper("Reps: \(exercise.reps)", value: $exercise.reps, in: 1...30)
                TextField("Vekt (kg)", value: $exercise.weight, format: .number)
                    .keyboardType(.decimalPad)
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

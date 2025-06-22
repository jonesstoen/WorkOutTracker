//
//  EditCustomExercisesView.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 22/06/2025.
//


import SwiftUI

struct EditCustomExercisesView: View {
    @Binding var customExercises: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(customExercises, id: \.self) { exercise in
                    Text(exercise)
                }
                .onDelete { indexSet in
                    customExercises.remove(atOffsets: indexSet)
                    save()
                }
            }
            .navigationTitle("Egendefinerte øvelser")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ferdig") { dismiss() }
                }
            }
        }
    }

    private func save() {
        UserDefaults.standard.set(customExercises, forKey: "customExercises")
    }
}

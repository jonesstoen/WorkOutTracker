//
//  AddWorkoutViewModel.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 24/06/2025.
//


import SwiftUI
import Combine

@MainActor
class AddWorkoutViewModel: ObservableObject {
    @Published var date: Date = .now
    @Published var type = ""
    @Published var category: WorkoutCategory = .strength
    @Published var exercises: [Exercise] = []
    @Published var notes = ""

    @Published var showExerciseSheet = false
    @Published var editingExerciseIndex: IdentifiableInt?

    private let repository: WorkoutRepository

    init(store: WorkoutStore) {
        // For nå bruker vi WorkoutStore som konkret repo, men avhengigheten er
        // uttrykt via WorkoutRepository slik at vi senere kan bytte implementasjon.
        self.repository = store
    }

    var isSaveDisabled: Bool {
        type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() {
        let workout = Workout(
            date: date,
            type: type.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            exercises: exercises,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        repository.add(workout)
    }
}

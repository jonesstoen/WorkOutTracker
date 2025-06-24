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
    // MARK: - Inputs
    @Published var type: String = ""
    @Published var category: WorkoutCategory = .strength
    @Published var exercises: [Exercise] = []
    @Published var notes: String = ""

    @Published var showExerciseSheet = false
    @Published var editingExerciseIndex: IdentifiableInt? = nil

    // MARK: - Avhengighet til lagring
    private let store: WorkoutStore

    init(store: WorkoutStore) {
        self.store = store
    }

    // MARK: - Validering
    var isSaveDisabled: Bool {
        type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Handlinger
    func save() {
        let newWorkout = Workout(
            date: .now,
            type: type,
            category: category,
            exercises: exercises,
            notes: notes
        )
        store.workouts.append(newWorkout)
    }
}

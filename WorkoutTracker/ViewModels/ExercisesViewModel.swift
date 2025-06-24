//
//  ExercisesViewModel.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 24/06/2025.
//


import Foundation
import Combine

@MainActor
class ExercisesViewModel: ObservableObject {
    @Published var exercises: [String] = []

    private let key = "customExercises"

    init() {
        load()
    }

    /// Legg til ny egendefinert øvelse
    func add(_ new: String) {
        let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !exercises.contains(trimmed) else { return }
        exercises.append(trimmed)
        save()
    }

    /// Fjern øvelser på gitt offsets
    func remove(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        exercises = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    private func save() {
        UserDefaults.standard.set(exercises, forKey: key)
    }
}

//
//  LiveWorkout.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 12/02/2026.
//


import Foundation

struct LiveWorkout: Equatable, Codable {
    var startDate: Date = .now
    var type: String = ""
    var category: WorkoutCategory = .strength
    var exercises: [Exercise] = []
    var notes: String = ""

    /// Antall sett som ikke er haket av.
    var incompleteSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter { !$0.isCompleted }.count }
    }

    /// Øvelsene slik de lagres: bare fullførte sett, og uten øvelser som står tomme.
    var completedExercises: [Exercise] {
        exercises.compactMap { exercise in
            var copy = exercise
            copy.sets = exercise.sets.filter(\.isCompleted)
            return copy.sets.isEmpty ? nil : copy
        }
    }

    mutating func markAllCompleted() {
        for e in exercises.indices {
            for s in exercises[e].sets.indices {
                exercises[e].sets[s].isCompleted = true
            }
        }
    }
}

/// Snapshot persisted to UserDefaults so a live session survives app kills.
struct LiveSessionSnapshot: Codable {
    let draft: LiveWorkout
    let totalPaused: TimeInterval
    let wasRunning: Bool
    let savedAt: Date
}
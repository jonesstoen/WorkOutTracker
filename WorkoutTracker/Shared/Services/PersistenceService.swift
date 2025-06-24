//
//  PersistenceService.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 24/06/2025.
//


import Foundation

/// En protokoll som definerer hvordan vi laster og lagrer økter
protocol PersistenceService {
    func loadWorkouts() -> [Workout]
    func saveWorkouts(_ workouts: [Workout])
}

/// Standard‐implementasjon som bruker UserDefaults + JSON
final class UserDefaultsPersistence: PersistenceService {
    private let key = "saved_workouts"

    func loadWorkouts() -> [Workout] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([Workout].self, from: data)
        else {
            return []
        }
        return decoded
    }

    func saveWorkouts(_ workouts: [Workout]) {
        guard let data = try? JSONEncoder().encode(workouts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

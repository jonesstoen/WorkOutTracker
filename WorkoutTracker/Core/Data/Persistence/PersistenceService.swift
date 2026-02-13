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
    private enum Keys {
        static let workouts = "saved_workouts"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadWorkouts() -> [Workout] {
        guard
            let data = userDefaults.data(forKey: Keys.workouts)
        else {
            return []
        }
        let decoded: [Workout]
        do {
            decoded = try JSONDecoder().decode([Workout].self, from: data)
            print("📦 Loaded \(decoded.count) workouts")
        } catch {
            print("❌ Failed to decode workouts:", error)
            return []
        }
        return decoded
    }

    func saveWorkouts(_ workouts: [Workout]) {
        let data: Data
        do {
            data = try JSONEncoder().encode(workouts)
            print("💾 Saved \(workouts.count) workouts")
        } catch {
            print("❌ Failed to encode workouts:", error)
            return
        }
        userDefaults.set(data, forKey: Keys.workouts)
    }
}

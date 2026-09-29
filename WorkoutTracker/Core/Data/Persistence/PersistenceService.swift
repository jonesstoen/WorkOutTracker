//
//  PersistenceService.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 24/06/2025.
//


import Foundation
import OSLog

/// En protokoll som definerer hvordan vi laster og lagrer økter
protocol PersistenceService {
    func loadWorkouts() -> [Workout]
    func saveWorkouts(_ workouts: [Workout])
}

/// Lagrer økter som JSON i Application Support.
/// Migrerer automatisk eldre data fra `UserDefaults` første gang den kjøres.
final class FilePersistence: PersistenceService {
    private let fileURL: URL
    private let legacy: UserDefaultsPersistence?

    init(
        directory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0],
        migratingFrom legacy: UserDefaultsPersistence? = UserDefaultsPersistence()
    ) {
        self.fileURL = directory.appendingPathComponent("workouts.json")
        self.legacy = legacy
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func loadWorkouts() -> [Workout] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return migrateFromLegacy()
        }
        do {
            let decoded = try JSONDecoder().decode([Workout].self, from: data)
            Logger.persistence.debug("Loaded \(decoded.count) workouts")
            return decoded
        } catch {
            Logger.persistence.error("Failed to decode workouts: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func saveWorkouts(_ workouts: [Workout]) {
        do {
            let data = try JSONEncoder().encode(workouts)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            Logger.persistence.debug("Saved \(workouts.count) workouts")
        } catch {
            Logger.persistence.error("Failed to save workouts: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func migrateFromLegacy() -> [Workout] {
        guard let legacy else { return [] }
        let workouts = legacy.loadWorkouts()
        guard !workouts.isEmpty else { return [] }
        saveWorkouts(workouts)
        // Old data is kept in UserDefaults as a fallback; it is no longer read once the file exists
        Logger.persistence.info("Migrated \(workouts.count) workouts from UserDefaults")
        return workouts
    }
}

/// Eldre implementasjon som bruker UserDefaults + JSON. Brukes nå kun til migrering.
final class UserDefaultsPersistence: PersistenceService {
    private enum Keys {
        static let workouts = "saved_workouts"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadWorkouts() -> [Workout] {
        guard let data = userDefaults.data(forKey: Keys.workouts) else { return [] }
        do {
            return try JSONDecoder().decode([Workout].self, from: data)
        } catch {
            Logger.persistence.error("Failed to decode legacy workouts: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func saveWorkouts(_ workouts: [Workout]) {
        do {
            userDefaults.set(try JSONEncoder().encode(workouts), forKey: Keys.workouts)
        } catch {
            Logger.persistence.error("Failed to encode workouts: \(error.localizedDescription, privacy: .public)")
        }
    }
}

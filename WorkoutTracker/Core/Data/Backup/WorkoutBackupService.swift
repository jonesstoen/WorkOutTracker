import Foundation

/// Everything needed to restore the app's training data on a fresh install.
struct WorkoutBackup: Codable, Equatable {
    var version: Int
    var exportedAt: Date
    var workouts: [Workout]
    /// The user's own exercise names, and the muscle group chosen for each (keyed by `exerciseKey`)
    var customExercises: [String]?
    var customExerciseMuscles: [String: String]?
}

struct ImportPreview: Equatable {
    let total: Int
    let newCount: Int
    var existingCount: Int { total - newCount }
}

/// Export to JSON (full backup) or CSV (one row per set, for spreadsheets), and import JSON back.
enum WorkoutBackupService {
    enum Format {
        case json, csv
        var fileExtension: String { self == .json ? "json" : "csv" }
    }

    enum ImportMode {
        /// Add workouts that are not in the app yet; local versions of existing ones are kept
        case addNew
        /// Make the app's workouts exactly those in the backup
        case replaceAll
    }

    enum BackupError: LocalizedError {
        case unreadable

        var errorDescription: String? {
            "Filen er ikke en sikkerhetskopi fra WorkoutTracker."
        }
    }

    static let currentVersion = 1
    private static let customExercisesKey = "customExercises"

    // MARK: - Export

    static func makeBackup(workouts: [Workout], defaults: UserDefaults = .standard, now: Date = .now) -> WorkoutBackup {
        let muscles = ExerciseCatalog.customMuscles(in: defaults).mapValues(\.rawValue)
        return WorkoutBackup(
            version: currentVersion,
            exportedAt: now,
            workouts: workouts.sorted { $0.date < $1.date },
            customExercises: defaults.stringArray(forKey: customExercisesKey) ?? [],
            customExerciseMuscles: muscles
        )
    }

    static func jsonData(_ backup: WorkoutBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(isoFormatter.string(from: date))
        }
        return try encoder.encode(backup)
    }

    static func fileName(for format: Format, on date: Date = .now) -> String {
        let day = date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day().dateSeparator(.dash))
        return "WorkoutTracker-\(day).\(format.fileExtension)"
    }

    /// Semicolon-separated with decimal commas, as Numbers and Excel expect with Norwegian settings.
    /// Starts with a byte order mark so Excel reads æøå as UTF-8.
    static func csv(for workouts: [Workout], timeZone: TimeZone = .current) -> String {
        let header = ["Dato", "Økt", "Kategori", "Øvelse", "Sett", "Vekt (kg)", "Reps", "Fullført", "Varighet (min)", "Notater"]
        var rows = [header]

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for workout in workouts.sorted(by: { $0.date < $1.date }) {
            let common = [
                dateFormatter.string(from: workout.date),
                workout.type.trimmingCharacters(in: .whitespacesAndNewlines),
                workout.category.rawValue,
            ]
            let minutes = workout.duration > 0 ? String(Int((workout.duration / 60).rounded())) : ""

            if workout.exercises.allSatisfy({ $0.sets.isEmpty }) {
                rows.append(common + ["", "", "", "", "", minutes, workout.notes])
                continue
            }
            for exercise in workout.exercises {
                for (index, set) in exercise.sets.enumerated() {
                    rows.append(common + [
                        exercise.name,
                        String(index + 1),
                        decimalComma(set.weight),
                        String(set.reps),
                        set.isCompleted ? "Ja" : "Nei",
                        minutes,
                        workout.notes,
                    ])
                }
            }
        }

        return "\u{FEFF}" + rows.map { $0.map(csvField).joined(separator: ";") }.joined(separator: "\r\n") + "\r\n"
    }

    // MARK: - Import

    /// Reads a backup made by `jsonData`, or the app's own `workouts.json`.
    static func parse(_ data: Data) throws -> WorkoutBackup {
        let isoDecoder = JSONDecoder()
        isoDecoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            guard let date = isoFormatter.date(from: string) ?? plainIsoFormatter.date(from: string) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Ugyldig dato: \(string)"))
            }
            return date
        }
        if let backup = try? isoDecoder.decode(WorkoutBackup.self, from: data) {
            return backup
        }
        if let workouts = try? JSONDecoder().decode([Workout].self, from: data) {
            return WorkoutBackup(version: currentVersion, exportedAt: .now, workouts: workouts)
        }
        throw BackupError.unreadable
    }

    static func preview(of backup: WorkoutBackup, existing: [Workout]) -> ImportPreview {
        let existingIDs = Set(existing.map(\.id))
        return ImportPreview(
            total: backup.workouts.count,
            newCount: backup.workouts.filter { !existingIDs.contains($0.id) }.count
        )
    }

    static func merged(existing: [Workout], with backup: WorkoutBackup, mode: ImportMode) -> [Workout] {
        switch mode {
        case .replaceAll:
            return backup.workouts
        case .addNew:
            let existingIDs = Set(existing.map(\.id))
            return existing + backup.workouts.filter { !existingIDs.contains($0.id) }
        }
    }

    /// Adds the backup's custom exercises and muscle groups to those already on the device.
    static func restoreCustomExercises(from backup: WorkoutBackup, into defaults: UserDefaults = .standard) {
        var names = defaults.stringArray(forKey: customExercisesKey) ?? []
        let knownKeys = Set(names.map(\.exerciseKey))
        names += (backup.customExercises ?? []).filter { !knownKeys.contains($0.exerciseKey) }
        defaults.set(names, forKey: customExercisesKey)

        for (key, raw) in backup.customExerciseMuscles ?? [:] {
            if let muscle = MuscleGroup(rawValue: raw) {
                ExerciseCatalog.setCustomMuscle(muscle, for: key, in: defaults)
            }
        }
    }

    // MARK: - Helpers

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let plainIsoFormatter = ISO8601DateFormatter()

    private static func decimalComma(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never).locale(Locale(identifier: "nb_NO")))
    }

    private static func csvField(_ field: String) -> String {
        guard field.contains(where: { ";\"\n\r".contains($0) }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

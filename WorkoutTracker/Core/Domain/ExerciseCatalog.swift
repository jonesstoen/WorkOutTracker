import Foundation

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest = "Bryst"
    case back = "Rygg"
    case legs = "Ben"
    case shoulders = "Skuldre"
    case arms = "Armer"
    case core = "Kjerne"
    case other = "Annet"

    var id: String { rawValue }

    /// Groups the user can pick for an exercise ("Annet" is only the fallback)
    static var selectable: [MuscleGroup] { allCases.filter { $0 != .other } }
}

struct CatalogExercise {
    let name: String
    let muscle: MuscleGroup
}

/// Built-in exercises and the muscle group each one counts towards.
enum ExerciseCatalog {
    static let predefined: [CatalogExercise] = [
        // Bryst
        CatalogExercise(name: "Benkpress",          muscle: .chest),
        CatalogExercise(name: "Benkpress manualer", muscle: .chest),
        CatalogExercise(name: "Incline benkpress",  muscle: .chest),
        CatalogExercise(name: "Flyes",              muscle: .chest),
        CatalogExercise(name: "Dips",               muscle: .chest),
        // Rygg
        CatalogExercise(name: "Nedtrekk",           muscle: .back),
        CatalogExercise(name: "Pull-ups",           muscle: .back),
        CatalogExercise(name: "Roing",              muscle: .back),
        CatalogExercise(name: "Sittende roing",     muscle: .back),
        CatalogExercise(name: "Kabelroing",         muscle: .back),
        CatalogExercise(name: "Markløft",           muscle: .back),
        // Ben
        CatalogExercise(name: "Squat",              muscle: .legs),
        CatalogExercise(name: "Leg press",          muscle: .legs),
        CatalogExercise(name: "Utfall",             muscle: .legs),
        CatalogExercise(name: "Strak markløft",     muscle: .legs),
        CatalogExercise(name: "Hip thrust",         muscle: .legs),
        CatalogExercise(name: "Leg curl",           muscle: .legs),
        CatalogExercise(name: "Leg extension",      muscle: .legs),
        // Skuldre
        CatalogExercise(name: "Skulderpress",       muscle: .shoulders),
        CatalogExercise(name: "Stående press",      muscle: .shoulders),
        CatalogExercise(name: "Lateral raises",     muscle: .shoulders),
        CatalogExercise(name: "Facepull",           muscle: .shoulders),
        // Armer
        CatalogExercise(name: "Bicep curl",         muscle: .arms),
        CatalogExercise(name: "Hammer curl",        muscle: .arms),
        CatalogExercise(name: "Triceps pushdown",   muscle: .arms),
        CatalogExercise(name: "Skull crushers",     muscle: .arms),
        // Kjerne
        CatalogExercise(name: "Planke",             muscle: .core),
        CatalogExercise(name: "Cable crunch",       muscle: .core),
        CatalogExercise(name: "Russian twist",      muscle: .core),
        CatalogExercise(name: "Hanging leg raise",  muscle: .core),
    ]

    /// Common alternative names that are not listed in the picker
    private static let aliases: [String: MuscleGroup] = [
        "knebøy": .legs,
        "beinpress": .legs,
        "bicepscurl": .arms,
        "planken": .core,
    ]

    private static let lookup: [String: MuscleGroup] = {
        var map = aliases
        for entry in predefined { map[entry.name.exerciseKey] = entry.muscle }
        return map
    }()

    static func isBuiltIn(_ name: String) -> Bool {
        predefined.contains { $0.name.exerciseKey == name.exerciseKey }
    }

    /// Muscle group for an exercise name; `custom` holds the user's own choices keyed by `exerciseKey`
    static func muscle(for name: String, custom: [String: MuscleGroup]) -> MuscleGroup {
        let key = name.exerciseKey
        return lookup[key] ?? custom[key] ?? .other
    }

    // MARK: - Muscle groups for custom exercises

    private static let customMusclesKey = "customExerciseMuscles"

    static func customMuscles(in defaults: UserDefaults = .standard) -> [String: MuscleGroup] {
        let raw = defaults.dictionary(forKey: customMusclesKey) as? [String: String] ?? [:]
        return raw.compactMapValues(MuscleGroup.init(rawValue:))
    }

    static func setCustomMuscle(_ muscle: MuscleGroup, for name: String, in defaults: UserDefaults = .standard) {
        var raw = defaults.dictionary(forKey: customMusclesKey) as? [String: String] ?? [:]
        raw[name.exerciseKey] = muscle.rawValue
        defaults.set(raw, forKey: customMusclesKey)
    }
}

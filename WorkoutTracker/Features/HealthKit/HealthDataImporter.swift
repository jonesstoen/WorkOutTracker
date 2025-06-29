import HealthKit

/// Mapper HKWorkout til din egen `Workout`-modell, inkl. asynkron henting av kalorier via HKStatisticsQuery.
struct HealthDataImporter {
    /// Henter total kaloriforbrenning for én workout asynkront
    private static func fetchCalories(for workout: HKWorkout,
                                      completion: @escaping (Double) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        // Predicate for samples innenfor øktens tidsrom
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, stats, _ in
            let calories = stats?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie()) ?? 0
            completion(calories)
        }
        HealthKitManager.shared.store.execute(query)
    }

    /// Asynkron map av HKWorkout til `Workout` med riktig kategori
    static func asyncMap(_ hk: HKWorkout) async throws -> Workout {
        try await withCheckedThrowingContinuation { cont in
            fetchCalories(for: hk) { calories in
                let durationMin = Int(hk.duration / 60)
                // Velg kategori basert på aktivitetstype
                let category: WorkoutCategory
                switch hk.workoutActivityType {
                case .traditionalStrengthTraining:
                    category = .strength
                case .running:
                    category = .running
                case .walking:
                    category = .walking
                case .cycling:
                    category = .cycling
                case .swimming:
                    category = .swimming
                case .yoga, .mindAndBody:
                    category = .yoga
                default:
                    category = .other
                }

                let workout = Workout(
                    id : hk.uuid,
                    date: hk.startDate,
                    type: hk.workoutActivityType.displayName,
                    category: category,
                    exercises: [],
                    notes: "Kalorier: \(Int(calories)), Varighet: \(durationMin) min"
                )
                cont.resume(returning: workout)
            }
        }
    }
}

// Extension for visningsnavn på HKWorkoutActivityType
extension HKWorkoutActivityType {
    /// Gir et enkelt tekst-navn for de mest brukte aktivitets-typene
    var displayName: String {
        switch self {
        case .traditionalStrengthTraining: return "Styrke"
        case .running:                    return "Løping"
        case .cycling:                    return "Sykling"
        case .walking:                    return "Gange"
        case .swimming:                   return "Svømming"
        case .yoga:                       return "Yoga"
        case .mindAndBody:                return "Mind & Body"
        default:                          return "Annet"
        }
    }
}

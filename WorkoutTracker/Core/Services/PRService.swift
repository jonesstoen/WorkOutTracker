import Foundation

enum PRService {
    /// Epley estimated one-rep max: weight × (1 + reps / 30)
    static func e1RM(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// Returns the best set per exercise across all workouts, keyed by normalized exercise name (`exerciseKey`).
    /// Workouts are processed chronologically so later dates win ties.
    static func computePRs(from workouts: [Workout]) -> [String: ExercisePR] {
        var prs: [String: ExercisePR] = [:]

        for workout in workouts.sorted(by: { $0.date < $1.date }) {
            for exercise in workout.exercises {
                let key = exercise.name.exerciseKey
                for set in exercise.sets {
                    guard set.weight > 0, set.reps > 0 else { continue }
                    let score = e1RM(weight: set.weight, reps: set.reps)
                    if let existing = prs[key], score <= existing.e1RM { continue }
                    prs[key] = ExercisePR(
                        exerciseName: exercise.name,
                        weight: set.weight,
                        reps: set.reps,
                        e1RM: score,
                        date: workout.date
                    )
                }
            }
        }
        return prs
    }
}

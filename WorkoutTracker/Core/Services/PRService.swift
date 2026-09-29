import Foundation

enum PRService {
    /// Epley estimated one-rep max: weight × (1 + reps / 30)
    static func e1RM(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// Returns the best set per exercise across all workouts, keyed by normalized exercise name (`exerciseKey`).
    /// Weighted sets are ranked by e1RM; exercises only ever done with bodyweight are ranked by reps.
    /// Workouts are processed chronologically so the first time a record is reached wins ties.
    static func computePRs(from workouts: [Workout]) -> [String: ExercisePR] {
        var prs: [String: ExercisePR] = [:]

        for workout in workouts.sorted(by: { $0.date < $1.date }) {
            for exercise in workout.exercises {
                let key = exercise.name.exerciseKey
                for set in exercise.sets where set.isCompleted && set.reps > 0 && set.weight >= 0 {
                    if let existing = prs[key], !isRecord(weight: set.weight, reps: set.reps, comparedTo: existing) {
                        continue
                    }
                    prs[key] = ExercisePR(
                        exerciseName: exercise.name,
                        weight: set.weight,
                        reps: set.reps,
                        e1RM: e1RM(weight: set.weight, reps: set.reps),
                        date: workout.date
                    )
                }
            }
        }
        return prs
    }

    /// Whether a set beats the current record: any weighted set beats a bodyweight record,
    /// weighted sets compare e1RM and bodyweight sets compare reps.
    static func isRecord(weight: Double, reps: Int, comparedTo pr: ExercisePR) -> Bool {
        guard reps > 0 else { return false }
        switch (weight > 0, pr.isBodyweight) {
        case (true, true):   return true
        case (true, false):  return e1RM(weight: weight, reps: reps) > pr.e1RM
        case (false, true):  return reps > pr.reps
        case (false, false): return false
        }
    }
}

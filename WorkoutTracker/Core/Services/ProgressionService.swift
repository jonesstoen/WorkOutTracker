import Foundation

struct ExerciseDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let e1RM: Double
    let weight: Double
    let reps: Int
}

enum ProgressionService {

    // Best set per session for an exercise, oldest first.
    // Weighted sets are ranked by e1RM; if an exercise has only bodyweight sets, by reps.
    static func history(for name: String, in workouts: [Workout]) -> [ExerciseDataPoint] {
        let key = name.exerciseKey
        return workouts
            .sorted { $0.date < $1.date }
            .compactMap { workout -> ExerciseDataPoint? in
                guard let exercise = workout.exercises.first(where: { $0.name.exerciseKey == key }) else { return nil }
                let valid = exercise.sets.filter { $0.isCompleted && $0.reps > 0 }
                let weighted = valid.filter { $0.weight > 0 }
                let best = weighted.isEmpty
                    ? valid.max { $0.reps < $1.reps }
                    : weighted.max { PRService.e1RM(weight: $0.weight, reps: $0.reps) < PRService.e1RM(weight: $1.weight, reps: $1.reps) }
                guard let best else { return nil }
                return ExerciseDataPoint(
                    date: workout.date,
                    e1RM: PRService.e1RM(weight: best.weight, reps: best.reps),
                    weight: best.weight,
                    reps: best.reps
                )
            }
    }

    static func lastSession(for name: String, in workouts: [Workout]) -> ExerciseDataPoint? {
        history(for: name, in: workouts).last
    }

    // MARK: - Repeat previous sessions

    /// Most recent workout with the same type name ("Push" == "push ") that has exercises
    static func lastWorkout(ofType type: String, in workouts: [Workout]) -> Workout? {
        let key = type.exerciseKey
        guard !key.isEmpty else { return nil }
        return workouts
            .filter { $0.type.exerciseKey == key && !$0.exercises.isEmpty }
            .max { $0.date < $1.date }
    }

    /// The workout's exercises as a fresh plan: new ids, same reps and weights, nothing completed
    static func plannedExercises(from workout: Workout) -> [Exercise] {
        workout.exercises.map { Exercise(name: $0.name, sets: $0.sets.map(\.planned)) }
    }

    /// Sets from the most recent session of an exercise, ready to be done again
    static func plannedSets(for name: String, in workouts: [Workout]) -> [WorkingSet]? {
        let key = name.exerciseKey
        let latest = workouts
            .sorted { $0.date > $1.date }
            .lazy
            .compactMap { $0.exercises.first { $0.name.exerciseKey == key && !$0.sets.isEmpty } }
            .first
        return latest?.sets.map(\.planned)
    }

    // Returns advice when e1RM has stagnated over the last sessions
    static func overloadAdvice(for name: String, in workouts: [Workout]) -> String? {
        let recent = Array(history(for: name, in: workouts).suffix(3))
        // Weight advice only makes sense for weighted exercises
        guard recent.count >= 2, recent.allSatisfy({ $0.weight > 0 }) else { return nil }

        let firstE1RM = recent.first!.e1RM
        let lastE1RM  = recent.last!.e1RM
        let improvement = firstE1RM > 0 ? (lastE1RM - firstE1RM) / firstE1RM : 0

        guard improvement < 0.025 else { return nil }

        let last = recent.last!
        let nextWeight = ((last.weight + 2.5) * 2).rounded() / 2

        let sessions = recent.count == 2 ? "2 siste" : "3 siste"
        return "Du har stagnert på \(last.weight.kgLabel) kg × \(last.reps) reps de \(sessions) " +
               "øktene. Prøv \(nextWeight.kgLabel) kg neste gang for å stimulere videre fremgang."
    }
}

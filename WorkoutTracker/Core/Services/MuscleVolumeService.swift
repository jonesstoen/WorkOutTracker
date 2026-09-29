import Foundation

struct MuscleVolume: Identifiable, Equatable {
    let muscle: MuscleGroup
    /// Completed sets in the current calendar week
    let thisWeek: Int
    /// Average completed sets per week over the four weeks before this one
    let average: Double

    var id: MuscleGroup { muscle }

    /// Normally trained, but this week is under half of the usual volume
    var isNeglected: Bool {
        average > 0 && Double(thisWeek) < average / 2
    }
}

enum MuscleVolumeService {
    private static let baselineWeeks = 4

    /// Completed sets per muscle group this week vs. the previous four weeks.
    /// Groups not trained in any of those five weeks are left out; catalog order is kept.
    static func weekly(
        workouts: [Workout],
        now: Date = .now,
        calendar: Calendar = .current,
        muscleFor: (String) -> MuscleGroup
    ) -> [MuscleVolume] {
        guard
            let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now),
            let baselineStart = calendar.date(byAdding: .weekOfYear, value: -baselineWeeks, to: thisWeek.start)
        else { return [] }

        var current: [MuscleGroup: Int] = [:]
        var baseline: [MuscleGroup: Int] = [:]

        for workout in workouts where workout.date >= baselineStart && workout.date < thisWeek.end {
            let isThisWeek = workout.date >= thisWeek.start
            for exercise in workout.exercises {
                let count = exercise.sets.filter(\.isCompleted).count
                guard count > 0 else { continue }
                let muscle = muscleFor(exercise.name)
                if isThisWeek {
                    current[muscle, default: 0] += count
                } else {
                    baseline[muscle, default: 0] += count
                }
            }
        }

        return MuscleGroup.allCases.compactMap { muscle in
            let sets = current[muscle] ?? 0
            let total = baseline[muscle] ?? 0
            guard sets > 0 || total > 0 else { return nil }
            return MuscleVolume(muscle: muscle, thisWeek: sets, average: Double(total) / Double(baselineWeeks))
        }
    }
}

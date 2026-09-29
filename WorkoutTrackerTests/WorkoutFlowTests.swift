import Foundation
import Testing
@testable import WorkoutTracker

private let cal = Calendar.current

private func daysAgo(_ n: Int, from now: Date = .now) -> Date {
    cal.date(byAdding: .day, value: -n, to: now)!
}

private func workout(_ date: Date, type: String = "Push", _ exercises: [Exercise]) -> Workout {
    Workout(date: date, type: type, category: .strength, exercises: exercises)
}

private func sets(_ n: Int, reps: Int = 5, weight: Double = 50, completed: Bool = true) -> [WorkingSet] {
    (0..<n).map { _ in WorkingSet(reps: reps, weight: weight, isCompleted: completed) }
}

struct WorkingSetDecodingTests {

    @Test
    func setsSavedBeforeCompletionTrackingDecodeAsCompleted() throws {
        let json = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","reps":5,"weight":80}"#
        let set = try JSONDecoder().decode(WorkingSet.self, from: Data(json.utf8))
        #expect(set.isCompleted)
    }

    @Test
    func completionFlagRoundTrips() throws {
        let set = WorkingSet(reps: 5, weight: 80, isCompleted: false)
        let decoded = try JSONDecoder().decode(WorkingSet.self, from: JSONEncoder().encode(set))
        #expect(decoded == set)
    }
}

struct RepeatWorkoutTests {

    @Test
    func lastWorkout_matchesTypeLooselyAndPicksNewest() {
        let old = workout(daysAgo(7), type: "Push", [Exercise(name: "Benkpress", sets: sets(3, weight: 70))])
        let newest = workout(daysAgo(2), type: "push ", [Exercise(name: "Benkpress", sets: sets(3, weight: 75))])
        let other = workout(daysAgo(1), type: "Pull", [Exercise(name: "Roing", sets: sets(3))])

        let found = ProgressionService.lastWorkout(ofType: "Push", in: [old, newest, other])
        #expect(found?.id == newest.id)
    }

    @Test
    func lastWorkout_ignoresWorkoutsWithoutExercises() {
        let empty = workout(daysAgo(1), type: "Push", [])
        #expect(ProgressionService.lastWorkout(ofType: "Push", in: [empty]) == nil)
    }

    @Test
    func plannedExercises_copiesSetsAsNewUncompletedSets() {
        let source = workout(daysAgo(2), [Exercise(name: "Benkpress", sets: sets(2, reps: 5, weight: 80))])
        let planned = ProgressionService.plannedExercises(from: source)

        #expect(planned.map(\.name) == ["Benkpress"])
        #expect(planned[0].sets.map(\.weight) == [80, 80])
        #expect(planned[0].sets.allSatisfy { !$0.isCompleted })
        #expect(planned[0].id != source.exercises[0].id)
        #expect(planned[0].sets[0].id != source.exercises[0].sets[0].id)
    }

    @Test
    func plannedSets_comesFromMostRecentSessionOfThatExercise() {
        let workouts = [
            workout(daysAgo(5), [Exercise(name: "Knebøy", sets: sets(3, weight: 90))]),
            workout(daysAgo(1), [Exercise(name: "knebøy", sets: sets(2, weight: 100))]),
        ]
        let planned = ProgressionService.plannedSets(for: "Knebøy", in: workouts)

        #expect(planned?.map(\.weight) == [100, 100])
        #expect(planned?.allSatisfy { !$0.isCompleted } == true)
        #expect(ProgressionService.plannedSets(for: "Ukjent", in: workouts) == nil)
    }
}

struct CompletedSetsTests {

    @Test
    func completedExercises_dropsUnfinishedSetsAndEmptyExercises() {
        var draft = LiveWorkout()
        draft.exercises = [
            Exercise(name: "Benkpress", sets: sets(2) + sets(1, completed: false)),
            Exercise(name: "Flyes", sets: sets(2, completed: false)),
        ]

        #expect(draft.incompleteSetCount == 3)
        #expect(draft.completedExercises.map(\.name) == ["Benkpress"])
        #expect(draft.completedExercises[0].sets.count == 2)
    }

    @Test
    func markAllCompleted_completesEverySet() {
        var draft = LiveWorkout()
        draft.exercises = [Exercise(name: "Benkpress", sets: sets(2, completed: false))]
        draft.markAllCompleted()

        #expect(draft.incompleteSetCount == 0)
        #expect(draft.completedExercises[0].sets.count == 2)
    }
}

struct MuscleVolumeTests {

    private func muscle(_ name: String) -> MuscleGroup {
        ExerciseCatalog.muscle(for: name, custom: ["min øvelse": .arms])
    }

    @Test
    func catalog_resolvesBuiltInAliasAndCustomNames() {
        #expect(muscle("benkpress ") == .chest)
        #expect(muscle("Knebøy") == .legs)
        #expect(muscle("Min øvelse") == .arms)
        #expect(muscle("Noe helt nytt") == .other)
    }

    @Test
    func weekly_countsCompletedSetsThisWeekAgainstFourWeekAverage() throws {
        let now = try #require(cal.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 12)))
        let workouts = [
            // This week: 3 chest sets (one unfinished set ignored), 0 back
            workout(now, [Exercise(name: "Benkpress", sets: sets(3) + sets(1, completed: false))]),
            // Previous four weeks: 8 back sets and 4 chest sets in total
            workout(daysAgo(7, from: now), [Exercise(name: "Roing", sets: sets(4)), Exercise(name: "Benkpress", sets: sets(4))]),
            workout(daysAgo(14, from: now), [Exercise(name: "Markløft", sets: sets(4))]),
            // Five weeks ago: outside the window
            workout(daysAgo(35, from: now), [Exercise(name: "Bicep curl", sets: sets(10))]),
        ]

        let volumes = MuscleVolumeService.weekly(workouts: workouts, now: now, calendar: cal, muscleFor: muscle)
        let byMuscle = Dictionary(uniqueKeysWithValues: volumes.map { ($0.muscle, $0) })

        #expect(byMuscle[.chest]?.thisWeek == 3)
        #expect(byMuscle[.chest]?.average == 1)
        #expect(byMuscle[.chest]?.isNeglected == false)

        #expect(byMuscle[.back]?.thisWeek == 0)
        #expect(byMuscle[.back]?.average == 2)
        #expect(byMuscle[.back]?.isNeglected == true)

        // Groups not trained in the last five weeks are left out
        #expect(byMuscle[.arms] == nil)
        // Catalog order is kept
        #expect(volumes.map(\.muscle) == [.chest, .back])
    }

    @Test
    func neglected_whenBelowHalfOfAverage() {
        #expect(MuscleVolume(muscle: .legs, thisWeek: 2, average: 6).isNeglected)
        #expect(!MuscleVolume(muscle: .legs, thisWeek: 3, average: 6).isNeglected)
        #expect(!MuscleVolume(muscle: .legs, thisWeek: 0, average: 0).isNeglected)
    }
}

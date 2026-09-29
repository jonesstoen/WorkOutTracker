import Foundation
import Testing
@testable import WorkoutTracker

struct BodyweightRecordTests {

    private func workout(daysAgo: Int, _ name: String, reps: Int, weight: Double = 0) -> Workout {
        Workout(
            date: Date().addingTimeInterval(TimeInterval(-daysAgo * 86_400)),
            type: "Pull",
            category: .strength,
            exercises: [Exercise(name: name, sets: [WorkingSet(reps: reps, weight: weight)])]
        )
    }

    @Test
    func bodyweightExercise_getsRecordForMostReps() throws {
        let prs = PRService.computePRs(from: [
            workout(daysAgo: 3, "Pull-ups", reps: 8),
            workout(daysAgo: 1, "Pull-ups", reps: 11),
        ])
        let pr = try #require(prs["pull-ups"])
        #expect(pr.reps == 11)
        #expect(pr.isBodyweight)
    }

    @Test
    func weightedSets_winOverBodyweightSets() throws {
        let prs = PRService.computePRs(from: [
            workout(daysAgo: 3, "Pull-ups", reps: 15),
            workout(daysAgo: 1, "Pull-ups", reps: 5, weight: 10),
        ])
        let pr = try #require(prs["pull-ups"])
        #expect(pr.weight == 10)
        #expect(!pr.isBodyweight)
    }

    @Test
    func isRecord_comparesRepsForBodyweight() throws {
        let pr = try #require(PRService.computePRs(from: [workout(daysAgo: 1, "Dips", reps: 10)])["dips"])
        #expect(PRService.isRecord(weight: 0, reps: 11, comparedTo: pr))
        #expect(!PRService.isRecord(weight: 0, reps: 10, comparedTo: pr))
        #expect(PRService.isRecord(weight: 5, reps: 1, comparedTo: pr))
    }

    @Test
    func bodyweightHistory_tracksBestReps() {
        let history = ProgressionService.history(for: "Pull-ups", in: [
            workout(daysAgo: 3, "Pull-ups", reps: 8),
            workout(daysAgo: 1, "Pull-ups", reps: 11),
        ])
        #expect(history.map(\.reps) == [8, 11])
        #expect(ProgressionService.overloadAdvice(for: "Pull-ups", in: []) == nil)
    }
}

struct CompletedVolumeTests {

    @Test
    func completedVolume_ignoresPlannedSets() {
        let exercise = Exercise(name: "Benkpress", sets: [
            WorkingSet(reps: 5, weight: 100, isCompleted: true),
            WorkingSet(reps: 5, weight: 100, isCompleted: false),
        ])
        #expect(exercise.completedVolume == 500)
    }
}

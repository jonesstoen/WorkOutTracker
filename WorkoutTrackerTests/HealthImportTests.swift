import Foundation
import HealthKit
import Testing
@testable import WorkoutTracker

struct AnchoredImportTests {

    /// Returns the given workouts once, then nothing new (like an anchored HealthKit query)
    final class AnchoredFetcherFake: HealthKitWorkoutFetching {
        var batches: [[HKWorkout]]
        private(set) var receivedAnchors: [HKQueryAnchor?] = []

        init(batches: [[HKWorkout]]) { self.batches = batches }

        func fetchNewWorkouts(since anchor: HKQueryAnchor?) async throws -> (workouts: [HKWorkout], anchor: HKQueryAnchor?) {
            receivedAnchors.append(anchor)
            let next = batches.isEmpty ? [] : batches.removeFirst()
            return (next, HKQueryAnchor(fromValue: receivedAnchors.count))
        }
    }

    private func defaults() -> UserDefaults {
        let suite = "AnchoredImportTests-\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    private func hkWorkout(hoursAgo: Double, duration: TimeInterval = 1800) -> HKWorkout {
        let start = Date().addingTimeInterval(-hoursAgo * 3600)
        return HKWorkout(activityType: .running, start: start, end: start.addingTimeInterval(duration))
    }

    @Test
    func importedWorkouts_keepTheirDuration() async {
        let repo = WorkoutRepositoryFake()
        let service = WorkoutImportService(
            repository: repo,
            workoutFetcher: AnchoredFetcherFake(batches: [[hkWorkout(hoursAgo: 2, duration: 2700)]]),
            defaults: defaults(),
            isAuthorized: { true }
        )
        await service.importIfNeeded()
        #expect(repo.workouts.first?.duration == 2700)
    }

    @Test
    func lateSyncedWorkout_isImportedOnNextLaunch() async {
        let repo = WorkoutRepositoryFake()
        let store = defaults()
        // A workout that started before the first import, but reached HealthKit afterwards
        let fetcher = AnchoredFetcherFake(batches: [[hkWorkout(hoursAgo: 1)], [hkWorkout(hoursAgo: 30)]])

        await WorkoutImportService(repository: repo, workoutFetcher: fetcher, defaults: store, isAuthorized: { true }).importIfNeeded()
        await WorkoutImportService(repository: repo, workoutFetcher: fetcher, defaults: store, isAuthorized: { true }).importIfNeeded()

        #expect(repo.workouts.count == 2)
        // The second launch continues from the anchor saved by the first
        #expect(fetcher.receivedAnchors.first! == nil)
        #expect(fetcher.receivedAnchors.last! != nil)
    }

    @Test
    func firstAnchoredRun_respectsOldImportDate() async {
        let repo = WorkoutRepositoryFake()
        let store = defaults()
        store.set(Date().addingTimeInterval(-5 * 3600).timeIntervalSince1970, forKey: "lastHealthKitImport")
        let fetcher = AnchoredFetcherFake(batches: [[hkWorkout(hoursAgo: 1), hkWorkout(hoursAgo: 48)]])

        await WorkoutImportService(repository: repo, workoutFetcher: fetcher, defaults: store, isAuthorized: { true }).importIfNeeded()

        // The 48h-old workout was handled by the old import (and may have been deleted since)
        #expect(repo.workouts.count == 1)
    }

    @Test
    func unauthorized_importsNothing() async {
        let repo = WorkoutRepositoryFake()
        let service = WorkoutImportService(
            repository: repo,
            workoutFetcher: AnchoredFetcherFake(batches: [[hkWorkout(hoursAgo: 1)]]),
            defaults: defaults(),
            isAuthorized: { false }
        )
        await service.importIfNeeded()
        #expect(repo.workouts.isEmpty)
    }
}

struct LegacyHealthNotesTests {

    @Test
    func durationInNotes_movesToDurationField() {
        let old = Workout(date: .now, type: "Løping", category: .running, exercises: [],
                          notes: "Kalorier: 312, Varighet: 45 min")
        let repaired = old.repairingLegacyHealthNotes()

        #expect(repaired.duration == 45 * 60)
        #expect(repaired.notes == "Kalorier: 312 kcal")
    }

    @Test
    func otherWorkouts_areLeftAlone() {
        let own = Workout(date: .now, type: "Push", category: .strength, exercises: [],
                          notes: "Varighet: 45 min var lenge", duration: 3000)
        #expect(own.repairingLegacyHealthNotes() == own)
    }
}

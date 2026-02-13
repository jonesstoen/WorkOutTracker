import Testing
import HealthKit
@testable import WorkoutTracker

/// Fake-repo som lar oss se hvilke økter import‑servicen legger til.
final class WorkoutRepositoryFake: WorkoutRepository {
    // Backing storage that is actually @Published
    @Published private var workoutsStorage: [Workout] = []

    // Protocol requirement: snapshot
    var workouts: [Workout] { workoutsStorage }

    // Protocol requirement: publisher
    var workoutsPublisher: Published<[Workout]>.Publisher { $workoutsStorage }

    func add(_ workout: Workout) {
        workoutsStorage.append(workout)
    }

    func add(contentsOf newWorkouts: [Workout]) {
        workoutsStorage.append(contentsOf: newWorkouts)
    }

    func delete(_ workout: Workout) {
        workoutsStorage.removeAll { $0.id == workout.id }
    }
}

/// Fake fetcher som returnerer forhåndsdefinerte HKWorkout‑instanser.
struct HealthKitWorkoutFetcherFake: HealthKitWorkoutFetching {
    var workouts: [HKWorkout]

    func fetchWorkouts(limit: Int) async throws -> [HKWorkout] {
        Array(workouts.prefix(limit))
    }
}

struct WorkoutImportServiceTests {

    @Test
    func importIfNeeded_addsOnlyNewWorkouts_andIsIdempotent() async throws {
        // Sørg for at vi starter uten tidligere import‑timestamp.
        UserDefaults.standard.removeObject(forKey: "lastHealthKitImport")

        // Lag to dummy HKWorkout‑objekter.
        let now = Date()
        let earlier = now.addingTimeInterval(-3600)

        let hk1 = HKWorkout(activityType: .running,
                            start: earlier,
                            end: now)
        let hk2 = HKWorkout(activityType: .traditionalStrengthTraining,
                            start: earlier.addingTimeInterval(-7200),
                            end: earlier.addingTimeInterval(-3600))

        let fetcher = HealthKitWorkoutFetcherFake(workouts: [hk1, hk2])
        let repo = WorkoutRepositoryFake()

        let importService = WorkoutImportService(
            repository: repo,
            workoutFetcher: fetcher
        )

        // Første import skal legge til begge mapped workouts i repoet.
        await importService.importIfNeeded()
        #expect(repo.workouts.count == 2)

        // Andre kall i samme sesjon skal være no‑op (didImportInitial hindrer ny import).
        await importService.importIfNeeded()
        #expect(repo.workouts.count == 2)
    }
}


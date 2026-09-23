import Foundation
import Testing
@testable import WorkoutTracker

private func day(_ offset: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: .now))!
}

private func strengthWorkout(_ offset: Int, _ name: String, weight: Double, reps: Int) -> Workout {
    Workout(
        date: day(offset),
        type: "Styrke",
        category: .strength,
        exercises: [Exercise(name: name, sets: [WorkingSet(reps: reps, weight: weight)])]
    )
}

struct PRServiceTests {

    @Test
    func e1RM_usesEpleyAndIgnoresEmptySets() {
        #expect(PRService.e1RM(weight: 100, reps: 30) == 200)
        #expect(PRService.e1RM(weight: 0, reps: 5) == 0)
        #expect(PRService.e1RM(weight: 100, reps: 0) == 0)
    }

    @Test
    func computePRs_keepsBestSetAndMatchesNamesLoosely() {
        let workouts = [
            strengthWorkout(-2, "Benkpress", weight: 80, reps: 5),
            strengthWorkout(-1, "benkpress ", weight: 90, reps: 3),
            strengthWorkout(0, "Knebøy", weight: 100, reps: 5),
        ]
        let prs = PRService.computePRs(from: workouts)

        #expect(prs.count == 2)
        #expect(prs["benkpress"]?.weight == 90)
        #expect(prs["knebøy"]?.weight == 100)
    }
}

struct ProgressionServiceTests {

    @Test
    func history_isChronologicalAndUsesBestSet() {
        let workouts = [
            strengthWorkout(-1, "Markløft", weight: 120, reps: 5),
            strengthWorkout(-3, "Markløft", weight: 110, reps: 5),
        ]
        let history = ProgressionService.history(for: "markløft", in: workouts)

        #expect(history.map(\.weight) == [110, 120])
        #expect(ProgressionService.lastSession(for: "Markløft", in: workouts)?.weight == 120)
    }

    @Test
    func overloadAdvice_suggestsWeightJustAboveLastSession() throws {
        let workouts = [
            strengthWorkout(-3, "Benkpress", weight: 100, reps: 5),
            strengthWorkout(-2, "Benkpress", weight: 100, reps: 5),
            strengthWorkout(-1, "Benkpress", weight: 100, reps: 5),
        ]
        let advice = try #require(ProgressionService.overloadAdvice(for: "Benkpress", in: workouts))

        #expect(advice.contains("Prøv \(102.5.kgLabel) kg"))
    }

    @Test
    func overloadAdvice_isNilWhenProgressing() {
        let workouts = [
            strengthWorkout(-2, "Benkpress", weight: 90, reps: 5),
            strengthWorkout(-1, "Benkpress", weight: 100, reps: 5),
        ]
        #expect(ProgressionService.overloadAdvice(for: "Benkpress", in: workouts) == nil)
    }
}

@MainActor
struct HomeViewModelTests {

    private func viewModel(workoutDays: [Int]) -> HomeViewModel {
        let persistence = PersistenceServiceFake()
        persistence.storedWorkouts = workoutDays.map {
            Workout(date: day($0).addingTimeInterval(3600), type: "", category: .running, exercises: [])
        }
        return HomeViewModel(store: WorkoutStore(persistence: persistence))
    }

    @Test
    func currentStreak_countsConsecutiveDaysIncludingToday() {
        #expect(viewModel(workoutDays: [0, -1, -2, -4]).currentStreak == 3)
    }

    @Test
    func currentStreak_startsYesterdayWhenNoWorkoutToday() {
        #expect(viewModel(workoutDays: [-1, -2]).currentStreak == 2)
    }

    @Test
    func currentStreak_isZeroAfterMissedDay() {
        #expect(viewModel(workoutDays: [-2, -3]).currentStreak == 0)
    }
}

struct FilePersistenceTests {

    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    @Test
    func saveThenLoad_roundTrips() {
        let persistence = FilePersistence(directory: tempDirectory(), migratingFrom: nil)
        let workout = strengthWorkout(0, "Benkpress", weight: 80, reps: 5)

        persistence.saveWorkouts([workout])

        #expect(persistence.loadWorkouts() == [workout])
    }

    @Test
    func load_migratesLegacyUserDefaultsData() throws {
        let suite = "FilePersistenceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let legacy = UserDefaultsPersistence(userDefaults: defaults)
        let workout = strengthWorkout(0, "Knebøy", weight: 100, reps: 5)
        legacy.saveWorkouts([workout])

        let directory = tempDirectory()
        #expect(FilePersistence(directory: directory, migratingFrom: legacy).loadWorkouts() == [workout])
        // Once migrated, the file is the source of truth even without the legacy store
        #expect(FilePersistence(directory: directory, migratingFrom: nil).loadWorkouts() == [workout])
    }
}

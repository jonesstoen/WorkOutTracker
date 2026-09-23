import Testing
@testable import WorkoutTracker

/// En enkel fake for PersistenceService som lar oss teste WorkoutStore
/// uten å lese/lagre til ekte UserDefaults.
final class PersistenceServiceFake: PersistenceService {
    var storedWorkouts: [Workout] = []

    func loadWorkouts() -> [Workout] {
        storedWorkouts
    }

    func saveWorkouts(_ workouts: [Workout]) {
        storedWorkouts = workouts
    }
}

struct WorkoutStoreTests {

    @Test
    func addAndDeleteWorkouts_updatesPersistence() async throws {
        let fakePersistence = PersistenceServiceFake()
        let store = WorkoutStore(persistence: fakePersistence)

        let workout = Workout(
            date: .now,
            type: "Test",
            category: .strength,
            exercises: [],
            notes: "Test"
        )

        // Når vi legger til en økt i store, skal den også bli lagret i fakePersistence.
        store.add(workout)

        #expect(store.workouts.contains(workout))
        #expect(fakePersistence.storedWorkouts.contains(workout))

        // Når vi sletter økten, skal den forsvinne fra både store og persistens.
        store.delete(workout)
        #expect(!store.workouts.contains(workout))
        #expect(!fakePersistence.storedWorkouts.contains(workout))
    }
}


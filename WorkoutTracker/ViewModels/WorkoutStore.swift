import Foundation
import Combine

/// Abstraksjon for all lesing/skriving av `Workout` i appen.
///
/// Målet er at _ingen_ utenfor repoet skal mutere en `[Workout]` direkte.
/// I stedet går alle endringer via disse metodene, slik at validering,
/// persistens og side‑effekter kan ligge her ett sted.
protocol WorkoutRepository: AnyObject {
    /// Nåværende liste over økter (snapshot).
    var workouts: [Workout] { get }

    /// Publisher som sender ut alle endringer.
    var workoutsPublisher: Published<[Workout]>.Publisher { get }

    /// Legg til én økt.
    func add(_ workout: Workout)

    /// Legg til flere økter samtidig.
    func add(contentsOf workouts: [Workout])

    /// Slett en spesifikk økt.
    func delete(_ workout: Workout)
}

final class WorkoutStore: ObservableObject, WorkoutRepository {
    @Published var workouts: [Workout] = []

    private let persistence: PersistenceService
    private var cancellables = Set<AnyCancellable>()

    /// Eksponer `Published`‑publisheren via repo‑protokollen.
    var workoutsPublisher: Published<[Workout]>.Publisher { $workouts }

    /// Lar deg bytte ut lagringslag (f.eks. CoreData) enklere
    init(persistence: PersistenceService = UserDefaultsPersistence()) {
        self.persistence = persistence
        // Last inn fra service
        self.workouts = persistence.loadWorkouts()

        // Debounce saving to avoid excessive disk writes
        $workouts
            .dropFirst() // Avoid saving immediately after initial load
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] workouts in
                print("save workout", workouts.count)
                self?.persistence.saveWorkouts(workouts)
            }
            .store(in: &cancellables)
    }

    // MARK: - WorkoutRepository

    func add(_ workout: Workout) {
        workouts.append(workout)
    }

    func add(contentsOf workouts: [Workout]) {
        guard !workouts.isEmpty else { return }
        self.workouts.append(contentsOf: workouts)
    }

    func delete(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
    }
}

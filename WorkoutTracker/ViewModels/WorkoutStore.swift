import Foundation
import Combine

final class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = []

    private let persistence: PersistenceService
    private var cancellables = Set<AnyCancellable>()

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
}

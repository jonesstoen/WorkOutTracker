import Foundation
import Combine

final class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = [] {
        didSet {
            persistence.saveWorkouts(workouts)
        }
    }

    private let persistence: PersistenceService

    /// Lar deg bytte ut lagringslag (f.eks. CoreData) enklere
    init(persistence: PersistenceService = UserDefaultsPersistence()) {
        self.persistence = persistence
        // Last inn fra service
        self.workouts = persistence.loadWorkouts()
    }
}

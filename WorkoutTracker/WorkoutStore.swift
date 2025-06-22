import Foundation

class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = [] {
        didSet { save() }
    }

    private let saveKey = "saved_workouts"

    init() {
        load()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
    }
}
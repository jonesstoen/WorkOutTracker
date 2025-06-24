import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published private(set) var workouts: [Workout] = []
    private var cancellables = Set<AnyCancellable>()

    init(store: WorkoutStore) {
        self.workouts = store.workouts
        store.$workouts
            .receive(on: DispatchQueue.main)
            .assign(to: \.workouts, on: self)
            .store(in: &cancellables)
    }

    // MARK: – Computed properties

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:   return "God morgen"
        case 12..<17:  return "God dag"
        case 17..<22:  return "God kveld"
        default:       return "God natt"
        }
    }

    var dateString: String {
        Date().formatted(.dateTime.day().month().year())
    }

    var totalSets: Int {
        workouts.reduce(0) { sum, w in
            sum + w.exercises.reduce(0) { $0 + $1.sets }
        }
    }

    var totalReps: Int {
        workouts.reduce(0) { sum, w in
            sum + w.exercises.reduce(0) { $0 + ($1.sets * $1.reps) }
        }
    }

    var totalWeight: Double {
        workouts.reduce(0) { sum, w in
            sum + w.exercises.reduce(0) {
                $0 + (Double($1.sets * $1.reps) * $1.weight)
            }
        }
    }

    var last7days: [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return workouts.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
        }
        .reversed()
    }

    var last7daysLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.dateFormat = "E"
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return formatter.string(from: day)
        }
        .reversed()
    }

    var recentWorkouts: [Workout] {
        Array(workouts.sorted { $0.date > $1.date }.prefix(5))
    }
}

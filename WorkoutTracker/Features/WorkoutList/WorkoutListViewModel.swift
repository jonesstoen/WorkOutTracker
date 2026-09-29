import SwiftUI
import Combine

@MainActor
class WorkoutListViewModel: ObservableObject {
    @Published private(set) var workouts: [Workout] = []
    @Published var selectedCategory: WorkoutCategory? = nil
    private let repository: WorkoutRepository

    init(store: WorkoutStore) {
        self.repository = store
        self.workouts = store.workouts
        store.$workouts
            .receive(on: DispatchQueue.main)
            .assign(to: &$workouts)
    }

    private struct YearWeek: Hashable {
        let year: Int
        let week: Int
    }

    var sections: [(title: String, workouts: [Workout])] {
        let cal = Calendar.current
        let now = Date()

        let thisWeek = YearWeek(
            year: cal.component(.yearForWeekOfYear, from: now),
            week: cal.component(.weekOfYear, from: now)
        )
        let lastWeekDate = cal.date(byAdding: .weekOfYear, value: -1, to: now)!
        let lastWeek = YearWeek(
            year: cal.component(.yearForWeekOfYear, from: lastWeekDate),
            week: cal.component(.weekOfYear, from: lastWeekDate)
        )

        let filtered = selectedCategory == nil
            ? workouts
            : workouts.filter { $0.category == selectedCategory }

        let grouped = Dictionary(grouping: filtered) { workout -> YearWeek in
            YearWeek(
                year: cal.component(.yearForWeekOfYear, from: workout.date),
                week: cal.component(.weekOfYear, from: workout.date)
            )
        }

        let sortedKeys = grouped.keys.sorted { lhs, rhs in
            lhs.year != rhs.year ? lhs.year > rhs.year : lhs.week > rhs.week
        }

        return sortedKeys.map { key in
            let title: String
            if key == thisWeek {
                title = "Denne uken"
            } else if key == lastWeek {
                title = "Forrige uke"
            } else {
                title = "Uke \(key.week), \(key.year)"
            }
            let items = grouped[key]!.sorted { $0.date > $1.date }
            return (title: title, workouts: items)
        }
    }

    func delete(at offsets: IndexSet, in sectionTitle: String) {
        guard let sectionWorkouts = sections.first(where: { $0.title == sectionTitle })?.workouts
        else { return }
        offsets.map { sectionWorkouts[$0] }.forEach { repository.delete($0) }
    }
}

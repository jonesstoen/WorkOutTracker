// WorkoutListViewModel.swift
// WorkoutTracker
//
// Created by Johannes Støen on 24/06/2025.
//

import SwiftUI
import Combine

@MainActor
class WorkoutListViewModel: ObservableObject {
    @Published private(set) var workouts: [Workout] = []
    private var cancellables = Set<AnyCancellable>()
    private let repository: WorkoutRepository

    init(store: WorkoutStore) {
        // Bruk WorkoutStore som konkret implementasjon, men snakk via
        // WorkoutRepository slik at vi kan bytte senere.
        self.repository = store
        self.workouts = store.workouts

        store.$workouts
            .receive(on: DispatchQueue.main)
            .assign(to: \.workouts, on: self)
            .store(in: &cancellables)
    }

    /// Hjelpe‐type for (år, uke), gir Hashable‐støtte
    private struct YearWeek: Hashable {
        let year: Int
        let week: Int
    }

    /// Seksjoner gruppert og sortert etter år og uke
    var sections: [(title: String, workouts: [Workout])] {
        let calendar = Calendar.current

        // 1) Gruppér på YearWeek
        let grouped = Dictionary(grouping: workouts) { workout -> YearWeek in
            let week = calendar.component(.weekOfYear, from: workout.date)
            let year = calendar.component(.yearForWeekOfYear, from: workout.date)
            return YearWeek(year: year, week: week)
        }

        // 2) Sortér nøklene synkende etter år, så uke
        let sortedKeys = grouped.keys.sorted { lhs, rhs in
            if lhs.year != rhs.year {
                return lhs.year > rhs.year
            } else {
                return lhs.week > rhs.week
            }
        }

        // 3) Bygg array av seksjoner med tittel og sorterte økter
        return sortedKeys.map { key in
            let title = "Uke \(key.week), \(key.year)"
            let items = grouped[key]!.sorted { $0.date > $1.date }
            return (title: title, workouts: items)
        }
    }

    /// Slett økter i en gitt seksjon
    func delete(at offsets: IndexSet, in sectionTitle: String) {
        // Finn workshops for seksjonen
        guard let sectionWorkouts = sections.first(where: { $0.title == sectionTitle })?.workouts
        else { return }
        let toDelete = offsets.map { sectionWorkouts[$0] }
        toDelete.forEach { repository.delete($0) }
    }
}

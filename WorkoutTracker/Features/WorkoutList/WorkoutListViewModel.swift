//
//  WorkoutListViewModel.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 24/06/2025.
//


import SwiftUI
import Combine

@MainActor
class WorkoutListViewModel: ObservableObject {
    @Published private(set) var workouts: [Workout] = []
    private var cancellables = Set<AnyCancellable>()
    private let store: WorkoutStore

    init(store: WorkoutStore) {
        self.store = store
        self.workouts = store.workouts

        store.$workouts
            .receive(on: DispatchQueue.main)
            .assign(to: \.workouts, on: self)
            .store(in: &cancellables)
    }

    // Gruppér øktene per uke
    var groupedWorkouts: [String: [Workout]] {
        Dictionary(grouping: workouts) { workout in
            let cal = Calendar.current
            let week = cal.component(.weekOfYear, from: workout.date)
            let year = cal.component(.yearForWeekOfYear, from: workout.date)
            return "Uke \(week), \(year)"
        }
    }

    // Sorterte seksjonsnøkler (uker)
    var sections: [String] {
        groupedWorkouts.keys.sorted(by: >)
    }

    // Sletting
    func delete(at offsets: IndexSet, in section: String) {
        guard let sectionWorkouts = groupedWorkouts[section] else { return }
        let toDelete = offsets.map { sectionWorkouts[$0] }
        store.workouts.removeAll { toDelete.contains($0) }
    }
}

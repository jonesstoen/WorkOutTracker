//
//  LiveWorkoutViewModel.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 12/02/2026.
//


import Foundation
import Combine

@MainActor
final class LiveWorkoutViewModel: ObservableObject {
    @Published var draft = LiveWorkout()
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = true

    @Published var showExerciseSheet = false
    @Published var editingExerciseIndex: IdentifiableInt?

    private var timerCancellable: AnyCancellable?
    private let store: WorkoutStore

    init(store: WorkoutStore, initialType: String = "", initialCategory: WorkoutCategory = .strength) {
        self.store = store
        draft.type = initialType
        draft.category = initialCategory
        startTimer()
    }

    func startTimer() {
        isRunning = true
        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.isRunning else { return }
                self.elapsed = Date().timeIntervalSince(self.draft.startDate)
            }
    }

    func pause() { isRunning = false }
    func resume() { isRunning = true }

    func finish() {
        let workout = Workout(
            date: draft.startDate,
            type: draft.type.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category,
            exercises: draft.exercises,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.workouts.append(workout)
    }
}

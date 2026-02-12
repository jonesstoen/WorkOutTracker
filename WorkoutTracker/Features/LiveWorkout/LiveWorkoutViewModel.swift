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
    private var pauseBeganAt: Date?
    private var totalPaused: TimeInterval = 0

    init(store: WorkoutStore, initialType: String = "", initialCategory: WorkoutCategory = .strength) {
        self.store = store
        draft.type = initialType
        draft.category = initialCategory
        self.isRunning = true
        startTimer()
    }

    func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }

                let now = Date()
                let currentPause = self.pauseBeganAt.map { now.timeIntervalSince($0) } ?? 0
                self.elapsed = now.timeIntervalSince(self.draft.startDate) - (self.totalPaused + currentPause)
            }
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        pauseBeganAt = Date()
    }

    func resume() {
        guard !isRunning else { return }
        isRunning = true
        if let began = pauseBeganAt {
            totalPaused += Date().timeIntervalSince(began)
            pauseBeganAt = nil
        }
    }

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

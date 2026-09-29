//
//  HealthKitService.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 29/06/2025.
//


import HealthKit

enum HealthKitService {
    /// Workouts added to HealthKit since `anchor` (all workouts when nil), plus the anchor to continue from.
    /// Unlike filtering on start date, this also catches workouts that sync late, e.g. from an Apple Watch.
    static func fetchNewWorkouts(since anchor: HKQueryAnchor?) async throws -> (workouts: [HKWorkout], anchor: HKQueryAnchor?) {
        try await withCheckedThrowingContinuation { cont in
            let query = HKAnchoredObjectQuery(
                type: .workoutType(),
                predicate: nil,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { _, samples, _, newAnchor, error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ((samples as? [HKWorkout]) ?? [], newAnchor))
                }
            }
            HealthKitManager.shared.store.execute(query)
        }
    }
}

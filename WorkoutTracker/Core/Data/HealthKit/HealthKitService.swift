//
//  HealthKitService.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 29/06/2025.
//


import HealthKit

enum HealthKitService {
    static func fetchWorkouts(limit: Int = 100) async throws -> [HKWorkout] {
          try await withCheckedThrowingContinuation { cont in
              let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
              let query = HKSampleQuery(
                  sampleType: .workoutType(),
                  predicate: nil,
                  limit: limit,
                  sortDescriptors: [sort]
              ) { _, samples, error in
                  if let error = error {
                      cont.resume(throwing: error)
                  } else {
                      cont.resume(returning: samples as? [HKWorkout] ?? [])
                  }
              }
              HealthKitManager.shared.store.execute(query)
          }
      }
}

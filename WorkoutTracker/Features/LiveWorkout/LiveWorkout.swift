//
//  LiveWorkout.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 12/02/2026.
//


import Foundation

struct LiveWorkout: Equatable {
    var startDate: Date = .now
    var type: String = ""
    var category: WorkoutCategory = .strength
    var exercises: [Exercise] = []
    var notes: String = ""
}
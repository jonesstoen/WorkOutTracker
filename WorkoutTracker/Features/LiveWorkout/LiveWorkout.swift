//
//  LiveWorkout.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 12/02/2026.
//


import Foundation

struct LiveWorkout: Equatable, Codable {
    var startDate: Date = .now
    var type: String = ""
    var category: WorkoutCategory = .strength
    var exercises: [Exercise] = []
    var notes: String = ""
}

/// Snapshot persisted to UserDefaults so a live session survives app kills.
struct LiveSessionSnapshot: Codable {
    let draft: LiveWorkout
    let totalPaused: TimeInterval
    let wasRunning: Bool
    let savedAt: Date
}
//
//  WorkoutCategory+Ui.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 12/02/2026.
//


import SwiftUI

extension WorkoutCategory {
    var color: Color {
        switch self {
        case .strength:  return .red
        case .cardio:    return .blue
        case .yoga:      return .green
        case .walking:   return .teal
        case .running:   return .orange
        case .cycling:   return .purple
        case .swimming:  return .cyan
        case .other:     return .gray
        }
    }

    var iconName: String {
        switch self {
        case .strength:  return "dumbbell"
        case .cardio:    return "heart.fill"
        case .yoga:      return "figure.cooldown"
        case .walking:   return "figure.walk"
        case .running:   return "figure.run"
        case .cycling:   return "bicycle"
        case .swimming:  return "figure.pool.swim"
        case .other:     return "questionmark.circle"
        }
    }
}

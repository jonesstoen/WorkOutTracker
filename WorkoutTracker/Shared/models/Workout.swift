import Foundation
import SwiftUI

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var type: String
    var category: WorkoutCategory
    var exercises: [Exercise]
    var notes: String     // ← ny

    init(
        id: UUID = UUID(),
        date: Date,
        type: String,
        category: WorkoutCategory,
        exercises: [Exercise],
        notes: String = ""  // ← default
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.category = category
        self.exercises = exercises
        self.notes = notes
    }
}


enum WorkoutCategory: String, CaseIterable, Identifiable, Codable {
    case strength = "Styrke"
    case cardio = "Kondisjon"
    case yoga = "Yoga"
    case walking = "Gange"
    case running = "Løping"
    case cycling = "Sykling"
    case swimming = "Svømming"
    case other = "Annet"

    var id: String { rawValue }

    /// Farge for kategori
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

    /// SF Symbols for kategori
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

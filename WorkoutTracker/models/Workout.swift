import Foundation
import SwiftUI

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var type: String
    var category: WorkoutCategory
    var exercises: [Exercise]

    init(id: UUID = UUID(), date: Date, type: String, category: WorkoutCategory, exercises: [Exercise]) {
        self.id = id
        self.date = date
        self.type = type
        self.category = category
        self.exercises = exercises
    }
}

enum WorkoutCategory: String, CaseIterable, Identifiable, Codable {
    case strength = "Styrke"
    case cardio = "Kondisjon"
    case yoga = "Yoga"
    case other = "Annet"

    var id: String { self.rawValue }

    var color: Color {
        switch self {
        case .strength: return .red
        case .cardio: return .blue
        case .yoga: return .green
        case .other: return .gray
        }
    }

    var iconName: String {
        switch self {
        case .strength: return "dumbbell"
        case .cardio: return "heart.fill"
        case .yoga: return "figure.cooldown"
        case .other: return "questionmark.circle"
        }
    }
}

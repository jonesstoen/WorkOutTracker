import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var type: String
    var category: WorkoutCategory
    var exercises: [Exercise]
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date,
        type: String,
        category: WorkoutCategory,
        exercises: [Exercise],
        notes: String = ""
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
}

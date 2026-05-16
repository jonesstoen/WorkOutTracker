import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var type: String
    var category: WorkoutCategory
    var exercises: [Exercise]
    var notes: String
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        date: Date,
        type: String,
        category: WorkoutCategory,
        exercises: [Exercise],
        notes: String = "",
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.category = category
        self.exercises = exercises
        self.notes = notes
        self.duration = duration
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(UUID.self, forKey: .id)
        date     = try c.decode(Date.self, forKey: .date)
        type     = try c.decode(String.self, forKey: .type)
        category = try c.decode(WorkoutCategory.self, forKey: .category)
        exercises = try c.decode([Exercise].self, forKey: .exercises)
        notes    = try c.decode(String.self, forKey: .notes)
        duration = (try? c.decode(TimeInterval.self, forKey: .duration)) ?? 0
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

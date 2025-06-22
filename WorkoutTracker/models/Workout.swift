import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var type: String
    var exercises: [Exercise]

    init(id: UUID = UUID(), date: Date, type: String, exercises: [Exercise]) {
        self.id = id
        self.date = date
        self.type = type
        self.exercises = exercises
    }
}

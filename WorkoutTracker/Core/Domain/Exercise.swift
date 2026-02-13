import Foundation

struct Exercise: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double

    init(id: UUID = UUID(), name: String, sets: Int, reps: Int, weight: Double) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
    }
}

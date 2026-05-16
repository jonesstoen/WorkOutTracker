import Foundation

struct ExercisePR: Identifiable {
    var id: String { exerciseName.lowercased() }
    let exerciseName: String
    let weight: Double
    let reps: Int
    let e1RM: Double
    let date: Date
}

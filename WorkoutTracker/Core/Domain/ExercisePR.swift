import Foundation

struct ExercisePR: Identifiable {
    var id: String { exerciseName.exerciseKey }
    let exerciseName: String
    let weight: Double
    let reps: Int
    let e1RM: Double
    let date: Date

    /// Record set without added weight (pull-ups, dips, ...), ranked by reps instead of e1RM
    var isBodyweight: Bool { weight == 0 }
}

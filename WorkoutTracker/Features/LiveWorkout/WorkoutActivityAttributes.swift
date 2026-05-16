import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    let workoutType: String   // e.g. "Push", "Styrke"
    let categoryIcon: String  // SF Symbol name
    let startDate: Date

    struct ContentState: Codable, Hashable {
        var isRunning: Bool
        var exerciseCount: Int
        var elapsed: TimeInterval  // used to anchor the live timer
    }
}

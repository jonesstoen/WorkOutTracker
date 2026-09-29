import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    let workoutType: String   // e.g. "Push", "Styrke"
    let categoryIcon: String  // SF Symbol name
    let startDate: Date

    struct ContentState: Codable, Hashable {
        var isRunning: Bool
        var exerciseCount: Int
        /// Start time with all pauses added, so `now - timerStart` is the active time.
        /// A fixed date keeps the timer right however often the system redraws the view.
        var timerStart: Date
        /// Set while paused; the timer shows `pausedAt - timerStart` and stands still.
        var pausedAt: Date?

        init(isRunning: Bool, exerciseCount: Int, elapsed: TimeInterval, now: Date = .now) {
            self.isRunning = isRunning
            self.exerciseCount = exerciseCount
            self.timerStart = now.addingTimeInterval(-elapsed)
            self.pausedAt = isRunning ? nil : now
        }
    }
}

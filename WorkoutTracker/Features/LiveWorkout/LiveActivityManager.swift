import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<WorkoutActivityAttributes>?

    func start(workoutType: String, categoryIcon: String, startDate: Date, exerciseCount: Int) {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            print("LiveActivity: activities not enabled (check NSSupportsLiveActivities in Info.plist)")
            return
        }
        guard activity == nil else { return }

        let attributes = WorkoutActivityAttributes(
            workoutType: workoutType.isEmpty ? "Treningsøkt" : workoutType,
            categoryIcon: categoryIcon,
            startDate: startDate
        )
        let state = WorkoutActivityAttributes.ContentState(
            isRunning: true,
            exerciseCount: exerciseCount,
            elapsed: Date().timeIntervalSince(startDate)
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("LiveActivity start error: \(error)")
        }
    }

    func update(isRunning: Bool, exerciseCount: Int, elapsed: TimeInterval) {
        guard let activity else { return }
        let state = WorkoutActivityAttributes.ContentState(
            isRunning: isRunning,
            exerciseCount: exerciseCount,
            elapsed: elapsed
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func end(elapsed: TimeInterval, exerciseCount: Int) {
        guard let activity else { return }
        let state = WorkoutActivityAttributes.ContentState(
            isRunning: false,
            exerciseCount: exerciseCount,
            elapsed: elapsed
        )
        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .after(.now + 4))
        }
        self.activity = nil
    }
}

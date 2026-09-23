import ActivityKit
import Foundation
import OSLog

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<WorkoutActivityAttributes>?

    func start(workoutType: String, categoryIcon: String, startDate: Date, exerciseCount: Int) {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            Logger.liveActivity.info("Activities not enabled (check NSSupportsLiveActivities in Info.plist)")
            return
        }
        guard activity == nil else { return }

        // End activities left behind by a session that was never restored
        for stale in Activity<WorkoutActivityAttributes>.activities {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }

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
            Logger.liveActivity.error("Start failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Picks up an activity that survived the app being killed, so updates reach it again.
    func reattach() {
        guard activity == nil else { return }
        activity = Activity<WorkoutActivityAttributes>.activities.first
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

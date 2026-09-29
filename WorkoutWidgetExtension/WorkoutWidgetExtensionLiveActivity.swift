import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen / banner
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.attributes.categoryIcon)
                            .font(.title2)
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.workoutType)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(context.state.isRunning ? "Pågår" : "Pause")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        WorkoutTimerText(state: context.state)
                            .font(.title3.monospacedDigit())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                        Text("\(context.state.exerciseCount) øvelser")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.trailing, 4)
                }
            } compactLeading: {
                Image(systemName: context.attributes.categoryIcon)
                    .foregroundStyle(.white)
            } compactTrailing: {
                WorkoutTimerText(state: context.state)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 40)
            } minimal: {
                Image(systemName: context.attributes.categoryIcon)
                    .foregroundStyle(.white)
            }
            .keylineTint(.white.opacity(0.3))
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: context.attributes.categoryIcon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.workoutType)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Label(
                        "\(context.state.exerciseCount) øvelser",
                        systemImage: "dumbbell.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                    if !context.state.isRunning {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                WorkoutTimerText(state: context.state)
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                Text("tid")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Timer

/// Counts up from the workout start while running, and stands still at the paused time while paused.
private struct WorkoutTimerText: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if let pausedAt = state.pausedAt {
            Text(timerInterval: state.timerStart...pausedAt, pauseTime: pausedAt, countsDown: false)
        } else {
            Text(state.timerStart, style: .timer)
        }
    }
}

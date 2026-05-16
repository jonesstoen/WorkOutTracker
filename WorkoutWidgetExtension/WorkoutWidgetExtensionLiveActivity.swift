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
                        Text(timerDate(context: context), style: .timer)
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
                Text(timerDate(context: context), style: .timer)
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

    private func timerDate(context: ActivityViewContext<WorkoutActivityAttributes>) -> Date {
        Date(timeIntervalSinceNow: -(context.state.elapsed))
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
                Text(timerDate, style: .timer)
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

    private var timerDate: Date {
        Date(timeIntervalSinceNow: -(context.state.elapsed))
    }
}

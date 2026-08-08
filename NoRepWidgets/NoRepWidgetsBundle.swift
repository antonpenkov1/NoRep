import WidgetKit
import SwiftUI
import ActivityKit

@main
struct NoRepWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color(red: 0.05, green: 0.05, blue: 0.07).opacity(0.9))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.blockTitle)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(context.state.label)
                            .font(.headline.weight(.black))
                            .foregroundStyle(phaseColor(context.state))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: context.state)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(maxWidth: 90, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let rounds = context.state.roundsText {
                        Text("\(rounds) rounds")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .foregroundStyle(phaseColor(context.state))
            } compactTrailing: {
                TimerText(state: context.state)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(phaseColor(context.state))
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .foregroundStyle(phaseColor(context.state))
            }
        }
    }
}

private struct LockScreenView: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(state.blockTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(state.label)
                    .font(.title3.weight(.black))
                    .foregroundStyle(phaseColor(state))
                    .lineLimit(1)
                if let rounds = state.roundsText {
                    Text("\(rounds) rounds")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            TimerText(state: state)
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .frame(maxWidth: 130, alignment: .trailing)
                .minimumScaleFactor(0.5)
        }
        .padding(16)
    }
}

/// Auto-ticking timer when running, frozen text when paused.
private struct TimerText: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        if state.isPaused {
            Text(state.pausedTimeText)
        } else if let endDate = state.endDate {
            Text(timerInterval: state.startDate...endDate, countsDown: true)
                .multilineTextAlignment(.trailing)
        } else {
            Text(state.startDate, style: .timer)
                .multilineTextAlignment(.trailing)
        }
    }
}

private func phaseColor(_ state: WorkoutActivityAttributes.ContentState) -> Color {
    switch state.kind {
    case "work": return Color(red: 0.24, green: 0.86, blue: 0.44)
    case "rest": return Color(red: 0.27, green: 0.60, blue: 1.0)
    default: return Color(red: 1.0, green: 0.78, blue: 0.22)
    }
}

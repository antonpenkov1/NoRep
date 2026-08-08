import SwiftUI

struct WatchWorkoutView: View {
    @StateObject private var manager = WatchWorkoutManager()
    @Environment(\.dismiss) private var dismiss
    private let plan: WorkoutPlan

    init(plan: WorkoutPlan) {
        self.plan = plan
    }

    var body: some View {
        Group {
            if manager.display.isFinished {
                summary
            } else {
                timer
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { manager.start(plan: plan) }
    }

    private var timer: some View {
        VStack(spacing: 4) {
            Text(manager.display.label)
                .font(.system(.caption, design: .rounded).weight(.black))
                .foregroundStyle(phaseColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(manager.display.timeText)
                .font(.system(size: 54, weight: .bold, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: true))

            if let rounds = manager.display.roundsText {
                Text("\(rounds) rounds")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
            } else {
                Text(manager.display.totalText)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if manager.display.isPaused {
                Text("PAUSED")
                    .font(.system(.caption2, design: .rounded).weight(.black))
                    .foregroundStyle(.yellow)
            }

            HStack(spacing: 8) {
                Button {
                    manager.finish()
                } label: {
                    Image(systemName: "flag.checkered")
                }
                .tint(.red)

                Button {
                    manager.togglePause()
                } label: {
                    Image(systemName: manager.display.isPaused ? "play.fill" : "pause.fill")
                }
                .tint(.gray)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if manager.display.showsRoundButton {
                manager.addRound()
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 30))
                .foregroundStyle(.green)
            Text(manager.display.totalText)
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
            if let rounds = manager.display.roundsText {
                Text("\(rounds) rounds")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
            }
            Text("Saved to iPhone journal")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    private var phaseColor: Color {
        switch manager.display.kind {
        case "work": return .green
        case "rest": return .blue
        default: return .yellow
        }
    }
}

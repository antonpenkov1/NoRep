import SwiftUI

struct WatchHomeView: View {

    var body: some View {
        List {
            Section("Quick start") {
                NavigationLink(value: WatchConfig(type: .emom)) {
                    row("EMOM", detail: "Rounds × interval", color: .red)
                }
                NavigationLink(value: WatchConfig(type: .amrap)) {
                    row("AMRAP", detail: "Tap to count rounds", color: .green)
                }
                NavigationLink(value: WatchConfig(type: .forTime)) {
                    row("For Time", detail: "Race the cap", color: .orange)
                }
                NavigationLink(value: WatchConfig(type: .tabata)) {
                    row("Tabata", detail: "8 × 20/10", color: .blue)
                }
            }
        }
        .navigationTitle("NoRep")
        .navigationDestination(for: WatchConfig.self) { config in
            WatchConfigView(config: config)
        }
        .navigationDestination(for: WorkoutPlan.self) { plan in
            WatchWorkoutView(plan: plan)
        }
    }

    private func row(_ title: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(color)
            Text(detail)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct WatchConfig: Hashable {
    var type: WorkoutType
}

struct WatchConfigView: View {
    let config: WatchConfig

    @State private var rounds = 10
    @State private var minutes = 10
    @State private var intervalSeconds = 60
    @State private var tabataRounds = 8

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                switch config.type {
                case .emom:
                    Stepper("Rounds: \(rounds)", value: $rounds, in: 1...60)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                    Stepper("Every: \(intervalSeconds)s", value: $intervalSeconds, in: 20...300, step: 10)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                case .amrap, .forTime:
                    Stepper("Minutes: \(minutes)", value: $minutes, in: 1...90)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                case .tabata:
                    Stepper("Rounds: \(tabataRounds)", value: $tabataRounds, in: 1...20)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                case .mix:
                    EmptyView()
                }

                NavigationLink(value: plan) {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(config.type.title)
    }

    private var plan: WorkoutPlan {
        let block: WorkoutBlock
        switch config.type {
        case .emom: block = .emom(EmomConfig(rounds: rounds, interval: TimeInterval(intervalSeconds)))
        case .amrap: block = .amrap(AmrapConfig(duration: TimeInterval(minutes * 60)))
        case .forTime: block = .forTime(ForTimeConfig(isCapEnabled: true, timeCap: TimeInterval(minutes * 60)))
        case .tabata: block = .tabata(TabataConfig(rounds: tabataRounds, work: 20, rest: 10))
        case .mix: block = .amrap(AmrapConfig())
        }
        return WorkoutPlan(type: config.type, blocks: [MixBlock(block: block)], countdown: 5)
    }
}

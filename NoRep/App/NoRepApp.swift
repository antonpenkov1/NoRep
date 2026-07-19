import SwiftUI

@main
struct NoRepApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView(router: router)
                    .navigationDestination(for: Route.self) { route in
                        router.destination(for: route)
                    }
            }
            .preferredColorScheme(.dark)
            .tint(Theme.accent)
            .onAppear { handleDemoRoute() }
        }
    }

    /// Screenshot automation: `simctl launch ... -DemoRoute <name>` opens a scene
    /// with demo data. Compiled out of release builds.
    private func handleDemoRoute() {
        #if DEBUG
        guard let demo = UserDefaults.standard.string(forKey: "DemoRoute") else { return }
        let defaults = SetupDefaultsStore.shared
        let route: Route?
        switch demo {
        case "setup-tabata":
            route = .setup(.tabata)
        case "workout-emom":
            route = .workout(WorkoutPlan(
                type: .emom,
                blocks: [.emom(EmomConfig(rounds: 10, interval: 60))],
                countdown: 0
            ))
        case "workout-tabata":
            route = .workout(WorkoutPlan(
                type: .tabata,
                blocks: [.tabata(TabataConfig())],
                countdown: 0
            ))
        case "mix":
            defaults.mixBlocks = [
                MixBlock(block: .amrap(AmrapConfig(duration: 600))),
                MixBlock(block: .rest(120)),
                MixBlock(block: .emom(EmomConfig(rounds: 8, interval: 60))),
                MixBlock(block: .tabata(TabataConfig()))
            ]
            route = .mixBuilder
        case "history":
            let history = HistoryStore.shared
            history.clear()
            history.add(WorkoutResult(date: Date().addingTimeInterval(-3 * 86400), title: "Tabata", detail: "TABATA 8 × 20s / 10s", totalSeconds: 230, rounds: nil))
            history.add(WorkoutResult(date: Date().addingTimeInterval(-2 * 86400), title: "Mix", detail: "AMRAP 10:00 · REST 2:00 · EMOM 8 × 1:00", totalSeconds: 1200, rounds: 14))
            history.add(WorkoutResult(date: Date().addingTimeInterval(-86400), title: "For Time", detail: "FOR TIME cap 12:00", totalSeconds: 583, rounds: 5))
            history.add(WorkoutResult(date: Date().addingTimeInterval(-3600), title: "AMRAP", detail: "AMRAP 12:00", totalSeconds: 720, rounds: 11))
            route = .history
        default:
            route = nil
        }
        if let route {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                router.push(route)
            }
        }
        #endif
    }
}

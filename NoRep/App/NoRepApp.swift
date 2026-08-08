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
        case "settings":
            route = .settings
        case "workout-emom":
            route = .workout(WorkoutPlan(
                type: .emom,
                blocks: [MixBlock(block: .emom(EmomConfig(rounds: 10, interval: 60)), note: "12 wall balls + 8 burpees")],
                countdown: 0
            ))
        case "workout-tabata":
            route = .workout(WorkoutPlan(
                type: .tabata,
                blocks: [MixBlock(block: .tabata(TabataConfig()), note: "Air squats — all out")],
                countdown: 0
            ))
        case "workout-sprint":
            // Finishes in seconds; seeded prior attempt makes the PR banner show.
            HistoryStore.shared.add(WorkoutResult(
                date: Date().addingTimeInterval(-5 * 86400),
                title: "Sprint",
                detail: "FOR TIME cap 0:10",
                totalSeconds: 25,
                typeID: WorkoutType.forTime.rawValue
            ))
            route = .workout(WorkoutPlan(
                type: .forTime,
                blocks: [MixBlock(block: .forTime(ForTimeConfig(isCapEnabled: true, timeCap: 8)), note: "400m run")],
                countdown: 0,
                customName: "Sprint"
            ))
        case "mix":
            defaults.mixBlocks = [
                MixBlock(block: .amrap(AmrapConfig(duration: 600)), note: "10 power cleans + 10 T2B"),
                MixBlock(block: .rest(120)),
                MixBlock(block: .emom(EmomConfig(rounds: 8, interval: 60)), note: "12/10 cal row"),
                MixBlock(block: .tabata(TabataConfig()), note: "Air squats")
            ]
            defaults.mixName = "Engine Day"
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

import SwiftUI

@main
struct NoRepWatchApp: App {

    init() {
        WatchSync.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if isDemoWorkout {
                    WatchWorkoutView(plan: WorkoutPlan(
                        type: .emom,
                        blocks: [MixBlock(block: .emom(EmomConfig(rounds: 10, interval: 60)))],
                        countdown: 0
                    ))
                } else {
                    WatchHomeView()
                }
            }
        }
    }

    /// Screenshot automation: `simctl launch ... -DemoWorkout 1`. Debug only.
    private var isDemoWorkout: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "DemoWorkout")
        #else
        return false
        #endif
    }
}

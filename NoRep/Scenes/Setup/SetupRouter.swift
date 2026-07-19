import Foundation

@MainActor
protocol SetupRoutingLogic {
    func routeToWorkout(plan: WorkoutPlan)
}

@MainActor
final class SetupRouter: SetupRoutingLogic {

    private weak var appRouter: AppRouter?

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func routeToWorkout(plan: WorkoutPlan) {
        appRouter?.push(.workout(plan))
    }
}

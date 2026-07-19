import Foundation

@MainActor
protocol MixBuilderRoutingLogic {
    func routeToWorkout(plan: WorkoutPlan)
}

@MainActor
final class MixBuilderRouter: MixBuilderRoutingLogic {

    private weak var appRouter: AppRouter?

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func routeToWorkout(plan: WorkoutPlan) {
        appRouter?.push(.workout(plan))
    }
}

import Foundation

@MainActor
protocol WorkoutRoutingLogic {
    func routeToRoot()
}

@MainActor
final class WorkoutRouter: WorkoutRoutingLogic {

    private weak var appRouter: AppRouter?

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func routeToRoot() {
        appRouter?.popToRoot()
    }
}

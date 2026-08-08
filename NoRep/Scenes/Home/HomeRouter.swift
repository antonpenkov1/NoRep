import Foundation

@MainActor
protocol HomeRoutingLogic {
    func routeToSetup(type: WorkoutType)
    func routeToMixBuilder()
    func routeToHistory()
    func routeToSettings()
}

@MainActor
final class HomeRouter: HomeRoutingLogic {

    private weak var appRouter: AppRouter?

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func routeToSetup(type: WorkoutType) {
        appRouter?.push(.setup(type))
    }

    func routeToMixBuilder() {
        appRouter?.push(.mixBuilder)
    }

    func routeToHistory() {
        appRouter?.push(.history)
    }

    func routeToSettings() {
        appRouter?.push(.settings)
    }
}

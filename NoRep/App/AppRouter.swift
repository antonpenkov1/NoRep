import SwiftUI

enum Route: Hashable {
    case setup(WorkoutType)
    case mixBuilder
    case workout(WorkoutPlan)
    case history
    case settings
}

/// Owns the navigation stack. Scene routers push routes through it,
/// keeping navigation concerns out of interactors and presenters.
@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .setup(let type):
            SetupView(type: type, router: self)
        case .mixBuilder:
            MixBuilderView(router: self)
        case .workout(let plan):
            WorkoutView(plan: plan, router: self)
        case .history:
            HistoryView(router: self)
        case .settings:
            SettingsView(router: self)
        }
    }
}

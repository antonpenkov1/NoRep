import SwiftUI

@main
struct NoRepWatchApp: App {

    init() {
        WatchSync.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchHomeView()
            }
        }
    }
}

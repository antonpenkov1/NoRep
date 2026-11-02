import UIKit

/// Portrait everywhere; the running workout screen unlocks landscape so the
/// clock can be read from across the gym.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}

@MainActor
enum OrientationLock {
    static var mask: UIInterfaceOrientationMask = .portrait

    static func allowLandscape() {
        var request: UIInterfaceOrientationMask?
        #if DEBUG
        // Screenshot automation: `-ForceLandscape 1` rotates the workout screen.
        if UserDefaults.standard.bool(forKey: "ForceLandscape") { request = .landscapeRight }
        #endif
        apply(.allButUpsideDown, request: request)
    }

    /// Explicit rotation from the workout screen. Works even when the iPhone's
    /// portrait orientation lock is on, which blocks rotation by tilting.
    static func rotate(toLandscape: Bool) {
        apply(.allButUpsideDown, request: toLandscape ? .landscapeRight : .portrait)
    }

    static func lockPortrait() {
        apply(.portrait, request: .portrait)
    }

    private static func apply(_ newMask: UIInterfaceOrientationMask, request: UIInterfaceOrientationMask?) {
        mask = newMask
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            if let request {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: request)) { _ in }
            }
        }
    }
}

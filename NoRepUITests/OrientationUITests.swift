import XCTest

/// Rotation on a real phone comes from tilting it, not from code.
/// XCUIDevice.orientation simulates exactly that tilt.
final class OrientationUITests: XCTestCase {
    private func launchWorkout() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-DemoRoute", "workout-emom"]
        app.launch()
        // The simulator keeps its last orientation between runs.
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["Landscape"].waitForExistence(timeout: 10), "workout screen did not open")
        return app
    }

    private func isLandscape(_ app: XCUIApplication) -> Bool {
        let frame = app.windows.firstMatch.frame
        return frame.width > frame.height
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testTiltRotatesWorkout() {
        let app = launchWorkout()
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        snap("tilt-landscape")
        XCTAssertTrue(isLandscape(app), "tilting did not rotate the workout screen")
        XCUIDevice.shared.orientation = .portrait
    }

    func testButtonRotatesWorkout() {
        let app = launchWorkout()
        app.buttons["Landscape"].tap()
        sleep(2)
        snap("button-landscape")
        XCTAssertTrue(isLandscape(app), "landscape button did not rotate")
        app.buttons["Portrait"].tap()
        sleep(2)
        XCTAssertFalse(isLandscape(app), "portrait button did not rotate back")
    }
}

import XCTest

/// Captures one full set of App Store screenshots on whatever simulator the
/// test is invoked on. Driven by the `bin/take-screenshots.sh` script that
/// loops over device configurations.
///
/// Each test method launches the app with `SCREENSHOT_SCENE` set to the scene
/// it wants to capture, waits a beat for the UI to settle, then attaches a
/// full-screen screenshot to the test result. The shell runner extracts the
/// PNG attachment and renames it.
final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_capture_menu()    throws { try capture(scene: "menu") }

    @MainActor
    func test_capture_game()    throws { try capture(scene: "game") }

    @MainActor
    func test_capture_layouts() throws { try capture(scene: "layouts") }

    @MainActor
    func test_capture_stats()   throws { try capture(scene: "stats") }

    @MainActor
    func test_capture_win()     throws { try capture(scene: "win") }

    // MARK: - Helpers

    @MainActor
    private func capture(scene: String) throws {
        let app = XCUIApplication()
        app.launchEnvironment["SCREENSHOT_SCENE"] = scene
        app.launch()

        // Allow async startup tasks (sound warmup, screenshot priming, scene
        // routing) to settle before grabbing the frame.
        sleep(2)

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "scene-\(scene)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

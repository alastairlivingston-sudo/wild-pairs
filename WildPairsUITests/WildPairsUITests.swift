import XCTest

// Critical-journey UI tests (testing-strategy.md §6, UIT-01..09). These run only on a Mac
// simulator (XCUITest is Apple-only). They target the accessibility identifiers set in the
// SwiftUI views and assert that the core flow is reachable, not visual styling.

final class WildPairsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    // UIT-01: App launches to the home screen.
    func testLaunchesToHome() {
        let app = launch()
        XCTAssertTrue(app.buttons["home-new-game"].waitForExistence(timeout: 5))
    }

    // UIT-03 / UIT-04: Start a Standard Teams game and reach the game table.
    func testStartGameReachesTable() {
        let app = launch()
        app.buttons["home-new-game"].tap()
        let start = app.buttons["newgame-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        // The prompt banner and pause button confirm we are on the game table.
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["game-prompt"].exists || app.staticTexts["game-prompt"].exists)
    }

    // UIT-06: The draw pile is reachable on the table.
    func testDrawPilePresent() {
        let app = launch()
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        XCTAssertTrue(app.buttons["game-draw-card-button"].waitForExistence(timeout: 5))
    }

    // UIT-09: Pause then resume preserves the table.
    func testPauseAndResume() {
        let app = launch()
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        let pause = app.buttons["game-pause-button"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.tap()
        let resume = app.buttons["Resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 3))
        resume.tap()
        XCTAssertTrue(pause.waitForExistence(timeout: 3))
    }

    // Landscape layout: the table must remain fully reachable (no clipped/overflowing
    // controls) when rotated. Verifies the GameTableView GeometryReader + ScrollView fix.
    func testGameTableSurvivesLandscapeRotation() {
        // However this test exits, the device must end up back in portrait — leaving it
        // stuck in landscape breaks every other test in the suite (e.g. NewGameFlowView's
        // "Start" button scrolls out of reach in a short landscape window).
        defer { XCUIDevice.shared.orientation = .portrait }

        let app = launch()
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        let pause = app.buttons["game-pause-button"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .landscapeLeft
        // Give SwiftUI a beat to re-layout after the rotation.
        Thread.sleep(forTimeInterval: 0.5)

        // Every critical control must still be hittable on-screen post-rotation.
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["game-pause-button"].isHittable, "Pause button not reachable in landscape")
        XCTAssertTrue(app.buttons["game-draw-card-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["game-draw-card-button"].isHittable, "Draw pile not reachable in landscape")

        // All four seats (left/partner/right opponents + the table itself) must be reachable —
        // regression check for a bug where the partner seat's name/badge silently failed to
        // render in the landscape single-row layout when its open hand used CardView at a
        // too-small size (cardBackSize instead of a dedicated openHandCardSize).
        for seatPosition in [1, 2, 3] {
            let zone = app.descendants(matching: .any)["seat-\(seatPosition)"]
            XCTAssertTrue(zone.waitForExistence(timeout: 3), "seat-\(seatPosition) not found in landscape")
            XCTAssertTrue(zone.isHittable, "seat-\(seatPosition) not reachable in landscape")
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "game-table-landscape"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

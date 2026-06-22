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
}

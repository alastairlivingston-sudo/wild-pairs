import XCTest

// Phase 7 performance/memory pass (docs/phase-6-8-brief.md): launch time, memory growth
// across many rounds, and save/resume after backgrounding. Each test records an XCTest
// metric so results show up in the .xcresult performance report, not just pass/fail.

final class WildPairsPerformanceTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func dismissOnboardingIfPresent(_ app: XCUIApplication) {
        let skip = app.buttons["onboarding-skip"]
        if skip.waitForExistence(timeout: 2) {
            skip.tap()
        }
    }

    /// `measure` re-invokes its block several times in the same app process (no relaunch
    /// between iterations), so each call must start from a known state — end any game
    /// already in progress from a prior iteration before starting a fresh one.
    private func returnToHomeIfNeeded(_ app: XCUIApplication) {
        guard app.buttons["game-pause-button"].exists else { return }
        app.buttons["game-pause-button"].tap()
        app.buttons["pause-end-game"].tap()
        let confirmEndGame = app.alerts.buttons["End game"]
        if confirmEndGame.waitForExistence(timeout: 2) { confirmEndGame.tap() }
        XCTAssertTrue(app.buttons["home-new-game"].waitForExistence(timeout: 5))
    }

    private func playSeveralRounds(_ app: XCUIApplication, count: Int) {
        returnToHomeIfNeeded(app)
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5))

        let draw = app.buttons["game-draw-card-button"]
        let nextRound = app.buttons["roundend-next"]
        let backToHome = app.buttons["End game"]
        var roundsSeen = 0
        let deadline = Date().addingTimeInterval(Double(count) * 60)

        while roundsSeen < count, Date() < deadline {
            if nextRound.exists {
                roundsSeen += 1
                if roundsSeen >= count { break }
                nextRound.tap()
            } else if backToHome.exists {
                break
            } else if draw.exists, draw.isEnabled, draw.frame.width > 0 {
                draw.tap()
            }
            usleep(150_000)
        }
    }

    // Cold launch time (ux-spec.md / testing-strategy.md performance budget reference).
    func testColdLaunchPerformance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        let metric = XCTApplicationLaunchMetric()
        measure(metrics: [metric]) {
            app.launch()
        }
    }

    // Memory growth across several full rounds — flags an obvious per-round leak (e.g. an
    // uncancelled Task, a retained closure) without needing Instruments attached.
    func testMemoryAcrossMultipleRounds() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()
        dismissOnboardingIfPresent(app)

        measure(metrics: [XCTMemoryMetric()]) {
            playSeveralRounds(app, count: 3)
        }
    }

    // Save/resume after backgrounding: send the app to the background (simulating the user
    // switching apps or the system suspending it), bring it back, and confirm the game table
    // is exactly where they left it rather than resetting or losing state.
    func testResumeAfterBackgrounding() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()
        dismissOnboardingIfPresent(app)
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5))

        let roundLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Round'")).firstMatch
        let roundTextBefore = roundLabel.exists ? roundLabel.label : nil
        let drawCountBefore = app.buttons["game-draw-card-button"].label

        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()

        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 10),
                      "Game table should restore after backgrounding, not return to Home")
        if let roundTextBefore {
            XCTAssertEqual(roundLabel.label, roundTextBefore, "Round number should survive backgrounding")
        }
        XCTAssertEqual(app.buttons["game-draw-card-button"].label, drawCountBefore,
                       "Draw pile count should be unchanged by backgrounding alone")
    }
}

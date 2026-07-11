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
        // `playSeveralRounds` deliberately leaves the round-end overlay showing once it has
        // seen `count` rounds (it breaks before tapping "Next round") — the next `measure`
        // iteration starts from that overlay, not the live table, so exit via its own button
        // rather than the pause menu (the overlay is modal and swallows the pause tap).
        let roundEndExit = app.buttons["End game"]
        if roundEndExit.exists {
            roundEndExit.tap()
            XCTAssertTrue(app.buttons["home-new-game"].waitForExistence(timeout: 5))
            return
        }
        guard app.buttons["game-pause-button"].exists else { return }
        app.buttons["game-pause-button"].tap()
        XCTAssertTrue(app.buttons["pause-end-game"].waitForExistence(timeout: 3))
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
        // A move-timed-out human move can play a wild, leaving a colour choice pending — the
        // move timer is then gated off, so the drive loop must resolve it or the round stalls.
        let colourPick = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'colour-pick-'")).firstMatch
        var roundsSeen = 0
        // Human turns advance on the move timer (drawing no-ops when a legal play exists), so a
        // round can run to its ~3-minute timer backstop; budget generously past it.
        let deadline = Date().addingTimeInterval(Double(count) * 90)

        while roundsSeen < count, Date() < deadline {
            if nextRound.exists {
                roundsSeen += 1
                if roundsSeen >= count { break }
                nextRound.tap()
            } else if backToHome.exists {
                break
            } else if colourPick.exists {
                colourPick.tap()
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
        app.launchArguments = ["--uitest-reset-state", "--uitest-fast-timers"]
        app.launch()
        dismissOnboardingIfPresent(app)

        // One measured pass over two rounds: enough to catch a memory blow-up across rounds
        // without a 15-round (5 iterations × 3 rounds) runtime now that human turns are
        // move-timer-paced (see playSeveralRounds).
        let options = XCTMeasureOptions()
        options.iterationCount = 1
        measure(metrics: [XCTMemoryMetric()], options: options) {
            playSeveralRounds(app, count: 2)
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

        // Pause before capturing the draw-pile label: AI turns run on their own timers, so an
        // unpaused label can legally change (e.g. a Draw-Two stack growing) between capture and
        // re-read. Paused, the state is frozen — any change across backgrounding is a real bug.
        app.buttons["game-pause-button"].tap()
        let resumeButton = app.buttons["Resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 3))

        let drawButton = app.buttons["game-draw-card-button"]
        XCTAssertTrue(drawButton.exists, "Draw pile should be queryable behind the pause sheet")
        let drawCountBefore = drawButton.label

        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()

        XCTAssertTrue(resumeButton.waitForExistence(timeout: 10),
                      "Paused game should restore after backgrounding, not return to Home")
        XCTAssertEqual(drawButton.label, drawCountBefore,
                       "Draw pile count should be unchanged by backgrounding alone")

        resumeButton.tap()
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5),
                      "Game table should restore after resuming")
        if let roundTextBefore {
            XCTAssertEqual(roundLabel.label, roundTextBefore, "Round number should survive backgrounding")
        }
    }
}

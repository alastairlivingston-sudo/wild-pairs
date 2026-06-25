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
        dismissOnboardingIfPresent(app)
        return app
    }

    /// On first launch (or after an erase) the onboarding overlay covers the home screen.
    /// Every other test cares about what's underneath, so skip through it via Skip.
    private func dismissOnboardingIfPresent(_ app: XCUIApplication) {
        let skip = app.buttons["onboarding-skip"]
        if skip.waitForExistence(timeout: 2) {
            skip.tap()
        }
    }

    // UIT-01: App launches to the home screen.
    func testLaunchesToHome() {
        let app = launch()
        XCTAssertTrue(app.buttons["home-new-game"].waitForExistence(timeout: 5))
    }

    // First-launch onboarding: shows automatically, walks through all pages, and dismissing
    // it (either via Skip or finishing) never shows it again this session.
    func testOnboardingShowsOnceAndDismisses() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()

        let next = app.buttons["onboarding-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5), "Onboarding should show on first launch")

        // Walk through every page via Next; the last page's button reads "Let's play".
        for _ in 0..<4 {
            guard next.exists else { break }
            next.tap()
        }

        XCTAssertTrue(app.buttons["home-new-game"].waitForExistence(timeout: 5),
                      "Home screen should be reachable once onboarding finishes")
        XCTAssertFalse(app.buttons["onboarding-next"].exists, "Onboarding must not reappear after finishing")
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

    // Colour-blind mode + pattern fills: enabling both must not crash or hide the table,
    // and the cards should render with the colour-name label visible (pattern texture
    // itself isn't asserted pixel-by-pixel here — see the attached screenshot).
    func testColourBlindModeAndPatternFillsOnTable() {
        // Settings persist across test runs in the same installed app; reset so the
        // toggles start from a known (off) state rather than whatever a prior run left.
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()
        dismissOnboardingIfPresent(app)
        app.buttons["home-settings"].tap()

        // SwiftUI Form Toggle rows expose an outer row-level Switch (carrying the
        // identifier) and an inner control Switch; only a tap landing on the inner
        // control's frame actually flips the value, so tap the row's right edge where
        // the visual knob renders rather than the row centre or its label.
        let colourBlind = app.switches["settings-colourblind-toggle"]
        XCTAssertTrue(colourBlind.waitForExistence(timeout: 5))
        colourBlind.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()

        let patternFills = app.switches["settings-patternfills-toggle"]
        XCTAssertTrue(patternFills.waitForExistence(timeout: 3))
        patternFills.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()  // back to Home
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()

        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["game-draw-card-button"].isHittable)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "colourblind-pattern-fills-table"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // Sound coordinator: toggling sound effects off must not crash or break play — the
    // coordinator should simply stop playing, gated purely on the settings flag.
    func testSoundToggleAndGameStillPlayable() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()
        dismissOnboardingIfPresent(app)
        app.buttons["home-settings"].tap()

        let soundToggle = app.switches["settings-sound-toggle"]
        XCTAssertTrue(soundToggle.waitForExistence(timeout: 5))
        soundToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()  // back to Home
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()

        let pause = app.buttons["game-pause-button"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["game-draw-card-button"].isHittable)
        app.buttons["game-draw-card-button"].tap()
        XCTAssertTrue(pause.isHittable, "Table should remain responsive with sound disabled")
    }
}

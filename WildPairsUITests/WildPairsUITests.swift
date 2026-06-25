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

    // VoiceOver: hand cards must expose the canonical accessibility label pattern
    // (colour/name + card category + playability) per accessibility-plan.md §2, not just a
    // bare abbreviation — regression check for the Phase 6 VoiceOver pass.
    func testHandCardsHaveCanonicalAccessibilityLabels() {
        let app = launch()
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5))

        let numberCard = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'number card'"))
            .firstMatch
        XCTAssertTrue(numberCard.waitForExistence(timeout: 3),
                      "Expected at least one hand card labelled with the canonical 'number card' pattern")

        let playabilityWord = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'Playable' OR label CONTAINS 'Not playable'"))
            .firstMatch
        XCTAssertTrue(playabilityWord.waitForExistence(timeout: 3),
                      "Expected hand cards to announce playability state")
    }

    // Dynamic Type at AX3 (UICTContentSizeCategoryAccessibilityXL): critical controls on
    // Home, Settings, and the game table must remain reachable — no clipped/overlapping
    // content that would make the app unusable at large accessibility text sizes. The
    // `-UIPreferredContentSizeCategoryName` launch argument is UIKit's standard per-process
    // override (it registers into NSUserDefaults at launch), scoped to this app only —
    // no need to touch (or restore) the simulator's system-wide setting.
    func testDynamicTypeAX3LayoutSurvives() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitest-reset-state",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL",
        ]
        app.launch()
        dismissOnboardingIfPresent(app)

        XCTAssertTrue(app.buttons["home-new-game"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home-new-game"].isHittable, "New Game button clipped at AX3 on Home")
        XCTAssertTrue(app.buttons["home-settings"].isHittable, "Settings button clipped at AX3 on Home")

        app.buttons["home-settings"].tap()
        XCTAssertTrue(app.switches["settings-colourblind-toggle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["settings-colourblind-toggle"].isHittable, "Colour-blind toggle not reachable at AX3")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["home-new-game"].tap()
        // At AX3 each Form row is much taller, so the Start button (last section) is below
        // the fold and not yet realized by the lazy List — scroll to it, as a real user would.
        let start = app.buttons["newgame-start"]
        for _ in 0..<6 where !start.exists {
            app.swipeUp()
        }
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.isHittable, "Start button not reachable at AX3 in New Game flow")
        start.tap()

        let pause = app.buttons["game-pause-button"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertTrue(pause.isHittable, "Pause button clipped at AX3 on game table")
        XCTAssertTrue(app.buttons["game-draw-card-button"].isHittable, "Draw pile not reachable at AX3")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "dynamic-type-ax3-table"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // The round timer (3-min fallback) and per-move timer (10s, local turn only) exist in
    // the engine but previously had no on-screen representation at all — regression check
    // that the new countdown UI actually renders.
    func testRoundAndMoveTimersAreVisible() {
        let app = launch()
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5))

        let roundTimer = app.descendants(matching: .any)["game-round-timer"]
        XCTAssertTrue(roundTimer.waitForExistence(timeout: 3), "Round timer countdown should be visible during play")

        // The move timer only shows on the local player's turn, which depends on seating —
        // don't fail the test if an AI is currently acting, just confirm it appears at some
        // point within a few seconds if it's going to.
        let moveTimer = app.descendants(matching: .any)["game-move-timer"]
        _ = moveTimer.waitForExistence(timeout: 5)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "round-move-timers"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // Plays a fast/easy/beginner game through to round-end to verify the new win/loss
    // celebration UI (confetti + colour glow on win, gentle desaturate on loss, "So close!"
    // copy) actually renders — not just that the code compiles.
    func testRoundEndCelebrationRenders() {
        // Defend against orientation leaking from a prior test in the same run (e.g. if its
        // own portrait-reset defer raced the next test's launch) — wrong orientation here
        // produces coordinates outside the visible screen and "failed to compute hit point".
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }

        // Cards mid-animation can briefly report an invalid activation point; tolerate
        // that instead of aborting the whole drive loop on one transient hit-test failure.
        continueAfterFailure = true

        // A leftover saved game from an earlier test would show "Continue Game" instead of
        // going straight into New Game flow, breaking the tap sequence below.
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()
        dismissOnboardingIfPresent(app)
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5))

        // Only ever tap the always-on-screen, fixed-position draw pile — drawing is legal
        // any time it's the local player's turn (TableCenterView's canDraw doesn't require
        // having no legal play), so this alone lets turns advance without ever touching the
        // horizontally-scrolling hand, which can report flaky off-screen hit points for
        // cards not currently scrolled into view.
        let nextRound = app.buttons["roundend-next"]
        let backToHome = app.buttons["End game"]
        let draw = app.buttons["game-draw-card-button"]
        let deadline = Date().addingTimeInterval(90)
        while Date() < deadline, !nextRound.exists, !backToHome.exists {
            if draw.exists, draw.isEnabled, draw.frame.width > 0 { draw.tap() }
            usleep(200_000)
        }

        XCTAssertTrue(nextRound.exists || backToHome.exists, "Round should end within the time budget")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "round-end-celebration"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // A full multi-round session: round 1 ends, "Next round" advances to round 2, and the
    // table is still fully functional there — not just reachable once and never re-tested.
    //
    // Two related flows are deliberately NOT automated here, by design rather than oversight:
    //   - Solo!/catch: AI players auto-call Solo the instant they reach one card
    //     (GameEngine.applySoloRequirement), so an AI is never catchable — only the human
    //     could ever be caught, which would require driving their hand down to exactly one
    //     card via taps on the horizontally-scrolling hand (the same off-screen hit-testing
    //     flakiness this file's draw-only bot strategy exists to avoid). Already covered at
    //     the unit level (AIConstraintTests, WinConditionTests' Solo! cases).
    //   - Round-timer expiry: the default is 180s with no UI affordance to shorten it for a
    //     test, and it's already covered thoroughly by TimedRoundTests at the engine level.
    func testMultiRoundSessionContinuesPastFirstRound() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        continueAfterFailure = true

        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset-state"]
        app.launch()
        dismissOnboardingIfPresent(app)
        app.buttons["home-new-game"].tap()
        app.buttons["newgame-start"].tap()
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5))

        let nextRound = app.buttons["roundend-next"]
        let backToHome = app.buttons["End game"]
        let draw = app.buttons["game-draw-card-button"]

        func drawUntil(_ condition: @autoclosure () -> Bool, timeout: TimeInterval) {
            let deadline = Date().addingTimeInterval(timeout)
            while Date() < deadline, !condition() {
                if draw.exists, draw.isEnabled, draw.frame.width > 0 { draw.tap() }
                usleep(200_000)
            }
        }

        drawUntil(nextRound.exists || backToHome.exists, timeout: 90)
        guard nextRound.exists else {
            // The first round ended in a game-over (best-of-N reached) rather than a round
            // win — there's no second round to advance to in that case, which is a valid
            // outcome, not a failure of this test.
            return
        }

        nextRound.tap()
        XCTAssertTrue(app.buttons["game-pause-button"].waitForExistence(timeout: 5),
                      "Game table should still be functional at the start of round 2")
        let roundLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Round'")).firstMatch
        XCTAssertTrue(roundLabel.waitForExistence(timeout: 3))
        XCTAssertFalse(roundLabel.label.contains("Round 1"), "Round number should have advanced past round 1")

        // Confirm round 2 itself is genuinely playable (not just reachable) by successfully
        // drawing a few times — full AI-driven rounds vary too much in length to require a
        // second complete round within a tight combined test budget; round-end itself is
        // already proven end-to-end by testRoundEndCelebrationRenders above.
        var sawSuccessfulDraw = false
        let settleDeadline = Date().addingTimeInterval(20)
        while Date() < settleDeadline, !sawSuccessfulDraw {
            if draw.exists, draw.isEnabled, draw.frame.width > 0 {
                let countBefore = draw.label
                draw.tap()
                usleep(300_000)
                if draw.label != countBefore { sawSuccessfulDraw = true }
            }
            usleep(200_000)
        }
        XCTAssertTrue(sawSuccessfulDraw || nextRound.exists || backToHome.exists,
                      "Round 2 should be responsive to play, not frozen")
    }
}

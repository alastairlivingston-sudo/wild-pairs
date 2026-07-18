import Foundation
import Testing
@testable import WildPairsCore

/// Tier-0a regression: the per-round wall-clock timer must count down once per round, not restart
/// every turn. The view model re-invokes `RoundTimerScheduler.deadline` on every action, so the
/// key case is that an already-armed deadline is preserved rather than pushed back to a fresh full
/// limit — the bug that let the round timer (and the move-timer's final-minute clamp) never elapse.
@Suite("Round timer scheduling (Tier 0a)")
struct RoundTimerSchedulerTests {

    private let now = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test("Fresh round arms the full limit")
    func freshRound() {
        let deadline = RoundTimerScheduler.deadline(now: now, existing: nil, pausedRemaining: nil, limit: 180)
        #expect(deadline == now.addingTimeInterval(180))
    }

    @Test("A subsequent action keeps the existing deadline, not a fresh full limit")
    func doesNotResetMidRound() {
        // Two minutes into the round: 60s should remain, and stay remaining after another action.
        let existing = now.addingTimeInterval(60)
        let later = now.addingTimeInterval(0.5)   // a turn later
        let deadline = RoundTimerScheduler.deadline(now: later, existing: existing, pausedRemaining: nil, limit: 180)
        #expect(deadline == existing)             // unchanged — old bug returned later + 180
        #expect(deadline!.timeIntervalSince(later) < 61)
    }

    @Test("Resuming restores the captured remaining time")
    func resumeRestoresRemaining() {
        let deadline = RoundTimerScheduler.deadline(now: now, existing: nil, pausedRemaining: 45, limit: 180)
        #expect(deadline == now.addingTimeInterval(45))
    }

    @Test("Resume remaining is clamped to the limit")
    func resumeClampsToLimit() {
        let deadline = RoundTimerScheduler.deadline(now: now, existing: nil, pausedRemaining: 999, limit: 180)
        #expect(deadline == now.addingTimeInterval(180))
    }

    @Test("A non-positive limit disables the timer")
    func disabledWhenNoLimit() {
        #expect(RoundTimerScheduler.deadline(now: now, existing: nil, pausedRemaining: nil, limit: 0) == nil)
        #expect(RoundTimerScheduler.deadline(now: now, existing: now, pausedRemaining: 30, limit: 0) == nil)
    }
}

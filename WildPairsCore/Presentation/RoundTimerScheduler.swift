import Foundation

/// Pure policy for arming the per-round wall-clock timer (`RuleProfile.roundTimeLimitSeconds`).
///
/// The round timer is a *single* countdown per round, not a per-turn reset: once armed at the
/// start of a round it keeps counting toward the same deadline as play advances, so it can
/// actually reach its "final minute" (which the move-timer clamp keys off — game-rules.md §Round
/// Timer Fallback). The view model re-invokes the scheduler on every action; the decision below
/// keeps the existing deadline instead of pushing it back each time.
public enum RoundTimerScheduler {

    /// The absolute deadline the round timer should be armed to, or `nil` if it should not run.
    ///
    /// - Parameters:
    ///   - now: the current instant.
    ///   - existing: the in-round deadline already set, if the timer is mid-round.
    ///   - pausedRemaining: time left captured at pause, if the round is resuming.
    ///   - limit: the round time limit in seconds; `<= 0` disables the timer.
    ///
    /// A fresh round (no existing deadline, not resuming) arms the full `limit`; a subsequent
    /// action in the same round keeps `existing`; a resume restores the captured remaining time
    /// (clamped to `limit`).
    public static func deadline(
        now: Date,
        existing: Date?,
        pausedRemaining: TimeInterval?,
        limit: TimeInterval
    ) -> Date? {
        guard limit > 0 else { return nil }
        if let pausedRemaining {
            return now.addingTimeInterval(max(0, min(pausedRemaining, limit)))
        }
        if let existing {
            return existing
        }
        return now.addingTimeInterval(limit)
    }
}

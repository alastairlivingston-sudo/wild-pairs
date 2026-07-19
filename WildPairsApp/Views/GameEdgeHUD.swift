import SwiftUI
import WildPairsCore

struct GameEdgeHUD: View {
    let roundNumber: Int
    let scoreboard: [ScoreRow]
    let turnLabel: String
    let turnDirection: TurnDirection
    let roundRemaining: TimeInterval?
    let roundTotal: TimeInterval
    /// Face-to-face mirrors the countdown visually but exposes one semantic timer to VoiceOver.
    let visualMoveRemaining: TimeInterval?
    let semanticMoveRemaining: TimeInterval?
    let moveTotal: TimeInterval
    let accent: Color
    var compact = false
    var isPrimarySemantic = true
    var contentRotation: Angle = .zero
    var onPause: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: compact ? Theme.Space.s1 : Theme.Space.s2) {
            roundSummary
                .frame(minWidth: compact ? 70 : 126, alignment: .leading)

            VStack(spacing: 2) {
                scoreStrip
                turnDirectionSummary
            }
            .frame(maxWidth: .infinity)

            moveTimerSlot

            if let onPause {
                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.footnote)
                        .frame(width: 28, height: 28)
                        .wpGlassCircle()
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Pause")
                .accessibilityIdentifier("game-pause-button")
            }
        }
        .rotationEffect(contentRotation)
        .padding(.horizontal, compact ? 7 : Theme.Space.s4)
        .padding(.vertical, compact ? Theme.Space.s1 : 6)
        .frame(minHeight: compact ? Theme.Table.compactEdgeHUDHeight : Theme.Table.edgeHUDHeight)
        .background(Color.black.opacity(0.68))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)
                .accessibilityHidden(true)
        }
        .accessibilityHidden(!isPrimarySemantic)
    }

    private var roundSummaryContent: some View {
        HStack(spacing: compact ? Theme.Space.s1 : Theme.Space.s2) {
            Text(compact ? "R\(roundNumber)" : "ROUND \(roundNumber)")
                .font(.system(size: compact ? 8 : 9, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .tracking(compact ? 0.45 : 0.7)
                .lineLimit(1)

            if let roundRemaining {
                GameRoundClock(
                    remaining: roundRemaining,
                    total: roundTotal,
                    accent: accent,
                    compact: compact
                )
            }
        }
    }

    @ViewBuilder private var roundSummary: some View {
        if isPrimarySemantic, let roundRemaining {
            roundSummaryContent
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "Round \(roundNumber), time remaining \(clockLabel(roundRemaining))"
                )
                .accessibilityIdentifier("game-round-timer")
        } else {
            roundSummaryContent
                .accessibilityHidden(true)
        }
    }

    private var scoreStrip: some View {
        HStack(spacing: compact ? 5 : Theme.Space.s2) {
            ForEach(Array(scoreboard.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: Theme.Space.s1) {
                    Circle()
                        .fill(index == 0 ? Theme.Palette.teamA : Theme.Palette.teamB)
                        .frame(width: 7, height: 7)
                    Text(compact ? "\(index == 0 ? "A" : "B") \(row.score)" : "\(row.displayName) \(row.score)")
                        .font(.system(size: compact ? 8 : 10, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
        }
        .foregroundStyle(.white.opacity(0.88))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scoreAccessibilityLabel)
    }

    private var turnDirectionContent: some View {
        HStack(spacing: compact ? 2 : Theme.Space.s1) {
            Text(turnLabel)
                .foregroundStyle(.white.opacity(0.94))
                .layoutPriority(1)

            Text("·")
                .foregroundStyle(.white.opacity(0.28))

            HStack(spacing: compact ? 1 : 3) {
                Image(systemName: turnDirection == .clockwise ? "arrow.clockwise" : "arrow.counterclockwise")
                    .foregroundStyle(accent)
                Text(turnDirection == .clockwise ? "CLOCKWISE" : "COUNTER-CLOCKWISE")
            }
            .foregroundStyle(.white.opacity(0.64))
        }
        .font(.system(size: compact ? 7 : 9, weight: .black, design: .rounded))
        .tracking(compact ? 0.05 : 0.35)
        .lineLimit(1)
        .minimumScaleFactor(0.56)
    }

    @ViewBuilder private var turnDirectionSummary: some View {
        if isPrimarySemantic {
            turnDirectionContent
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(turnLabel), \(turnDirection == .clockwise ? "clockwise" : "counter-clockwise") play"
                )
                .accessibilityIdentifier("game-turn-rail")
        } else {
            turnDirectionContent
                .accessibilityHidden(true)
        }
    }

    private var moveTimerContent: some View {
        GameMoveTimerSlot(
            remaining: visualMoveRemaining,
            total: moveTotal,
            accent: accent,
            compact: compact
        )
    }

    @ViewBuilder private var moveTimerSlot: some View {
        if isPrimarySemantic, let semanticMoveRemaining {
            moveTimerContent
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(secondsLabel(semanticMoveRemaining)) seconds left to play")
                .accessibilityIdentifier("game-move-timer")
        } else {
            moveTimerContent
                .accessibilityHidden(true)
        }
    }

    private var scoreAccessibilityLabel: String {
        scoreboard.map { "\($0.displayName) \($0.score)" }.joined(separator: ", ")
    }

    private func secondsLabel(_ remaining: TimeInterval) -> Int {
        max(0, Int(remaining.rounded()))
    }

    private func clockLabel(_ remaining: TimeInterval) -> String {
        let seconds = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct GameRoundClock: View {
    let remaining: TimeInterval
    let total: TimeInterval
    let accent: Color
    let compact: Bool

    private var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, remaining / total))
    }

    private var isUrgent: Bool { remaining <= 30 }

    private var label: String {
        let seconds = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        HStack(spacing: Theme.Space.s1) {
            ZStack {
                Circle().stroke(.white.opacity(0.16), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isUrgent ? Theme.Palette.warning : accent,
                        style: StrokeStyle(lineWidth: 2.25, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Image(systemName: "timer")
                    .font(.system(size: compact ? 8 : 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))
            }
            .frame(width: compact ? 21 : 24, height: compact ? 21 : 24)

            Text(label)
                .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isUrgent ? Theme.Palette.warning : .white.opacity(0.88))
                .lineLimit(1)
        }
    }
}

private struct GameMoveTimerSlot: View {
    let remaining: TimeInterval?
    let total: TimeInterval
    let accent: Color
    let compact: Bool

    private var progress: Double {
        guard let remaining, total > 0 else { return 0 }
        return max(0, min(1, remaining / total))
    }

    private var isUrgent: Bool {
        guard let remaining else { return false }
        return remaining <= 3
    }

    private var seconds: Int {
        guard let remaining else { return 0 }
        return max(0, Int(remaining.rounded()))
    }

    var body: some View {
        VStack(spacing: 3) {
            if remaining != nil {
                HStack(spacing: Theme.Space.s1) {
                    Text("MOVE")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.54))
                        .tracking(0.65)
                    Spacer(minLength: 0)
                    Text("\(seconds)")
                        .font(.system(size: isUrgent ? 23 : 18, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isUrgent ? Theme.Palette.warning : .white)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.12))
                        Capsule()
                            .fill(isUrgent ? Theme.Palette.warning : accent)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 5)
        .frame(
            width: compact ? Theme.Table.compactMoveTimerWidth : Theme.Table.moveTimerWidth,
            height: Theme.Table.moveTimerHeight
        )
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.r3, style: .continuous)
                .fill(.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r3, style: .continuous)
                .strokeBorder(
                    isUrgent ? Theme.Palette.warning.opacity(0.72) : .white.opacity(0.12),
                    lineWidth: 1
                )
        )
        .opacity(remaining == nil ? 0.34 : 1)
    }
}

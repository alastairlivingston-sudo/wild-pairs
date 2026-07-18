import SwiftUI
import WildPairsCore

// A non-local player's seat. Opponents are physical fanned card backs topped by a stable
// elemental crest; the partner remains an open, face-up shelf. The active-turn treatment uses
// white corner brackets plus an explicit "UP NOW" flag, so it never depends on tint alone.
struct PlayerZoneView: View {
    let seat: PlayerSeatViewState
    var showColourName: Bool = false
    var showPattern: Bool = false
    var cardBackSize: CGSize = Theme.CardSize.opponentBack
    /// Size for the partner's face-up cards. This intentionally remains independent from the
    /// compact opponent-back size because CardView needs enough room for its indices and mark.
    var openHandCardSize: CGSize = Theme.CardSize.partnerHand
    /// Maximum width the fan may occupy before overlap tightens.
    var maxFanWidth: CGFloat? = nil
    var reducedMotion: Bool = false
    var isThinking: Bool = false
    var thinkingDotCount: Int = 3
    var accent: Color = Theme.Palette.accent
    var cue: SeatCueKind? = nil
    /// Non-nil while this seat should show the one-shot "+N caught" stamp.
    var caughtPenaltyCount: Int? = nil
    var onCatchSolo: (() -> Void)? = nil

    @State private var glowPulse = false
    @State private var arrivalPop = false

    private var isOpponent: Bool { seat.visiblePartnerHand == nil }
    private var canCatchSolo: Bool { seat.needsSoloCall && onCatchSolo != nil }
    private var countUrgent: Bool { seat.handCount <= 2 }

    private var countTint: Color {
        switch seat.handCount {
        case 0, 1: return Theme.Palette.error
        case 2:    return Theme.Palette.warning
        default:   return Theme.Palette.accent
        }
    }

    var body: some View {
        seatChrome
            .overlay(activeTurnChrome)
            .overlay(cueOverlay)
            .overlay(caughtPenaltyOverlay)
            .shadow(color: glowColor, radius: glowRadius)
            .scaleEffect(arrivalPop ? 1.045 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.68), value: cue)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: caughtPenaltyCount)
            .animation(.spring(response: 0.5, dampingFraction: 0.65), value: seat.needsSoloCall)
            .onAppear { updateGlow(seat.isCurrentPlayer) }
            .onChange(of: seat.isCurrentPlayer) { _, isCurrent in
                updateGlow(isCurrent)
                if isCurrent { triggerArrivalPop() }
            }
            // Keep the test identifier and the one-element VoiceOver summary used by the existing
            // UI tests. The visible CATCH control is an affordance for the same whole-seat action.
            .contentShape(Rectangle())
            .onTapGesture { if canCatchSolo { onCatchSolo?() } }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(canCatchSolo ? "Double tap to catch the missed Solo call for a two-card penalty" : "")
            .accessibilityAddTraits(canCatchSolo ? .isButton : [])
            .accessibilityIdentifier("seat-\(seat.seatPosition)")
    }

    @ViewBuilder private var seatChrome: some View {
        if isOpponent {
            seatContent
        } else {
            seatContent
                // A shallow shelf rather than a large dashboard panel. It clarifies that these
                // cards belong to the partner while allowing the cards themselves to dominate.
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.r3, style: .continuous)
                        .fill(Color.black.opacity(0.30))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.r3, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                )
        }
    }

    private var seatContent: some View {
        VStack(spacing: Theme.Space.s1) {
            if isOpponent {
                opponentHeader
                if isThinking {
                    ThinkingDotsView(dotCount: thinkingDotCount, isStatic: reducedMotion)
                }
                opponentFan
                Text(seat.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(seat.isCurrentPlayer ? .white : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            } else {
                partnerHeader
                if isThinking {
                    ThinkingDotsView(dotCount: thinkingDotCount, isStatic: reducedMotion)
                }
                if let partnerHand = seat.visiblePartnerHand {
                    openHandFan(partnerHand)
                }
            }

            statusBadges
        }
        .padding(isOpponent ? Theme.Space.s1 : Theme.Space.s2)
        .frame(maxWidth: maxFanWidth.map { $0 + Theme.Space.s2 * 2 })
    }

    private var opponentHeader: some View {
        Image(crestAssetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 30, height: 30)
            .shadow(color: accent.opacity(seat.isCurrentPlayer ? 0.45 : 0.18), radius: 6)
            .accessibilityHidden(true)
    }

    private var partnerHeader: some View {
        HStack(spacing: Theme.Space.s2) {
            Image(crestAssetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text("PARTNER · OPEN HAND")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.82))
                    .tracking(0.35)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(seat.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(seat.isCurrentPlayer ? .white : .secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Theme.Space.s1)
            countBadge
        }
    }

    /// Stable cosmetic identity: absolute seat position maps to one crest, so the same player
    /// keeps the same emblem even when pass-and-play rotates the table perspective.
    private var crestAssetName: String {
        switch ((seat.seatPosition % 4) + 4) % 4 {
        case 0: return "solo_table_crest_lava"
        case 1: return "solo_table_crest_sky"
        case 2: return "solo_table_crest_grass"
        default: return "solo_table_crest_sun"
        }
    }

    private var crestDisplayName: String {
        switch ((seat.seatPosition % 4) + 4) % 4 {
        case 0: return "Lava"
        case 1: return "Sky"
        case 2: return "Grass"
        default: return "Sun"
        }
    }

    // MARK: Active turn

    @ViewBuilder private var activeTurnChrome: some View {
        if seat.isCurrentPlayer {
            ActiveSeatBrackets(tint: accent)
                .padding(-3)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text("UP NOW")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(Color.black)
                .padding(.horizontal, Theme.Space.s2)
                .padding(.vertical, 3)
                .background(Capsule().fill(.white))
                .overlay(Capsule().strokeBorder(accent.opacity(0.72), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                .offset(y: -11)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var glowColor: Color {
        guard seat.isCurrentPlayer else { return .clear }
        return accent.opacity(reducedMotion ? 0.22 : (glowPulse ? 0.42 : 0.20))
    }

    private var glowRadius: CGFloat {
        guard seat.isCurrentPlayer else { return 0 }
        return reducedMotion ? 5 : (glowPulse ? 10 : 5)
    }

    private func updateGlow(_ isCurrent: Bool) {
        guard isCurrent, !reducedMotion else {
            glowPulse = false
            return
        }
        glowPulse = false
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
    }

    private func triggerArrivalPop() {
        guard !reducedMotion else { return }
        withAnimation(.spring(response: 0.24, dampingFraction: 0.56)) { arrivalPop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { arrivalPop = false }
        }
    }

    // MARK: Cards and counts

    private var countBadge: some View {
        Text("\(seat.handCount)")
            .font(.caption.weight(.heavy))
            .monospacedDigit()
            .padding(.horizontal, Theme.Space.s2)
            .padding(.vertical, 2)
            .foregroundStyle(Theme.Palette.onAccent)
            .background(Capsule().fill(countTint))
            .overlay(
                countUrgent
                    ? Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1)
                    : nil
            )
    }

    private var countChip: some View {
        Text("\(seat.handCount)")
            .font(.caption.weight(.heavy))
            .monospacedDigit()
            .frame(minWidth: 28, minHeight: 24)
            .padding(.horizontal, 2)
            .foregroundStyle(Theme.Palette.onAccent)
            .background(Capsule().fill(countTint))
            .overlay(
                countUrgent
                    ? Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1)
                    : nil
            )
            .shadow(color: .black.opacity(0.32), radius: 3, y: 2)
    }

    /// A real hand fan rather than a flat offset stack. The visible backs are capped, but their
    /// footprint and exact count badge still make large hands easy to compare at a glance.
    private var opponentFan: some View {
        let visible = min(seat.handCount, Theme.Table.visibleOpponentBacks)
        let resolvedWidth = max(cardBackSize.width, maxFanWidth ?? cardBackSize.width * 1.75)
        let availableStep = visible > 1
            ? max(3, (resolvedWidth - cardBackSize.width) / CGFloat(visible - 1))
            : 0
        let step = min(cardBackSize.width * 0.18, availableStep)
        let centre = CGFloat(max(visible - 1, 0)) / 2

        return ZStack(alignment: .bottomTrailing) {
            ZStack {
                if visible == 0 {
                    RoundedRectangle(cornerRadius: Theme.Radius.r2, style: .continuous)
                        .strokeBorder(.white.opacity(0.20), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .frame(width: cardBackSize.width, height: cardBackSize.height)
                } else {
                    ForEach(0..<visible, id: \.self) { index in
                        let offset = CGFloat(index) - centre
                        CardBackView(size: cardBackSize)
                            .rotationEffect(.degrees(Double(offset) * 4.5), anchor: .bottom)
                            .offset(x: offset * step, y: abs(offset) * 1.6)
                            .zIndex(Double(index))
                            .transition(
                                reducedMotion
                                    ? .identity
                                    : .scale(scale: 0.62).combined(with: .opacity)
                            )
                    }
                }
            }
            .frame(width: resolvedWidth, height: cardBackSize.height + 12)

            countChip.offset(x: 6, y: 6)
        }
        .frame(width: resolvedWidth, height: cardBackSize.height + 18)
        .animation(.spring(response: 0.4, dampingFraction: 0.76), value: seat.handCount)
    }

    private func fanStep(count: Int, cardWidth: CGFloat, comfortableOverlap: CGFloat) -> CGFloat {
        guard count > 1 else { return cardWidth }
        let comfortableStep = cardWidth - comfortableOverlap
        guard let maxFanWidth else { return comfortableStep }
        let comfortableTotal = cardWidth + comfortableStep * CGFloat(count - 1)
        if comfortableTotal <= maxFanWidth { return comfortableStep }
        return max((maxFanWidth - cardWidth) / CGFloat(count - 1), cardWidth * 0.15)
    }

    /// Partner cards remain face-up and non-interactive. The shelf header above is what makes
    /// ownership explicit; the cards retain the exact existing CardView rendering.
    private func openHandFan(_ hand: [Card]) -> some View {
        let count = hand.count
        let step = fanStep(
            count: count,
            cardWidth: openHandCardSize.width,
            comfortableOverlap: openHandCardSize.width * 0.4
        )

        return ZStack(alignment: .leading) {
            if count == 0 {
                Color.clear.frame(width: openHandCardSize.width, height: openHandCardSize.height)
            } else {
                ForEach(Array(hand.enumerated()), id: \.element.id) { index, card in
                    CardView(
                        card: card,
                        size: openHandCardSize,
                        showColourName: showColourName,
                        showPattern: showPattern,
                        reducedMotion: reducedMotion
                    )
                    .offset(x: CGFloat(index) * step)
                    .transition(
                        reducedMotion
                            ? .identity
                            : .scale(scale: 0.5).combined(with: .opacity)
                    )
                }
            }
        }
        .frame(
            width: count > 0
                ? openHandCardSize.width + step * CGFloat(count - 1)
                : openHandCardSize.width,
            height: openHandCardSize.height,
            alignment: .leading
        )
    }

    // MARK: Feedback and Solo catch

    @ViewBuilder private var cueOverlay: some View {
        if caughtPenaltyCount == nil, let cue {
            Group {
                switch cue {
                case .skipped:
                    Text("SKIPPED")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Theme.Palette.onAccent)
                        .padding(.horizontal, Theme.Space.s2)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.Palette.warning))
                        .rotationEffect(.degrees(-8))
                case .drew(let count):
                    Text("+\(count)")
                        .font(.title3.weight(.heavy))
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.onAccent)
                        .padding(.horizontal, Theme.Space.s2)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.Palette.error))
                }
            }
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
            .transition(reducedMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder private var caughtPenaltyOverlay: some View {
        if let count = caughtPenaltyCount {
            CaughtPenaltyStamp(count: count)
                .transition(reducedMotion ? .opacity : .scale(scale: 0.35).combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder private var statusBadges: some View {
        if seat.hasFinishedRound {
            badge("OUT", system: "checkmark.circle.fill", tint: Theme.Palette.success)
        } else if canCatchSolo {
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("CATCH")
                Text("+2").monospacedDigit()
            }
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(Theme.Palette.onAccent)
            .padding(.horizontal, Theme.Space.s2)
            .frame(minHeight: 30)
            .background(Capsule().fill(Theme.Palette.warning))
            .overlay(Capsule().strokeBorder(.white.opacity(0.72), lineWidth: 1))
            .shadow(color: .black.opacity(0.32), radius: 4, y: 2)
            .accessibilityHidden(true)
        } else if seat.needsSoloCall {
            badge("SOLO?", system: "exclamationmark.circle.fill", tint: Theme.Palette.warning)
        }
    }

    private func badge(_ text: String, system: String, tint: Color) -> some View {
        Label(text, systemImage: system)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, Theme.Space.s2)
            .padding(.vertical, 2)
            .background(Capsule().fill(tint.opacity(0.20)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.44), lineWidth: 1))
            .foregroundStyle(tint)
    }

    // MARK: Accessibility

    private var accessibilityLabel: String {
        var parts = ["\(seat.name), \(crestDisplayName) crest, \(seat.handCount) cards"]
        if let partnerHand = seat.visiblePartnerHand {
            parts.append("your partner, open hand: \(partnerHandSummary(partnerHand))")
        }
        if seat.isCurrentPlayer { parts.append("up now, their turn") }
        if seat.hasFinishedRound {
            parts.append("out of the round")
        } else if seat.needsSoloCall {
            parts.append("has one card and has not called Solo")
        }
        if let count = caughtPenaltyCount {
            parts.append("caught, drew \(count) penalty cards")
        }
        return parts.joined(separator: ", ")
    }

    private func partnerHandSummary(_ hand: [Card]) -> String {
        guard !hand.isEmpty else { return "empty" }
        return hand.map { card -> String in
            let colour = card.colour?.displayName ?? "Wild"
            if case .number(let value) = card.type { return "\(colour) \(value)" }
            return "\(colour) \(card.type.abbreviation)"
        }
        .joined(separator: ", ")
    }
}

/// Shape-coded active-turn frame: a low-opacity tint underlay and a white inner stroke make it
/// readable in greyscale, while the broken corners avoid turning every active seat into a panel.
private struct ActiveSeatBrackets: View {
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 2
            let arm = min(18, min(size.width, size.height) * 0.22)
            var path = Path()

            path.move(to: CGPoint(x: inset, y: inset + arm))
            path.addLine(to: CGPoint(x: inset, y: inset))
            path.addLine(to: CGPoint(x: inset + arm, y: inset))

            path.move(to: CGPoint(x: size.width - inset - arm, y: inset))
            path.addLine(to: CGPoint(x: size.width - inset, y: inset))
            path.addLine(to: CGPoint(x: size.width - inset, y: inset + arm))

            path.move(to: CGPoint(x: size.width - inset, y: size.height - inset - arm))
            path.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
            path.addLine(to: CGPoint(x: size.width - inset - arm, y: size.height - inset))

            path.move(to: CGPoint(x: inset + arm, y: size.height - inset))
            path.addLine(to: CGPoint(x: inset, y: size.height - inset))
            path.addLine(to: CGPoint(x: inset, y: size.height - inset - arm))

            let broad = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
            let crisp = StrokeStyle(
                lineWidth: Theme.Table.activeSeatBracketWidth,
                lineCap: .round,
                lineJoin: .round
            )
            context.stroke(path, with: .color(tint.opacity(0.48)), style: broad)
            context.stroke(path, with: .color(.white.opacity(0.96)), style: crisp)
        }
    }
}

struct CaughtPenaltyStamp: View {
    let count: Int

    var body: some View {
        VStack(spacing: 0) {
            Text("+\(count)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .monospacedDigit()
            Text("CAUGHT")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
        }
        .foregroundStyle(.white)
        .frame(width: 74, height: 74)
        .background(
            Circle().fill(
                LinearGradient(
                    colors: [Theme.Palette.error, Color(hex: 0x6F1D1A)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        .overlay(Circle().strokeBorder(Theme.Palette.warning, lineWidth: 3).padding(4))
        .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
        .rotationEffect(.degrees(-6))
        .accessibilityLabel("Caught. Plus \(count) penalty cards")
    }
}

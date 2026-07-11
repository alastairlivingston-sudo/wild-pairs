import SwiftUI
import WildPairsCore

// Modal sheets for the two mid-resolution decisions: choosing a colour after a wild, and
// choosing a target after Targeted Draw / Forced Swap.

/// A compact "Choose a new colour" panel shown as an in-table overlay (Phase 17 C5) rather than
/// a bottom sheet, so it never covers the local hand or the partner's hand. The caller centres it
/// over the table (above the hand) with a light scrim.
struct ColourPickerView: View {
    let onChoose: (CardColour) -> Void
    var showPattern: Bool = false

    var body: some View {
        VStack(spacing: Theme.Space.s3) {
            Text("Choose a new colour").font(.headline).fontWeight(.semibold).foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Space.s2) {
                ForEach(CardColour.allCases, id: \.self) { colour in
                    Button { onChoose(colour) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                                .fill(
                                    LinearGradient(colors: [colour.highlightColor(.dark), colour.fillColor(.dark)],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                            if showPattern {
                                CardPatternFill(colour: colour).clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r3))
                            }
                            VStack(spacing: Theme.Space.s1) {
                                SuitSymbol(colour: colour, lineWidth: 2.4).frame(width: 24, height: 24)
                                Text(showPattern ? colour.displayName.uppercased() : colour.displayName)
                                    .font(.subheadline).fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                        }
                        // Compact swatch (~84pt) so the centred panel clears the hand.
                        .frame(minWidth: 84, minHeight: 84)
                        .shadow(color: colour.fillColor(.dark).opacity(0.5), radius: 10)
                    }
                    .buttonStyle(ElementTileButtonStyle())
                    .accessibilityLabel("\(colour.displayName), \(colour.symbolDisplayName) symbol, button")
                    .accessibilityIdentifier("colour-pick-\(colour.rawValue)")
                }
            }
        }
        .padding(Theme.Space.s4)
        .frame(maxWidth: 300)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.r4).fill(Theme.Felt.base(.dark)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.r4).strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.45), radius: 24, y: 6)
        .accessibilityAddTraits(.isModal)
    }
}

/// "Challenge this Draw Four?" prompt (Phase 17 B2, opt-in) — shown as an in-table overlay to the
/// target of a fresh Draw Four. Challenging alleges the player bluffed (held a card of the colour
/// in force before the wild); if right the bluffer draws instead, if wrong the challenger draws
/// extra. Shown only when `RuleProfile.drawFourChallengeable` is on.
struct DrawFourChallengeView: View {
    let challengedName: String
    let priorColour: CardColour?
    let onChallenge: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: Theme.Space.s3) {
            Text("Challenge the Draw Four?").font(.headline).fontWeight(.semibold)
                .foregroundStyle(.white).multilineTextAlignment(.center)
            Text(promptDetail)
                .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            VStack(spacing: Theme.Space.s2) {
                Button { onChallenge() } label: {
                    Label("Challenge", systemImage: "exclamationmark.shield.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.wpPrimary)
                .accessibilityIdentifier("drawfour-challenge")

                Button { onAccept() } label: {
                    Text("Accept the cards").frame(maxWidth: .infinity)
                }
                .buttonStyle(.wpSecondary)
                .accessibilityIdentifier("drawfour-accept")
            }
        }
        .padding(Theme.Space.s4)
        .frame(maxWidth: 320)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.r4).fill(Theme.Felt.base(.dark)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.r4).strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.45), radius: 24, y: 6)
        .accessibilityAddTraits(.isModal)
    }

    private var promptDetail: String {
        let colour = priorColour?.displayName ?? "the previous colour"
        return "\(challengedName) played a Draw Four. If they were holding a \(colour) card, your challenge wins and they draw instead — but if you're wrong, you draw extra."
    }
}

struct TargetPickerView: View {
    let candidates: [PlayerSeatViewState]
    let onChoose: (UUID) -> Void

    var body: some View {
        ZStack {
            TableBackground()
            VStack(spacing: Theme.Space.s4) {
                Text("Choose a player").font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                ForEach(candidates) { seat in
                    Button { onChoose(seat.id) } label: {
                        HStack {
                            Text(seat.name).fontWeight(.semibold)
                            Spacer()
                            Text("\(seat.handCount) cards").foregroundStyle(.secondary)
                        }
                        .padding(Theme.Space.s4)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .wpGlass(cornerRadius: Theme.Radius.r3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(seat.name), \(seat.handCount) cards")
                    .accessibilityIdentifier("target-pick-\(seat.seatPosition)")
                }
            }
            .padding(Theme.Space.s5)
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
    }
}

// Side-to-Side Teams "Team Pass" (game-rules.md §Side-to-Side Teams): each player privately
// picks one card from their hand to give their partner, or declines. Selections stay
// private until both teammates have submitted — this view only ever shows the local
// player's own hand, never the partner's choice.
struct TeamPassPickerView: View {
    let hand: [Card]
    let onChoose: (Card?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TableBackground()
            VStack(spacing: Theme.Space.s4) {
                Text("Team Pass").font(.title).fontWeight(.semibold).foregroundStyle(.white)
                Text("Choose a card to give your partner, or decline.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.s3) {
                        ForEach(hand) { card in
                            Button {
                                onChoose(card)
                                dismiss()
                            } label: {
                                CardView(card: card, size: Theme.CardSize.regularHand)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("teampass-card-\(card.id)")
                        }
                    }
                    .padding(.horizontal, Theme.Space.s2)
                }

                Button("Decline — keep my hand") {
                    onChoose(nil)
                    dismiss()
                }
                .buttonStyle(.wpSecondary)
                .accessibilityIdentifier("teampass-decline")
            }
            .padding(Theme.Space.s5)
        }
        .presentationDetents([.height(320)])
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
    }
}

// Pass-and-play turn handoff (Phase 15): shown when the game is waiting on the other human
// at the table. Partner hands are open by design, so this is a turn-clarity gate, not a
// privacy screen — the table stays visible (dimmed) behind it.
struct HandoffOverlay: View {
    let seat: PlayerSeatViewState
    let onReady: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: Theme.Space.s4) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.Palette.accent)
                Text("Pass the device to \(seat.name)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("It's \(seat.name)'s turn.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    onReady()
                } label: {
                    Text("I'm \(seat.name) — show my hand")
                }
                .buttonStyle(.wpPrimary)
                .accessibilityIdentifier("handoff-confirm")
            }
            .padding(Theme.Space.s6)
            .frame(maxWidth: 420)
            .wpGlass(cornerRadius: Theme.Radius.r4, tint: Theme.Palette.accent)
            .padding(Theme.Space.s5)
        }
        .transition(.opacity)
        // `.contain` keeps the confirm button individually reachable/queryable; adding the
        // modal trait directly to the container would swallow the children (KI-034 lesson).
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("handoff-overlay")
    }
}

// The single guidance line above the hand (§ux tone of voice).
struct PromptBanner: View {
    let prompt: PromptKind
    /// Element glow for the border (design-plan.md §3.1) so the banner tracks the scene tint.
    var tint: Color? = nil

    var body: some View {
        Text(text)
            .font(.body).fontWeight(.medium)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Space.s4).padding(.vertical, Theme.Space.s2)
            .frame(maxWidth: .infinity)
            // A capsule's corner radius is height/2, so at large Dynamic Type sizes this
            // banner wraps to several lines, the capsule grows tall, and its semicircular
            // ends balloon inward and clip the text. A fixed-radius rounded rect has no
            // such failure mode regardless of how many lines the text wraps to.
            .wpGlass(cornerRadius: Theme.Radius.r4, tint: tint)
            .accessibilityIdentifier("game-prompt")
    }

    private var text: String {
        switch prompt {
        case .yourTurn(let hint):        return hint
        case .waitingFor(let name):      return "\(name) is thinking…"
        case .chooseColour:              return "Choose a new colour."
        case .chooseTarget:              return "Choose a player."
        case .chooseTeamPass:            return "Team Pass — choose a card to give your partner, or decline."
        case .challengeDrawFour:         return "A Draw Four was played on you — challenge it, or accept the cards."
        case .mustDraw:                  return "Your turn — no matching card. Tap the draw pile."
        case .stackOrDraw(let count):     return "Stack a Draw Two or Draw Four, or draw \(count)."
        case .forcedPickup(let count):    return "No card can answer the +\(count) — picking it up…"
        case .roundOver(let team):       return "\(team) wins this round!"
        case .roundOverByTimeout(let team): return "Time's up — \(team) wins this round on lowest score."
        case .gameOver(let team):        return "\(team) wins the game!"
        case .paused:                    return "Paused."
        }
    }
}

// AI thinking indicator (ux-spec.md §10 "Game table — AI turn"): pulsing dots establish
// that the AI is deliberating, not executing instantly. Dot count scales with difficulty;
// Fast mode / Reduced Motion show a static label instead of animating, per spec.
struct ThinkingDotsView: View {
    let dotCount: Int
    var isStatic: Bool = false

    @State private var animate = false

    var body: some View {
        if isStatic {
            Text("Thinking…").font(.caption2).foregroundStyle(.secondary)
                .accessibilityLabel("Thinking")
        } else {
            HStack(spacing: 3) {
                ForEach(0..<dotCount, id: \.self) { i in
                    Circle()
                        .fill(Theme.Palette.accent)
                        .frame(width: 5, height: 5)
                        .opacity(animate ? 1 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.15),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
            .accessibilityLabel("Thinking")
        }
    }
}

// Tasteful, unobtrusive countdown for the 3-minute round-wide fallback timer (game-rules.md
// "Round Timer Fallback") — only shown once a round is actually running with the rule active.
struct RoundTimerBadge: View {
    let remaining: TimeInterval
    let total: TimeInterval

    private var isUrgent: Bool { remaining <= 30 }
    private var label: String {
        let seconds = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        Label(label, systemImage: "clock")
            .font(.caption).fontWeight(.semibold).monospacedDigit()
            .foregroundStyle(isUrgent ? Theme.Palette.warning : .white.opacity(0.8))
            .padding(.horizontal, Theme.Space.s3).padding(.vertical, 4)
            .wpGlassCapsule(tint: isUrgent ? Theme.Palette.warning : nil)
            .accessibilityLabel("Round time remaining: \(label)")
            .accessibilityIdentifier("game-round-timer")
    }
}

// The local player's 10-second per-move countdown (game-rules.md "Per-Move Timer") — a thin
// progress bar above the hand, only shown on the local player's turn. Colour shifts from
// accent to warning as time runs low, mirroring the round timer's urgency cue.
struct MoveTimerBar: View {
    let remaining: TimeInterval
    let total: TimeInterval

    private var progress: Double { total > 0 ? max(0, min(1, remaining / total)) : 0 }
    private var isUrgent: Bool { remaining <= 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Int(remaining.rounded()))s to play")
                .font(.caption2).foregroundStyle(isUrgent ? Theme.Palette.warning : .secondary)
            ProgressView(value: progress)
                .tint(isUrgent ? Theme.Palette.warning : Theme.Palette.accent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(remaining.rounded())) seconds left to play")
        .accessibilityIdentifier("game-move-timer")
    }
}

import SwiftUI
import WildPairsCore

// Pass-and-play dual-ended table (Phase 17 D1 — "Active-Half Focus"). Two human teammates share
// one flat device: You at the bottom edge, Partner at the top edge (rotated 180°). Whoever is to
// act gets the big, lit half with a full-size, tappable hand; the waiting teammate collapses to a
// slim rotated strip. No "pass the device" handoff — the turn hand-off is felt as the halves
// expand/collapse. Used only when `vm.isPassAndPlay`; AI-partner games keep GameTableView.

struct PassAndPlayTableView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var settings: AppSettings
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var showPause = false

    private var showColourName: Bool { settings.userSettings.colourBlindMode }
    private var showPattern: Bool { settings.userSettings.colourBlindMode && settings.userSettings.patternFills }
    private var reducedMotion: Bool { settings.userSettings.reducedVisualEffects }
    private var motionDisabled: Bool { reducedMotion || systemReduceMotion }
    private var effectiveLargeCards: Bool {
        settings.userSettings.largeCards || dynamicTypeSize >= .accessibility3
    }
    private var handCardSize: CGSize {
        effectiveLargeCards ? Theme.CardSize.regularHand : Theme.CardSize.compactHand
    }

    private var vs: GameViewState { vm.viewState }             // bottom (You) perspective: seats, opponents
    private var avs: GameViewState { vm.activeViewState }      // acting human: centre draw affordance + hand
    private var current: UUID? { vm.currentHumanID }
    private var elementGlow: Color { Theme.Element.scene(for: vs.currentColour).glow }

    var body: some View {
        ZStack {
            TableBackground(
                element: vs.currentColour,
                turnDirection: vs.phase == .playing ? vs.turnDirection : nil,
                directionAnimationDisabled: settings.userSettings.animationSpeed == .off,
                style: settings.userSettings.tableBackgroundStyle,
                activeTablePosition: vs.phase == .playing
                    ? vs.seats.first { $0.isCurrentPlayer }?.tablePosition
                    : nil
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                edgeHUD(for: vm.topHumanID, rotated: true, isPrimarySemantic: false)

                VStack(spacing: Theme.Space.s2) {
                    humanHalf(for: vm.topHumanID, rotated: true)
                    middleRow
                    humanHalf(for: vm.bottomHumanID, rotated: false)
                }
                .padding(.vertical, Theme.Space.s2)
                .frame(maxHeight: .infinity)

                edgeHUD(for: vm.bottomHumanID, rotated: false, isPrimarySemantic: true)
                    .accessibilitySortPriority(100)
            }
            .saturation(tableSaturation)
            .animation(motionDisabled ? nil : .easeInOut(duration: 0.4), value: current)

            pauseButton

            decisionOverlay

            if vs.phase == .roundEnded || vs.phase == .gameEnded {
                RoundEndView(vs: vs, settings: settings, onNext: vm.beginNextRound, onExit: onExit)
            }
        }
        .sheet(isPresented: $showPause) {
            PauseMenuView(settings: settings, onResume: { showPause = false; vm.resume() }, onEndGame: onExit)
        }
        .onChange(of: showPause) { _, paused in if paused { vm.pause() } }
        .preferredColorScheme(.dark)
    }

    private var tableSaturation: Double {
        guard vs.phase != .playing, vs.localTeamWon == false, !reducedMotion else { return 1 }
        return 0
    }

    private func edgeHUD(
        for viewerID: UUID?,
        rotated: Bool,
        isPrimarySemantic: Bool
    ) -> some View {
        let ownsMoveTimer = viewerID == current
        return GameEdgeHUD(
            roundNumber: vs.roundNumber,
            scoreboard: vs.scoreboard,
            turnLabel: turnLabel(for: viewerID),
            turnDirection: vs.turnDirection,
            roundRemaining: vm.roundTimeRemaining,
            roundTotal: vm.roundTimeLimit,
            visualMoveRemaining: ownsMoveTimer ? vm.moveTimeRemaining : nil,
            semanticMoveRemaining: isPrimarySemantic ? vm.moveTimeRemaining : nil,
            moveTotal: vm.moveTimeLimit,
            accent: elementGlow,
            compact: hSize != .regular,
            isPrimarySemantic: isPrimarySemantic,
            contentRotation: rotated ? .degrees(180) : .zero
        )
    }

    private func turnLabel(for viewerID: UUID?) -> String {
        guard let viewerID,
              let viewer = vs.seats.first(where: { $0.id == viewerID }),
              let active = vs.seats.first(where: { $0.isCurrentPlayer }) else { return "TURN" }
        if active.id == viewerID { return "YOUR TURN" }
        if active.teamID == viewer.teamID { return "PARTNER'S TURN" }
        return "\(active.name.uppercased())'S TURN"
    }

    // MARK: A human end

    /// Both ends always render their full hand — a teammate must never lose sight of their
    /// cards just because it is not their turn. Turn ownership is carried by the brackets,
    /// the accent border and the PLAY NOW cue, never by hiding cards.
    @ViewBuilder private func humanHalf(for humanID: UUID?, rotated: Bool) -> some View {
        if let humanID {
            let isActive = current == humanID
            half(humanID, isActive: isActive)
                .rotationEffect(.degrees(rotated ? 180 : 0))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
        }
    }

    /// The waiting teammate's cards, all marked unplayable — it is not their turn, so nothing
    /// should read as actionable even though every card stays visible.
    private func waitingHand(_ humanID: UUID) -> [CardViewModel] {
        vm.hand(for: humanID).map { CardViewModel(card: $0, isPlayable: false) }
    }

    /// One teammate's end. The hand is always fully rendered; `isActive` only changes the
    /// chrome and whether cards respond to taps.
    private func half(_ humanID: UUID, isActive: Bool) -> some View {
        VStack(spacing: Theme.Space.s2) {
            HStack(spacing: Theme.Space.s2) {
                if isActive {
                    Text("PLAY NOW")
                        .font(.subheadline).fontWeight(.bold).foregroundStyle(Theme.Palette.accent)
                } else {
                    Text(vm.name(for: humanID))
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                }
                Text("\(vm.handCount(for: humanID))")
                    .font(.caption).fontWeight(.heavy).monospacedDigit()
                    .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
                    .background(Capsule().fill(
                        isActive ? Theme.Palette.accent : Theme.Palette.accent.opacity(0.55)
                    ))
                    .foregroundStyle(Theme.Palette.onAccent)
                if isActive, avs.soloButtonVisible {
                    Button { vm.callSolo(as: humanID) } label: {
                        Label("Solo!", systemImage: "exclamationmark.circle.fill").font(.caption).fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.Palette.warning).controlSize(.small)
                }
                if !isActive {
                    Text("waiting").font(.caption2).foregroundStyle(.tertiary).textCase(.uppercase)
                }
            }
            // The waiting end still sees every card; nothing is playable there, and hit-testing
            // is off so it cannot act early.
            HandView(hand: isActive ? avs.localHand : waitingHand(humanID),
                     cardSize: handCardSize,
                     showColourName: showColourName, showPattern: showPattern,
                     reducedMotion: motionDisabled,
                     onPlay: { card in if isActive { vm.play(card.card, as: humanID) } })
                .allowsHitTesting(isActive)
        }
        .padding(.horizontal, Theme.Space.s3).padding(.vertical, Theme.Space.s2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.r4)
                .fill(Color.white.opacity(isActive ? 0.03 : 0.015))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.r4)
                    .strokeBorder(
                        Theme.Palette.accent.opacity(isActive ? 0.6 : 0.16),
                        lineWidth: isActive ? 1.5 : 1
                    ))
                .shadow(
                    color: (reducedMotion || !isActive) ? .clear : Theme.Palette.accent.opacity(0.4),
                    radius: 20
                )
        )
        .overlay {
            if isActive {
                ActiveSeatBrackets(tint: elementGlow)
                    .padding(-3)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .opacity(isActive ? 1 : 0.88)
        .padding(.horizontal, Theme.Space.s3)
    }

    // MARK: Middle — opponents + shared centre

    private var middleRow: some View {
        HStack(alignment: .center, spacing: Theme.Space.s2) {
            opponentColumn(tablePosition: 1)
            TableCenterView(
                topDiscard: avs.topDiscard, currentColour: avs.currentColour,
                drawPileCount: avs.drawPileCount, pendingDrawCount: avs.pendingDrawCount,
                turnDirection: avs.turnDirection, canDraw: avs.canDrawNow,
                mustDraw: avs.mustDrawNow, forcedPickup: avs.forcedPickupCount != nil,
                showColourName: showColourName, showPattern: showPattern, reducedMotion: motionDisabled,
                cardSize: Theme.CardSize.tableFocus, colourChoicePending: avs.colourChoicePending,
                recentDiscards: avs.recentDiscards,
                onDraw: { if let c = current { vm.drawCard(as: c) } })
            opponentColumn(tablePosition: 3)
        }
        .padding(.horizontal, Theme.Space.s2)
    }

    @ViewBuilder private func opponentColumn(tablePosition: Int) -> some View {
        if let seat = vs.seats.first(where: { $0.tablePosition == tablePosition }) {
            PlayerZoneView(
                seat: seat, cardBackSize: Theme.CardSize.opponentBack, maxFanWidth: 84,
                reducedMotion: motionDisabled, isThinking: seat.id == vm.thinkingPlayerID,
                thinkingDotCount: vm.thinkingDifficulty == .easy ? 2 : 3, accent: elementGlow,
                onCatchSolo: seat.id == vs.catchableSoloPlayerID ? { vm.callOut(seat.id) } : nil)
            .frame(width: 84)
        } else {
            Color.clear.frame(width: 84)
        }
    }

    // MARK: Pause

    private var pauseButton: some View {
        HStack {
            Spacer()
            Button { showPause = true; vm.pause() } label: {
                Image(systemName: "pause.fill").font(.footnote)
                    .frame(width: 28, height: 28).wpGlassCircle()
                    .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
            }
            .accessibilityLabel("Pause").accessibilityIdentifier("game-pause-button")
        }
        .frame(maxHeight: .infinity)
        .padding(.trailing, Theme.Space.s2)
    }

    // MARK: Decision overlays (either end — rotated when the top human owns it)

    @ViewBuilder private var decisionOverlay: some View {
        if let decision = vm.activeDecision {
            let rotated = decision.owner == vm.topHumanID
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                decisionContent(decision).rotationEffect(.degrees(rotated ? 180 : 0))
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder private func decisionContent(_ decision: GameViewModel.ActiveDecision) -> some View {
        switch decision {
        case .colour(let owner):
            ColourPickerView(onChoose: { vm.chooseColour($0, as: owner) }, showPattern: showPattern)
        case .target(let owner, let candidates):
            TargetPickerView(candidates: vs.seats.filter { candidates.contains($0.id) },
                             onChoose: { vm.chooseTarget($0, as: owner) })
        case .teamPass(let owner):
            TeamPassPickerView(hand: vm.hand(for: owner), onChoose: { vm.passTeamCard($0, as: owner) })
        case .drawFourChallenge(let owner, let name, let colour):
            DrawFourChallengeView(challengedName: name, priorColour: colour,
                                  onChallenge: { vm.resolveDrawFourChallenge(true, as: owner) },
                                  onAccept: { vm.resolveDrawFourChallenge(false, as: owner) })
        }
    }
}

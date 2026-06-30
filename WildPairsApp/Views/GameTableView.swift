import SwiftUI
import WildPairsCore

// The primary gameplay screen. Portrait-only (Phase 9 A1): partner top-centre, opponents
// upper-left/upper-right, you at the bottom, table centre between the opponents. All zones
// are sized from `GeometryReader` so nothing ever clips off-screen — no horizontal
// `ScrollView` seat wrappers. All game logic lives in the ViewModel/Core; this view only
// renders state and forwards taps.

struct GameTableView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var settings: AppSettings
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.colorScheme) private var scheme
    @State private var showPause = false

    private var vs: GameViewState { vm.viewState }
    private var handCardSize: CGSize {
        let large = settings.userSettings.largeCards
        // iPad hand reads larger so the deck has real presence on the wide canvas (ux-spec §7).
        if hSize == .regular { return large ? CGSize(width: 120, height: 180) : Theme.CardSize.selected }
        return large ? Theme.CardSize.regularHand : Theme.CardSize.compactHand
    }
    private var showColourName: Bool { settings.userSettings.colourBlindMode }
    private var showPattern: Bool { settings.userSettings.colourBlindMode && settings.userSettings.patternFills }
    private var reducedMotion: Bool { settings.userSettings.reducedVisualEffects }
    /// Dot count by difficulty (ux-spec.md §10 thinking-indicator table): Easy gets fewer
    /// dots than Medium/Hard/Expert/Master, which all show the full three.
    private var thinkingDotCount: Int { vm.thinkingDifficulty == .easy ? 2 : 3 }
    private var tableSaturation: Double {
        guard vs.phase != .playing, vs.localTeamWon == false, !settings.userSettings.reducedVisualEffects else { return 1 }
        return 0
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let spacing = Theme.Space.s3
                let seatBackSize = Theme.CardSize.opponentBack
                // Opponents are now a compact avatar (Step 4), not a wide fanned back-row —
                // give the side columns just enough width for the avatar + label, and let the
                // table centre (discard/draw) claim the room a back-fan used to need.
                let avatarColumnWidth: CGFloat = 92
                let sideWidth = min(avatarColumnWidth, (geo.size.width - spacing * 4) * 0.22)
                // The draw + discard pair is the focal point of the table — the old compact
                // (60pt) centre read as two small cards lost in dead space. Give it real
                // presence: bigger on iPhone, bigger still on iPad's wider canvas.
                let isPad = hSize == .regular
                let centerSize = isPad ? Theme.CardSize.selected : Theme.CardSize.regularHand
                let resolvedSide = max(sideWidth, 80)
                // iPad uses its width deliberately (ux-spec §7): the table is a centred block of
                // a sensible max width with opponents pushed out to its edges and larger cards,
                // instead of phone-width content marooned in the middle of a 1024pt screen.
                let contentMaxWidth: CGFloat = isPad ? 760 : .infinity
                let availableWidth = contentMaxWidth.isFinite ? contentMaxWidth : geo.size.width
                let partnerCardSize = isPad ? CGSize(width: 60, height: 90) : Theme.CardSize.partnerHand
                // Clamp the partner's open-hand fan to the real on-screen width so it never
                // clips off the right edge (A6).
                let partnerMaxWidth = min(resolvedSide * 2 + centerSize.width * 2 + Theme.Space.s3,
                                          availableWidth - Theme.Space.s4 * 2)

                ZStack {
                    TableBackground().ignoresSafeArea()

                    VStack(spacing: 0) {
                        scoreBar.padding(.top, spacing)

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: spacing) {
                                // Spread the three game zones down the tall canvas instead of
                                // clustering them with a dead band: partner anchored at the top,
                                // opponents + draw/discard centred in the middle, your prompt +
                                // hand at the bottom (thumb zone, ux-spec §6).
                                partnerZone(maxWidth: partnerMaxWidth, seatBackSize: seatBackSize,
                                            openHandCardSize: partnerCardSize)
                                Spacer(minLength: spacing)
                                opponentCenterRow(spacing: spacing, seatBackSize: seatBackSize,
                                                  centerSize: centerSize, sideWidth: resolvedSide, spread: isPad)
                                Spacer(minLength: spacing)

                                if let roundRemaining = vm.roundTimeRemaining {
                                    RoundTimerBadge(remaining: roundRemaining, total: vm.roundTimeLimit)
                                }
                                PromptBanner(prompt: vs.prompt).padding(.horizontal, Theme.Space.s4)
                                if let moveRemaining = vm.moveTimeRemaining {
                                    MoveTimerBar(remaining: moveRemaining, total: vm.moveTimeLimit)
                                        .padding(.horizontal, Theme.Space.s4)
                                }
                                bottomControls
                                pointsAtRiskPill
                                HandView(hand: vs.localHand, cardSize: handCardSize,
                                         showColourName: showColourName, showPattern: showPattern,
                                         reducedMotion: reducedMotion, onPlay: vm.play)
                            }
                            .padding(.vertical, spacing)
                            .frame(maxWidth: contentMaxWidth)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geo.size.height - 60)
                        }
                        // Loss desaturates the table gently underneath the overlay (ux-spec.md
                        // §10 "Round loss feedback"); skipped under Reduced visual effects.
                        .saturation(tableSaturation)
                        .animation(.easeInOut(duration: 0.6), value: tableSaturation)
                    }

                    if let hint = vm.lastInvalidHint { invalidTooltip(hint, handCardSize: handCardSize) }

                    if vs.phase == .roundEnded || vs.phase == .gameEnded {
                        RoundEndView(vs: vs, settings: settings, onNext: vm.beginNextRound, onExit: onExit)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: colourSheetBinding) {
            ColourPickerView(onChoose: vm.chooseColour, showPattern: showPattern)
        }
        .sheet(isPresented: targetSheetBinding) {
            TargetPickerView(candidates: targetCandidates, onChoose: vm.chooseTarget)
        }
        .sheet(isPresented: teamPassSheetBinding) {
            TeamPassPickerView(hand: vs.localHand.map(\.card), onChoose: vm.passTeamCard)
        }
        .sheet(isPresented: $showPause) {
            PauseMenuView(settings: settings, onResume: { showPause = false; vm.resume() },
                          onEndGame: onExit)
        }
        .onChange(of: showPause) { _, paused in if paused { vm.pause() } }
        // The felt table is a deliberately dark-first surface (Phase 9 A2); locking the
        // colour scheme keeps text/contrast tokens (.secondary, .white) deterministic
        // instead of drifting with the system light/dark appearance.
        .preferredColorScheme(.dark)
    }

    /// Single-row pill — round chip, team scores, pause — that never wraps to a second
    /// line, replacing the toolbar's two-row layout at small widths (A6/A7).
    private var scoreBar: some View {
        HStack(spacing: Theme.Space.s3) {
            Text("Round \(vs.roundNumber)")
                .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.5)
                .padding(.horizontal, Theme.Space.s2).padding(.vertical, Theme.Space.s1)
                .background(Capsule().fill(.white.opacity(0.08)))

            Spacer(minLength: Theme.Space.s2)

            HStack(spacing: Theme.Space.s2) {
                ForEach(Array(vs.scoreboard.enumerated()), id: \.element.id) { index, row in
                    HStack(spacing: Theme.Space.s1) {
                        Circle()
                            .fill(index == 0 ? Theme.Palette.teamA : Theme.Palette.teamB)
                            .frame(width: 8, height: 8)
                        Text("\(row.displayName) \(row.score)")
                            .font(.caption).fontWeight(.semibold)
                            .lineLimit(1).minimumScaleFactor(0.5)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.s3).padding(.vertical, Theme.Space.s1)
            .background(Capsule().fill(.white.opacity(0.08)))

            Spacer(minLength: Theme.Space.s2)

            Button { showPause = true; vm.pause() } label: {
                Image(systemName: "pause.fill").font(.footnote)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(.white.opacity(0.08)))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Pause")
            .accessibilityIdentifier("game-pause-button")
        }
        .lineLimit(1)
        .padding(.horizontal, Theme.Space.s4)
    }

    @ViewBuilder private var bottomControls: some View {
        if vs.soloButtonVisible {
            Button { vm.callSolo() } label: {
                Label("Solo!", systemImage: "exclamationmark.circle.fill")
                    .fontWeight(.bold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Palette.warning)
            .accessibilityIdentifier("game-solo-button")
            .accessibilityHint("You have one card remaining. Call Solo to avoid a penalty.")
        }
    }

    /// Live "points at risk" (Phase 11 E) — the raw card-value sum of the local player's own
    /// team's hands, shown only for that team since it's derived purely from already-visible
    /// hands (the local player's own + the open partner hand) and never leaks opponent info.
    private var pointsAtRiskPill: some View {
        Text("Team at risk: \(vs.localTeamPointsAtRisk) pts")
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Theme.Space.s3).padding(.vertical, Theme.Space.s1)
            .background(Capsule().fill(.white.opacity(0.06)))
            .accessibilityLabel("Your team would lose \(vs.localTeamPointsAtRisk) points if you lost the round now.")
    }

    /// Partner's open hand, anchored at the top of the table (A6: `maxFanWidth` clamps the fan
    /// to the on-screen width so it never clips off the right edge).
    @ViewBuilder private func partnerZone(maxWidth: CGFloat, seatBackSize: CGSize,
                                          openHandCardSize: CGSize) -> some View {
        if let partner = seat(at: 2) {
            PlayerZoneView(seat: partner, showColourName: showColourName, showPattern: showPattern,
                           cardBackSize: seatBackSize, openHandCardSize: openHandCardSize,
                           maxFanWidth: maxWidth,
                           reducedMotion: reducedMotion, isThinking: partner.id == vm.thinkingPlayerID,
                           thinkingDotCount: thinkingDotCount)
        }
    }

    /// The middle row: left opponent · table centre (draw + discard) · right opponent. Each
    /// zone gets an explicit width from `GeometryReader` so the row never scrolls or clips,
    /// even at large Dynamic Type sizes (A6/A7). On iPad (`spread`) the opponents are pushed
    /// out to the edges of the table block so the canvas width is actually used.
    private func opponentCenterRow(spacing: CGFloat, seatBackSize: CGSize, centerSize: CGSize,
                                   sideWidth: CGFloat, spread: Bool) -> some View {
        HStack(alignment: .center, spacing: spacing) {
            if let left = seat(at: 1) {
                opponentZone(left, backSize: seatBackSize, width: sideWidth)
            } else {
                Color.clear.frame(width: sideWidth)
            }
            if spread { Spacer(minLength: spacing) }
            tableCenter(size: centerSize)
            if spread { Spacer(minLength: spacing) }
            if let right = seat(at: 3) {
                opponentZone(right, backSize: seatBackSize, width: sideWidth)
            } else {
                Color.clear.frame(width: sideWidth)
            }
        }
    }

    private func tableCenter(size: CGSize) -> some View {
        TableCenterView(
            topDiscard: vs.topDiscard, currentColour: vs.currentColour,
            drawPileCount: vs.drawPileCount, pendingDrawCount: vs.pendingDrawCount,
            turnDirection: vs.turnDirection,
            canDraw: vs.isLocalPlayerTurn, showColourName: showColourName, showPattern: showPattern,
            reducedMotion: reducedMotion, cardSize: size, onDraw: vm.drawCard
        )
    }

    private func opponentZone(_ seat: PlayerSeatViewState, backSize: CGSize, width: CGFloat) -> some View {
        PlayerZoneView(
            seat: seat, cardBackSize: backSize, maxFanWidth: width - Theme.Space.s2 * 2,
            reducedMotion: reducedMotion,
            isThinking: seat.id == vm.thinkingPlayerID, thinkingDotCount: thinkingDotCount,
            onCatchSolo: seat.id == vs.catchableSoloPlayerID ? { vm.callOut(seat.id) } : nil
        )
        .frame(width: width)
    }

    private func invalidTooltip(_ hint: String, handCardSize: CGSize) -> some View {
        VStack {
            Spacer()
            Text(hint)
                .font(.callout).padding(Theme.Space.s3)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.r2).fill(.ultraThinMaterial))
                .padding(.bottom, handCardSize.height + Theme.Space.s6)
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    // MARK: Helpers

    private func seat(at position: Int) -> PlayerSeatViewState? {
        vs.seats.first { $0.seatPosition == position }
    }

    private var targetCandidates: [PlayerSeatViewState] {
        vs.seats.filter { vs.localTargetChoices.contains($0.id) }
    }

    private var colourSheetBinding: Binding<Bool> {
        Binding(get: { vs.awaitingLocalColourChoice }, set: { _ in })
    }
    private var targetSheetBinding: Binding<Bool> {
        Binding(get: { !vs.localTargetChoices.isEmpty }, set: { _ in })
    }
    private var teamPassSheetBinding: Binding<Bool> {
        Binding(get: { vs.awaitingLocalTeamPass }, set: { _ in })
    }
}

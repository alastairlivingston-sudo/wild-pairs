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
        if hSize == .regular { return large ? Theme.CardSize.selected : Theme.CardSize.regularHand }
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
                let centerSize = Theme.CardSize.compactHand

                ZStack {
                    TableBackground().ignoresSafeArea()

                    VStack(spacing: 0) {
                        scoreBar.padding(.top, spacing)

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: spacing) {
                                Spacer(minLength: 0)
                                portraitSeatsStack(spacing: spacing, seatBackSize: seatBackSize,
                                                    centerSize: centerSize, sideWidth: max(sideWidth, 80),
                                                    tableWidth: geo.size.width)
                                Spacer(minLength: 0)

                                if let roundRemaining = vm.roundTimeRemaining {
                                    RoundTimerBadge(remaining: roundRemaining, total: vm.roundTimeLimit)
                                }
                                PromptBanner(prompt: vs.prompt).padding(.horizontal, Theme.Space.s4)
                                if let moveRemaining = vm.moveTimeRemaining {
                                    MoveTimerBar(remaining: moveRemaining, total: vm.moveTimeLimit)
                                        .padding(.horizontal, Theme.Space.s4)
                                }
                                bottomControls
                                HandView(hand: vs.localHand, cardSize: handCardSize,
                                         showColourName: showColourName, showPattern: showPattern,
                                         reducedMotion: reducedMotion, onPlay: vm.play)
                            }
                            .padding(.vertical, spacing)
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

    /// Partner stacked above a fixed-width row of (left opponent, table centre, right
    /// opponent) — each zone is given an explicit width from `GeometryReader` so the row
    /// never needs to scroll or clip, even at large Dynamic Type sizes (A6/A7).
    private func portraitSeatsStack(spacing: CGFloat, seatBackSize: CGSize, centerSize: CGSize, sideWidth: CGFloat,
                                     tableWidth: CGFloat) -> some View {
        // The naive sum (both side columns + both centre cards) can exceed the table's actual
        // width once spacing is added back in — clamp to what's really on screen so the
        // partner's fan never clips off the right edge (A6).
        let partnerMaxWidth = min(sideWidth * 2 + centerSize.width * 2 + Theme.Space.s3,
                                   tableWidth - Theme.Space.s4 * 2)
        return VStack(spacing: spacing) {
            if let partner = seat(at: 2) {
                PlayerZoneView(seat: partner, showColourName: showColourName, showPattern: showPattern,
                               cardBackSize: seatBackSize, openHandCardSize: Theme.CardSize.partnerHand,
                               maxFanWidth: partnerMaxWidth,
                               reducedMotion: reducedMotion, isThinking: partner.id == vm.thinkingPlayerID,
                               thinkingDotCount: thinkingDotCount)
            }
            HStack(alignment: .center, spacing: spacing) {
                if let left = seat(at: 1) {
                    opponentZone(left, backSize: seatBackSize, width: sideWidth)
                } else {
                    Color.clear.frame(width: sideWidth)
                }
                tableCenter(size: centerSize)
                if let right = seat(at: 3) {
                    opponentZone(right, backSize: seatBackSize, width: sideWidth)
                } else {
                    Color.clear.frame(width: sideWidth)
                }
            }
        }
    }

    private func tableCenter(size: CGSize) -> some View {
        TableCenterView(
            topDiscard: vs.topDiscard, currentColour: vs.currentColour,
            drawPileCount: vs.drawPileCount, turnDirection: vs.turnDirection,
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

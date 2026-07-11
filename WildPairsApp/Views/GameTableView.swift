import SwiftUI
import WildPairsCore

// The primary gameplay screen: partner top-centre, opponents upper-left/upper-right, you at
// the bottom, table centre between the opponents. All zones are sized from `GeometryReader`
// so nothing ever clips off-screen — no horizontal `ScrollView` seat wrappers. iPhone is
// portrait-only (Phase 9 A1); iPad additionally supports landscape (Phase 15), where the
// same zone structure compresses vertically and spreads across the full width. All game
// logic lives in the ViewModel/Core; this view only renders state and forwards taps.

struct GameTableView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var settings: AppSettings
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.colorScheme) private var scheme
    @State private var showPause = false
    /// The seat cue (skip / forced draw) currently on screen; the ViewModel emits one and this
    /// view shows it briefly then clears it (Phase 17 C3).
    @State private var activeCue: SeatCueEvent?
    /// Live frames of each seat + the discard, in the table coordinate space, feeding the
    /// cross-table played-card travel (Phase 17 Stage 3.1).
    @State private var tableAnchors: [TableAnchor: CGRect] = [:]
    /// Ghost cards currently flying from an acting seat to the discard.
    @State private var flights: [CardFlight] = []
    /// Card-backs currently flying from the draw pile to a seat (Phase 17 Stage 3.5).
    @State private var drawFlights: [DrawFlight] = []
    /// Turn hand-off spotlights sweeping from the finishing seat to the next (Phase 17 Stage 3.3).
    @State private var spotlights: [TurnSpotlight] = []
    private let tableSpace = "wpTable"

    private var vs: GameViewState { vm.viewState }
    /// Table position (0…3) of the seat whose turn it currently is — drives the hand-off sweep.
    private var currentSeatPosition: Int? { vs.seats.first { $0.isCurrentPlayer }?.tablePosition }
    private var handCardSize: CGSize {
        let large = settings.userSettings.largeCards
        // iPad hand reads larger so the deck has real presence on the wide canvas (ux-spec §7).
        if hSize == .regular { return large ? Theme.CardSize.padHandLarge : Theme.CardSize.padHand }
        return large ? Theme.CardSize.regularHand : Theme.CardSize.compactHand
    }
    private var showColourName: Bool { settings.userSettings.colourBlindMode }
    private var showPattern: Bool { settings.userSettings.colourBlindMode && settings.userSettings.patternFills }
    private var reducedMotion: Bool { settings.userSettings.reducedVisualEffects }
    /// Skip the cross-table travel ghost entirely when motion is off (Reduced Motion, or the
    /// user's Animation → Off setting) — the discard just updates in place.
    private var travelDisabled: Bool { reducedMotion || settings.userSettings.animationSpeed == .off }
    /// Dot count by difficulty (ux-spec.md §10 thinking-indicator table): Easy gets fewer
    /// dots than Medium/Hard/Expert/Master, which all show the full three.
    private var thinkingDotCount: Int { vm.thinkingDifficulty == .easy ? 2 : 3 }
    private var tableSaturation: Double {
        guard vs.phase != .playing, vs.localTeamWon == false, !settings.userSettings.reducedVisualEffects else { return 1 }
        return 0
    }
    /// Chrome accent for the active element (design-plan.md §2.1) — the prompt border and
    /// active-seat glow follow the scene tint so the whole table reads as one environment.
    private var elementGlow: Color { Theme.Element.scene(for: vs.currentColour).glow }

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
                let isLandscape = isPad && geo.size.width > geo.size.height
                // Landscape height is the scarce axis on iPad — shrink the focal cards, partner
                // fan, and hand so the whole table fits without vertical scrolling on smaller
                // iPads (Phase 17 C9).
                let centerSize = isPad ? (isLandscape ? Theme.CardSize.tableFocus : Theme.CardSize.padTableFocus)
                                       : Theme.CardSize.tableFocus
                let handSize: CGSize = (isPad && isLandscape)
                    ? (settings.userSettings.largeCards ? Theme.CardSize.padHand : Theme.CardSize.regularHand)
                    : handCardSize
                let resolvedSide = max(sideWidth, 80)
                // iPad uses its width deliberately (ux-spec §7): the table is a centred block of
                // a sensible max width with opponents pushed out to its edges and larger cards,
                // instead of phone-width content marooned in the middle of a 1024pt screen.
                // Landscape gets a wider block (the height is the scarce axis there).
                let contentMaxWidth: CGFloat = isPad
                    ? (isLandscape ? min(geo.size.width - Theme.Space.s6 * 2, 1120) : 820)
                    : .infinity
                let availableWidth = contentMaxWidth.isFinite ? contentMaxWidth : geo.size.width
                let partnerCardSize = (isPad && !isLandscape) ? Theme.CardSize.padPartnerHand : Theme.CardSize.partnerHand
                // Clamp the partner's open-hand fan to the real on-screen width so it never
                // clips off the right edge (A6).
                let partnerMaxWidth = min(resolvedSide * 2 + centerSize.width * 2 + Theme.Space.s3,
                                          availableWidth - Theme.Space.s4 * 2)

                ZStack {
                    TableBackground(element: vs.currentColour).ignoresSafeArea()

                    VStack(spacing: 0) {
                        scoreBar.padding(.top, spacing)

                        ScrollView(.vertical, showsIndicators: false) {
                            // iPhone: zones fill the height with flexible spacers (partner top,
                            // table middle, hand bottom). iPad: the same zones form a fixed-gap
                            // block centred vertically, so the elements sit close together and the
                            // unavoidable felt on the very tall canvas reads as a margin at the
                            // screen edges rather than dead bands between the zones.
                            VStack(spacing: 0) {
                                if isPad { Spacer(minLength: spacing) }
                                VStack(spacing: spacing) {
                                    partnerZone(maxWidth: partnerMaxWidth, seatBackSize: seatBackSize,
                                                openHandCardSize: partnerCardSize)
                                    zoneGap(isPad: isPad, compact: isLandscape)
                                    opponentCenterRow(spacing: spacing, seatBackSize: seatBackSize,
                                                      centerSize: centerSize, sideWidth: resolvedSide, spread: isPad)
                                    zoneGap(isPad: isPad, compact: isLandscape)

                                    if let roundRemaining = vm.roundTimeRemaining {
                                        RoundTimerBadge(remaining: roundRemaining, total: vm.roundTimeLimit)
                                    }
                                    PromptBanner(prompt: vs.prompt, tint: elementGlow)
                                        .padding(.horizontal, Theme.Space.s4)
                                    // Per-move countdown over the effective limit (10s, or 5s in
                                    // the round's final minute — Phase 17 C10). Fills at the limit
                                    // and drains to zero so the shortened final-minute window reads
                                    // correctly.
                                    if let moveRemaining = vm.moveTimeRemaining, moveRemaining <= vm.moveTimeLimit {
                                        MoveTimerBar(remaining: moveRemaining, total: vm.moveTimeLimit)
                                            .padding(.horizontal, Theme.Space.s4)
                                    }
                                    bottomControls
                                    pointsAtRiskPill
                                    HandView(hand: vs.localHand, cardSize: handSize,
                                             showColourName: showColourName, showPattern: showPattern,
                                             reducedMotion: reducedMotion, onPlay: vm.play)
                                        .reportTableAnchor(.seat(0), in: tableSpace)
                                }
                                .frame(maxWidth: contentMaxWidth)
                                .frame(maxWidth: .infinity)
                                if isPad { Spacer(minLength: spacing) }
                            }
                            .padding(.vertical, spacing)
                            .frame(minHeight: geo.size.height - 60)
                        }
                        // Loss desaturates the table gently underneath the overlay (ux-spec.md
                        // §10 "Round loss feedback"); skipped under Reduced visual effects.
                        .saturation(tableSaturation)
                        .animation(.easeInOut(duration: 0.6), value: tableSaturation)
                    }

                    if let hint = vm.lastInvalidHint { invalidTooltip(hint, handCardSize: handSize) }

                    if let handoff = vm.pendingHandoffSeat {
                        HandoffOverlay(seat: handoff, onReady: vm.confirmHandoff)
                    }

                    if vs.phase == .roundEnded || vs.phase == .gameEnded {
                        RoundEndView(vs: vs, settings: settings, onNext: vm.beginNextRound, onExit: onExit)
                    }

                    // Colour choice as a centred in-table overlay (Phase 17 C5) — biased toward
                    // the top so it sits over the table centre and never covers the hand or the
                    // partner's open hand. The scrim keeps the cards visible (just dimmed).
                    if vs.awaitingLocalColourChoice {
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                ColourPickerView(onChoose: vm.chooseColour, showPattern: showPattern)
                                Spacer(minLength: 0)
                                Spacer(minLength: 0)   // bias the panel above centre, clear of the hand
                            }
                        }
                        .transition(.opacity)
                    }

                    // Turn hand-off sweep (Stage 3.3): a glowing orb travels from the finishing
                    // seat to the next, under the flying cards so a play/draw reads on top.
                    ForEach(spotlights) { spot in
                        TurnSpotlightView(spotlight: spot, tint: elementGlow) {
                            spotlights.removeAll { $0.id == spot.id }
                        }
                    }

                    // Cross-table draw travel (Stage 3.5): card-backs fly from the draw pile to
                    // the drawing seat, staggered so a big penalty visibly takes longer.
                    ForEach(drawFlights) { flight in
                        FlyingBackView(flight: flight, cardSize: drawFlightSize(centerSize)) {
                            drawFlights.removeAll { $0.id == flight.id }
                        }
                    }

                    // Draw Four challenge prompt (Phase 17 B2, opt-in) — an in-table overlay to
                    // the target of a fresh Draw Four, styled like the colour picker so it never
                    // covers the hand.
                    if vs.awaitingLocalDrawFourChallenge {
                        ZStack {
                            Color.black.opacity(0.4).ignoresSafeArea()
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                DrawFourChallengeView(
                                    challengedName: vs.drawFourChallengedName ?? "The previous player",
                                    priorColour: vs.drawFourPriorColour,
                                    onChallenge: { vm.resolveDrawFourChallenge(true) },
                                    onAccept: { vm.resolveDrawFourChallenge(false) })
                                Spacer(minLength: 0)
                                Spacer(minLength: 0)
                            }
                        }
                        .transition(.opacity)
                    }

                    // Cross-table played-card travel (Stage 3.1): ghost cards fly from the
                    // acting seat to the discard. Sits above the table but below modals.
                    ForEach(flights) { flight in
                        FlyingCardView(flight: flight, cardSize: centerSize,
                                       reducedMotion: reducedMotion) {
                            flights.removeAll { $0.id == flight.id }
                        }
                    }
                }
                .coordinateSpace(name: tableSpace)
                .onPreferenceChange(TableAnchorPreference.self) { tableAnchors = $0 }
                .onChange(of: vm.cardFlight) { _, event in launchFlight(event) }
                .onChange(of: vm.drawFlight) { _, event in launchDrawFlights(event) }
                .onChange(of: currentSeatPosition) { old, new in launchSpotlight(from: old, to: new) }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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
        // Show a seat cue (skip / forced draw) briefly, then clear it (Phase 17 C3).
        .onChange(of: vm.seatCue) { _, new in
            guard let new else { return }
            withAnimation { activeCue = new }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                if activeCue?.token == new.token { withAnimation { activeCue = nil } }
            }
        }
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
                .wpGlassCapsule()

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
            .wpGlassCapsule()

            Spacer(minLength: Theme.Space.s2)

            Button { showPause = true; vm.pause() } label: {
                Image(systemName: "pause.fill").font(.footnote)
                    .frame(width: 28, height: 28)
                    .wpGlassCircle()
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Pause")
            .accessibilityIdentifier("game-pause-button")
        }
        .lineLimit(1)
        .padding(.horizontal, Theme.Space.s4)
    }

    /// Solo! is always on screen (Phase 17 C7) but only enabled at the legal moment — while
    /// you hold two cards on your turn, or at one card within the effect-drop grace window.
    @ViewBuilder private var bottomControls: some View {
        let enabled = vs.soloButtonVisible
        Button { vm.callSolo() } label: {
            Label("Solo!", systemImage: "exclamationmark.circle.fill")
                .fontWeight(.bold)
        }
        .buttonStyle(.borderedProminent)
        .tint(enabled ? Theme.Palette.warning : Color.gray)
        .opacity(enabled ? 1 : 0.45)
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
        .accessibilityIdentifier("game-solo-button")
        .accessibilityHint(enabled
            ? "Call Solo before playing your second-to-last card, or you can be caught for a penalty."
            : "Solo can be called when you are about to play down to your last card.")
    }

    /// Live "points at risk" (Phase 11 E) — the raw card-value sum of the local player's own
    /// team's hands, shown only for that team since it's derived purely from already-visible
    /// hands (the local player's own + the open partner hand) and never leaks opponent info.
    private var pointsAtRiskPill: some View {
        // "On the table", not "Team at risk" — the original critique flagged the old wording
        // as alarming during calm play (design-plan.md §3.1).
        Text("On the table: \(vs.localTeamPointsAtRisk) pts")
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Theme.Space.s3).padding(.vertical, Theme.Space.s1)
            .wpGlassCapsule()
            // Playable hand cards lift by 18% of their height (HandView); on iPad's 150pt
            // cards that's ~27pt, which reaches this pill without the extra clearance.
            .padding(.bottom, Theme.Space.s4)
            .accessibilityLabel("Your team would lose \(vs.localTeamPointsAtRisk) points if you lost the round now.")
    }

    /// Gap between table zones: a flexible spacer on iPhone (fills the height), a fixed gap on
    /// iPad (so the zone block has a fixed height that the surrounding spacers can centre).
    /// `compact` (iPad landscape) halves the gap — height is the scarce axis there.
    @ViewBuilder private func zoneGap(isPad: Bool, compact: Bool = false) -> some View {
        if isPad {
            Color.clear.frame(height: compact ? Theme.Space.s4 : Theme.Space.s8)
        } else {
            Spacer(minLength: Theme.Space.s3)
        }
    }

    /// Partner's open hand, anchored at the top of the table (A6: `maxFanWidth` clamps the fan
    /// to the on-screen width so it never clips off the right edge).
    /// The transient skip / forced-draw cue for a seat, if the active cue targets it (C3).
    private func cue(for seat: PlayerSeatViewState) -> SeatCueKind? {
        (activeCue?.seatIDs.contains(seat.id) == true) ? activeCue?.kind : nil
    }

    @ViewBuilder private func partnerZone(maxWidth: CGFloat, seatBackSize: CGSize,
                                          openHandCardSize: CGSize) -> some View {
        if let partner = seat(at: 2) {
            PlayerZoneView(seat: partner, showColourName: showColourName, showPattern: showPattern,
                           cardBackSize: seatBackSize, openHandCardSize: openHandCardSize,
                           maxFanWidth: maxWidth,
                           reducedMotion: reducedMotion, isThinking: partner.id == vm.thinkingPlayerID,
                           thinkingDotCount: thinkingDotCount, accent: elementGlow,
                           cue: cue(for: partner))
                .reportTableAnchor(.seat(2), in: tableSpace)
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
            canDraw: vs.canDrawNow,
            mustDraw: vs.mustDrawNow, forcedPickup: vs.forcedPickupCount != nil,
            showColourName: showColourName, showPattern: showPattern,
            reducedMotion: reducedMotion, cardSize: size,
            colourChoicePending: vs.colourChoicePending,
            recentDiscards: vs.recentDiscards, flightSpace: tableSpace, onDraw: vm.drawCard
        )
    }

    private func opponentZone(_ seat: PlayerSeatViewState, backSize: CGSize, width: CGFloat) -> some View {
        PlayerZoneView(
            seat: seat, cardBackSize: backSize, maxFanWidth: width - Theme.Space.s2 * 2,
            reducedMotion: reducedMotion,
            isThinking: seat.id == vm.thinkingPlayerID, thinkingDotCount: thinkingDotCount,
            accent: elementGlow, cue: cue(for: seat),
            onCatchSolo: seat.id == vs.catchableSoloPlayerID ? { vm.callOut(seat.id) } : nil
        )
        .frame(width: width)
        .reportTableAnchor(.seat(seat.tablePosition), in: tableSpace)
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

    /// Seats are placed by `tablePosition` (relative to the displayed player), not absolute
    /// seat number, so a pass-and-play perspective flip rotates the whole table.
    private func seat(at position: Int) -> PlayerSeatViewState? {
        vs.seats.first { $0.tablePosition == position }
    }

    /// Launch a ghost card from the acting seat to the discard for a play event (Stage 3.1).
    /// No-op when motion is disabled or the endpoints haven't been measured yet.
    private func launchFlight(_ event: CardFlightEvent?) {
        guard let event, !travelDisabled,
              let seat = vs.seats.first(where: { $0.id == event.fromSeatID }),
              let fromRect = tableAnchors[.seat(seat.tablePosition)],
              let toRect = tableAnchors[.discard] else { return }
        flights.append(CardFlight(
            card: event.card,
            from: CGPoint(x: fromRect.midX, y: fromRect.midY),
            to: CGPoint(x: toRect.midX, y: toRect.midY)))
    }

    /// Launch `count` card-backs from the draw pile to the drawing seat (Stage 3.5), staggered
    /// so the pickup's duration scales with how many cards it is. Visible backs are capped, but
    /// the stagger still lengthens for the true count so a 6-card penalty reads longer than one.
    private func launchDrawFlights(_ event: DrawFlightEvent?) {
        guard let event, !travelDisabled,
              let seat = vs.seats.first(where: { $0.id == event.toSeatID }),
              let fromRect = tableAnchors[.drawPile],
              let toRect = tableAnchors[.seat(seat.tablePosition)] else { return }
        let from = CGPoint(x: fromRect.midX, y: fromRect.midY)
        let to = CGPoint(x: toRect.midX, y: toRect.midY)
        let visible = min(max(event.count, 1), 8)
        for i in 0..<visible {
            drawFlights.append(DrawFlight(from: from, to: to, delay: Double(i) * 0.11))
        }
    }

    /// A travelling card-back reads best a touch smaller than the focal discard.
    private func drawFlightSize(_ centerSize: CGSize) -> CGSize {
        CGSize(width: centerSize.width * 0.72, height: centerSize.height * 0.72)
    }

    /// Sweep a spotlight orb from the finishing seat to the seat whose turn it now is (Stage 3.3).
    /// No-op when motion is off, the turn didn't actually move seats, or an anchor is unmeasured.
    private func launchSpotlight(from old: Int?, to new: Int?) {
        guard !travelDisabled, let old, let new, old != new,
              let fromRect = tableAnchors[.seat(old)],
              let toRect = tableAnchors[.seat(new)] else { return }
        spotlights.append(TurnSpotlight(
            from: CGPoint(x: fromRect.midX, y: fromRect.midY),
            to: CGPoint(x: toRect.midX, y: toRect.midY)))
    }

    private var targetCandidates: [PlayerSeatViewState] {
        vs.seats.filter { vs.localTargetChoices.contains($0.id) }
    }

    private var targetSheetBinding: Binding<Bool> {
        Binding(get: { !vs.localTargetChoices.isEmpty }, set: { _ in })
    }
    private var teamPassSheetBinding: Binding<Bool> {
        Binding(get: { vs.awaitingLocalTeamPass }, set: { _ in })
    }
}

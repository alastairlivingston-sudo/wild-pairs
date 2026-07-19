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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var showPause = false
    /// The seat cue (skip / forced draw) currently on screen; the ViewModel emits one and this
    /// view shows it briefly then clears it (Phase 17 C3).
    @State private var activeCue: SeatCueEvent?
    /// One-shot presentation state for the seat that has just been caught missing Solo. The
    /// rules engine already applies the draw; this state only positions the transient stamp.
    @State private var activeSoloPenalty: SoloPenaltyEvent?
    /// Live frames of each seat + the discard, in the table coordinate space, feeding the
    /// cross-table played-card travel (Phase 17 Stage 3.1).
    @State private var tableAnchors: [TableAnchor: CGRect] = [:]
    /// Ghost cards currently flying from an acting seat to the discard.
    @State private var flights: [CardFlight] = []
    /// Card-backs currently flying from the draw pile to a seat (Phase 17 Stage 3.5).
    @State private var drawFlights: [DrawFlight] = []
    /// IDs of cards whose visual ghost is still travelling. The published discard is hidden until
    /// the corresponding flight lands, preventing one card from appearing in two places at once.
    @State private var travellingCardIDs: Set<UUID> = []
    /// One-shot visible confirmation for any successful Solo declaration.
    @State private var activeSoloCall: SoloCallEvent?
    private let tableSpace = "wpTable"

    private var vs: GameViewState { vm.viewState }
    private var activeSeat: PlayerSeatViewState? { vs.seats.first { $0.isCurrentPlayer } }
    private var activeTurnLabel: String {
        guard let seat = activeSeat else { return "TURN" }
        if seat.isLocalPlayer { return "YOUR TURN" }
        if seat.tablePosition == 2 { return "PARTNER'S TURN" }
        return "\(seat.name.uppercased())'S TURN"
    }
    private var localCaughtPenaltyCount: Int? {
        guard let localID = vs.seats.first(where: { $0.isLocalPlayer })?.id,
              activeSoloPenalty?.seatID == localID else { return nil }
        return activeSoloPenalty?.count
    }
    private var handCardSize: CGSize {
        let large = effectiveLargeCards
        // iPad hand reads larger so the deck has real presence on the wide canvas (ux-spec §7).
        if hSize == .regular { return large ? Theme.CardSize.padHandLarge : Theme.CardSize.padHand }
        return large ? Theme.CardSize.regularHand : Theme.CardSize.compactHand
    }
    private var effectiveLargeCards: Bool {
        settings.userSettings.largeCards || dynamicTypeSize >= .accessibility3
    }
    private var showColourName: Bool { settings.userSettings.colourBlindMode }
    private var showPattern: Bool { settings.userSettings.colourBlindMode && settings.userSettings.patternFills }
    private var reducedMotion: Bool { settings.userSettings.reducedVisualEffects }
    private var motionDisabled: Bool { reducedMotion || systemReduceMotion }
    /// Skip the cross-table travel ghost entirely when motion is off (Reduced Motion, or the
    /// user's Animation → Off setting) — the discard just updates in place.
    private var travelDisabled: Bool { motionDisabled || settings.userSettings.animationSpeed == .off }
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
                    ? (effectiveLargeCards ? Theme.CardSize.padHand : Theme.CardSize.regularHand)
                    : handCardSize
                // 72pt keeps the crest, five-card fan, and count badge readable while allowing
                // the 24pt draw/discard gap to fit on a 375pt-wide iPhone without clipping.
                let resolvedSide = max(sideWidth, 72)
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
                    TableBackground(
                        element: vs.currentColour,
                        turnDirection: vs.phase == .playing ? vs.turnDirection : nil,
                        directionAnimationDisabled: settings.userSettings.animationSpeed == .off,
                        style: settings.userSettings.tableBackgroundStyle
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 0) {
                        edgeHUD(compact: !isPad)

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

                                    PromptBanner(prompt: vs.prompt, tint: elementGlow)
                                        .padding(.horizontal, Theme.Space.s4)
                                    bottomControls
                                    localHandZone(cardSize: handSize)
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
                        .animation(motionDisabled ? nil : .easeInOut(duration: 0.6), value: tableSaturation)
                    }

                    if let hint = vm.lastInvalidHint { invalidTooltip(hint, handCardSize: handSize) }

                    if let handoff = vm.pendingHandoffSeat {
                        HandoffOverlay(seat: handoff, onReady: vm.confirmHandoff)
                    }

                    if vs.phase == .roundEnded || vs.phase == .gameEnded {
                        RoundEndSequenceOverlay(
                            vs: vs,
                            settings: settings,
                            anchors: tableAnchors,
                            reducedMotion: motionDisabled,
                            onNext: vm.beginNextRound,
                            onExit: onExit
                        )
                        .transition(.opacity)
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
                                       reducedMotion: motionDisabled) {
                            finishFlight(flight)
                        }
                    }

                    if let call = activeSoloCall {
                        SoloCallShoutOverlay(
                            callerLabel: soloCallerLabel(call),
                            accent: elementGlow,
                            reducedMotion: motionDisabled
                        )
                        .transition(motionDisabled ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                        .zIndex(20)
                    }
                }
                .coordinateSpace(name: tableSpace)
                .onPreferenceChange(TableAnchorPreference.self) { tableAnchors = $0 }
                .onChange(of: vm.cardFlight) { _, event in launchFlight(event) }
                .onChange(of: vm.drawFlight) { _, event in launchDrawFlights(event) }
                .onChange(of: vm.soloPenalty) { _, event in presentSoloPenalty(event) }
                .onChange(of: vm.soloCall) { _, event in presentSoloCall(event) }
                .onChange(of: vs.roundNumber) { _, _ in
                    // Defensive (10/10 gate: no stale hidden discard): a new round must never
                    // inherit an in-flight card ID left over from the previous round, which would
                    // keep a discard hidden. Any prior-round flight is moot once the round turns.
                    flights.removeAll()
                    travellingCardIDs.removeAll()
                }
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
            withAnimation(motionDisabled ? nil : Theme.Motion.cardSettle) { activeCue = new }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Theme.Motion.seatCueDisplayDuration
            ) {
                guard activeCue?.token == new.token else { return }
                withAnimation(motionDisabled ? nil : Theme.Motion.fast) { activeCue = nil }
            }
        }
        // The felt table is a deliberately dark-first surface (Phase 9 A2); locking the
        // colour scheme keeps text/contrast tokens (.secondary, .white) deterministic
        // instead of drifting with the system light/dark appearance.
        .preferredColorScheme(.dark)
    }

    private func edgeHUD(compact: Bool) -> some View {
        GameEdgeHUD(
            roundNumber: vs.roundNumber,
            scoreboard: vs.scoreboard,
            turnLabel: activeTurnLabel,
            turnDirection: vs.turnDirection,
            roundRemaining: vm.roundTimeRemaining,
            roundTotal: vm.roundTimeLimit,
            visualMoveRemaining: vm.moveTimeRemaining,
            semanticMoveRemaining: vm.moveTimeRemaining,
            moveTotal: vm.moveTimeLimit,
            accent: elementGlow,
            compact: compact,
            onPause: { showPause = true; vm.pause() }
        )
    }

    /// Solo! remains visible so its location is learned, but the urgent legal state becomes a
    /// deliberate thumb-zone callout rather than another generic bordered button.
    private var bottomControls: some View {
        HStack(alignment: .center) {
            if let count = localCaughtPenaltyCount {
                CaughtPenaltyStamp(count: count)
                    .scaleEffect(0.84)
                    .frame(width: 72, height: 64)
                    .transition(motionDisabled ? .opacity : .scale(scale: 0.45).combined(with: .opacity))
            }
            Spacer(minLength: Theme.Space.s4)
            SoloTableCallButton(
                isEnabled: vs.soloButtonVisible,
                reducedMotion: motionDisabled,
                action: vm.callSolo
            )
        }
        .padding(.horizontal, Theme.Space.s4)
        .frame(maxWidth: .infinity)
    }

    private func localHandZone(cardSize: CGSize) -> some View {
        HandView(
            hand: vs.localHand,
            cardSize: cardSize,
            showColourName: showColourName,
            showPattern: showPattern,
            reducedMotion: motionDisabled,
            onPlay: vm.play
        )
        .padding(.horizontal, Theme.Space.s1)
        .overlay {
            if vs.isLocalPlayerTurn {
                ActiveSeatBrackets(tint: elementGlow)
                    .padding(.horizontal, Theme.Space.s2)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .top) {
            if vs.isLocalPlayerTurn {
                Text("PLAY NOW")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.4)
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, Theme.Space.s2)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.white))
                    .overlay(Capsule().strokeBorder(elementGlow.opacity(0.72), lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    .offset(y: -7)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .animation(motionDisabled ? nil : Theme.Motion.fast, value: vs.isLocalPlayerTurn)
        .reportTableAnchor(.seat(0), in: tableSpace)
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
                           reducedMotion: motionDisabled, isThinking: partner.id == vm.thinkingPlayerID,
                           thinkingDotCount: thinkingDotCount, accent: elementGlow,
                           cue: cue(for: partner),
                           caughtPenaltyCount: penaltyCount(for: partner))
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
            reducedMotion: motionDisabled, cardSize: size,
            colourChoicePending: vs.colourChoicePending,
            recentDiscards: vs.recentDiscards, flightSpace: tableSpace,
            pileSpacing: Theme.Table.drawDiscardGap,
            hiddenTopCardIDs: travellingCardIDs,
            onDraw: vm.drawCard
        )
    }

    private func opponentZone(_ seat: PlayerSeatViewState, backSize: CGSize, width: CGFloat) -> some View {
        PlayerZoneView(
            seat: seat, cardBackSize: backSize, maxFanWidth: width - Theme.Space.s2 * 2,
            reducedMotion: motionDisabled,
            isThinking: seat.id == vm.thinkingPlayerID, thinkingDotCount: thinkingDotCount,
            accent: elementGlow, cue: cue(for: seat),
            caughtPenaltyCount: penaltyCount(for: seat),
            onCatchSolo: seat.id == vs.catchableSoloPlayerID ? { vm.callOut(seat.id) } : nil
        )
        .frame(width: width)
        .reportTableAnchor(.seat(seat.tablePosition), in: tableSpace)
    }

    private func penaltyCount(for seat: PlayerSeatViewState) -> Int? {
        activeSoloPenalty?.seatID == seat.id ? activeSoloPenalty?.count : nil
    }

    private func presentSoloPenalty(_ event: SoloPenaltyEvent?) {
        guard let event else { return }
        withAnimation(motionDisabled ? nil : .spring(response: 0.38, dampingFraction: 0.68)) {
            activeSoloPenalty = event
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Theme.Motion.caughtPenaltyDisplayDuration
        ) {
            guard activeSoloPenalty?.token == event.token else { return }
            withAnimation(motionDisabled ? nil : .easeOut(duration: 0.22)) {
                activeSoloPenalty = nil
            }
        }
    }

    private func presentSoloCall(_ event: SoloCallEvent?) {
        guard let event else { return }
        withAnimation(motionDisabled ? nil : Theme.Motion.soloShout) {
            activeSoloCall = event
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Theme.Motion.soloShoutDisplayDuration
        ) {
            guard activeSoloCall?.token == event.token else { return }
            withAnimation(motionDisabled ? nil : .easeOut(duration: 0.18)) {
                activeSoloCall = nil
            }
        }
    }

    private func soloCallerLabel(_ event: SoloCallEvent) -> String {
        guard let caller = vs.seats.first(where: { $0.id == event.seatID }) else { return "CALLED" }
        if caller.isLocalPlayer { return "YOU CALLED" }
        if caller.tablePosition == 2 { return "PARTNER CALLED" }
        return "\(caller.name.uppercased()) CALLED"
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

    /// Launch a ghost card from the acting seat to the discard. The real top discard is hidden
    /// until this flight lands, so causality is shown once rather than as a duplicate card.
    private func launchFlight(_ event: CardFlightEvent?) {
        guard let event, !travelDisabled,
              let seat = vs.seats.first(where: { $0.id == event.fromSeatID }),
              let fromRect = tableAnchors[.seat(seat.tablePosition)],
              let toRect = tableAnchors[.discard] else { return }

        travellingCardIDs.insert(event.card.id)
        flights.append(CardFlight(
            card: event.card,
            from: CGPoint(x: fromRect.midX, y: fromRect.midY),
            to: CGPoint(x: toRect.midX, y: toRect.midY)
        ))
    }

    private func finishFlight(_ flight: CardFlight) {
        flights.removeAll { $0.id == flight.id }
        withAnimation(motionDisabled ? nil : Theme.Motion.cardSettle) {
            _ = travellingCardIDs.remove(flight.card.id)
        }
    }

    /// Launch `count` card-backs from the draw pile to the drawing seat. Cards receive slightly
    /// different arrival lanes and arcs, making a +4/+6 pickup countable instead of a single blur.
    private func launchDrawFlights(_ event: DrawFlightEvent?) {
        guard let event, !travelDisabled,
              let seat = vs.seats.first(where: { $0.id == event.toSeatID }),
              let fromRect = tableAnchors[.drawPile],
              let toRect = tableAnchors[.seat(seat.tablePosition)] else { return }
        let from = CGPoint(x: fromRect.midX, y: fromRect.midY)
        let baseDestination = CGPoint(x: toRect.midX, y: toRect.midY)
        let visible = min(max(event.count, 1), 8)
        let centre = CGFloat(max(visible - 1, 0)) * 0.5

        for index in 0..<visible {
            let lane = CGFloat(index) - centre
            let destination: CGPoint
            switch seat.tablePosition {
            case 1, 3:
                destination = CGPoint(x: baseDestination.x, y: baseDestination.y + lane * 6)
            default:
                destination = CGPoint(x: baseDestination.x + lane * 6, y: baseDestination.y)
            }
            let distance = hypot(destination.x - from.x, destination.y - from.y)
            let bendMagnitude = min(72, max(24, distance * 0.14))
            let bend = index.isMultiple(of: 2) ? bendMagnitude : -bendMagnitude
            drawFlights.append(DrawFlight(
                from: from,
                destination: destination,
                delay: Double(index) * Theme.Motion.drawFlightStagger,
                bend: bend,
                landingRotation: Double(lane) * 2.4
            ))
        }
    }

    /// A travelling card-back reads best a touch smaller than the focal discard.
    private func drawFlightSize(_ centerSize: CGSize) -> CGSize {
        CGSize(width: centerSize.width * 0.72, height: centerSize.height * 0.72)
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


// MARK: - One-shot table moments

/// A successful Solo declaration is a table-wide social moment, even in an offline game. The
/// engine already emitted the declaration; this overlay only makes the call visible for one
/// second. Reduced Motion keeps the final burst static and uses opacity only.
private struct SoloCallShoutOverlay: View {
    let callerLabel: String
    let accent: Color
    let reducedMotion: Bool

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var appeared = false

    private var motionDisabled: Bool { reducedMotion || systemReduceMotion }

    var body: some View {
        ZStack {
            if !motionDisabled {
                Circle()
                    .stroke(accent.opacity(0.70), lineWidth: 3)
                    .scaleEffect(appeared ? 1.34 : 0.68)
                    .opacity(appeared ? 0 : 0.82)
            }

            SoloBurstShape(points: 18, innerRatio: 0.79)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFFE277), Theme.Palette.warning, Color(hex: 0xC94F19)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            SoloBurstShape(points: 18, innerRatio: 0.79)
                .strokeBorder(.white.opacity(0.94), lineWidth: 2)

            VStack(spacing: 2) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 20, weight: .black))
                Text("SOLO!")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-0.8)
                Text(callerLabel)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.65)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
            .foregroundStyle(Theme.Palette.onAccent)
            .padding(.horizontal, Theme.Space.s3)
        }
        .frame(width: 184, height: 184)
        .scaleEffect(appeared ? 1 : 0.62)
        .opacity(appeared ? 1 : 0)
        .shadow(color: .black.opacity(0.48), radius: 18, y: 8)
        .onAppear {
            if motionDisabled {
                appeared = true
            } else {
                withAnimation(Theme.Motion.soloShout) { appeared = true }
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Solo called. \(callerLabel.lowercased()).")
    }
}

/// Score is Solo's only reward currency, so the end of a round first explains where the score
/// came from: remaining-hand values sit at the contributing seats, collect to the centre, and
/// resolve into the awarded score before the existing summary appears. No rules are calculated
/// here; every value comes from `GameViewState`.
private struct RoundEndSequenceOverlay: View {
    let vs: GameViewState
    @ObservedObject var settings: AppSettings
    let anchors: [TableAnchor: CGRect]
    let reducedMotion: Bool
    let onNext: () -> Void
    let onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var stage: Stage = .seatValues
    @State private var displayedAward = 0

    private enum Stage: Equatable {
        case seatValues
        case collecting
        case award
        case summary
    }

    private var motionDisabled: Bool { reducedMotion || systemReduceMotion }
    private var award: Int { vs.roundScoreAwarded ?? 0 }
    private var multiplier: Int { max(1, vs.roundScoreMultiplier ?? 1) }
    private var baseScore: Int {
        vs.roundBaseScore ?? contributorScores.reduce(0) { $0 + $1.remainingPoints }
    }
    private var winningTeam: TeamID? { vs.roundWinningTeamID }
    private var contributorScores: [RoundSeatScoreViewState] {
        let losingTeamRows = vs.roundSeatScores.filter {
            guard let winningTeam else { return $0.remainingPoints > 0 }
            return $0.teamID != winningTeam && $0.remainingPoints > 0
        }
        return losingTeamRows.isEmpty
            ? vs.roundSeatScores.filter { $0.remainingPoints > 0 }
            : losingTeamRows
    }

    var body: some View {
        ZStack {
            if stage == .summary || award <= 0 || contributorScores.isEmpty {
                RoundEndView(
                    vs: vs,
                    settings: settings,
                    onNext: onNext,
                    onExit: onExit
                )
                .transition(.opacity)
            } else {
                Color.black.opacity(0.58).ignoresSafeArea()

                GeometryReader { geo in
                    ForEach(contributorScores) { score in
                        RoundSeatScoreChip(score: score)
                            .position(position(for: score, in: geo.size))
                            .scaleEffect(stage == .collecting ? 0.70 : 1)
                            .opacity(stage == .seatValues ? 1 : 0)
                            .animation(motionDisabled ? nil : Theme.Motion.roundScore, value: stage)
                    }

                    if stage == .award {
                        roundAwardCard
                            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.49)
                            .transition(
                                motionDisabled
                                    ? .opacity
                                    : .scale(scale: 0.58).combined(with: .opacity)
                            )
                    }
                }
            }
        }
        .task(id: vs.roundNumber) { await runSequence() }
        .accessibilityElement(children: .contain)
    }

    private func position(for score: RoundSeatScoreViewState, in size: CGSize) -> CGPoint {
        if stage == .collecting || stage == .award {
            return CGPoint(x: size.width * 0.5, y: size.height * 0.49)
        }
        if let rect = anchors[.seat(score.tablePosition)] {
            return CGPoint(x: rect.midX, y: rect.midY)
        }
        switch score.tablePosition {
        case 0: return CGPoint(x: size.width * 0.50, y: size.height * 0.79)
        case 1: return CGPoint(x: size.width * 0.18, y: size.height * 0.47)
        case 2: return CGPoint(x: size.width * 0.50, y: size.height * 0.20)
        default: return CGPoint(x: size.width * 0.82, y: size.height * 0.47)
        }
    }

    private var roundAwardCard: some View {
        VStack(spacing: Theme.Space.s1) {
            Text(vs.localTeamWon == true ? "YOUR TEAM BANKS" : "OPPONENTS BANK")
                .font(.caption2.weight(.black))
                .tracking(0.85)
            if multiplier > 1 {
                Text("\(baseScore) × \(multiplier)")
                    .font(.caption.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.72))
            }
            Text("+\(displayedAward)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(displayedAward)))
            Text("ROUND SCORE")
                .font(.caption.weight(.black))
                .tracking(0.7)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Space.s6)
        .padding(.vertical, Theme.Space.s4)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.r4, style: .continuous)
                .fill(Color.black.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r4, style: .continuous)
                .strokeBorder(winnerTint.opacity(0.90), lineWidth: 2)
        )
        .shadow(color: winnerTint.opacity(0.34), radius: 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            multiplier > 1
                ? "Round score awarded: \(baseScore) points times \(multiplier), \(award) points total"
                : "Round score awarded: \(award) points"
        )
    }

    private var winnerTint: Color {
        winningTeam == .teamA ? Theme.Palette.teamA : Theme.Palette.teamB
    }

    @MainActor private func runSequence() async {
        guard award > 0, !contributorScores.isEmpty else {
            stage = .summary
            return
        }

        if motionDisabled {
            displayedAward = award
            stage = .award
            try? await Task.sleep(nanoseconds: 850_000_000)
            guard !Task.isCancelled else { return }
            stage = .summary
            return
        }

        try? await Task.sleep(nanoseconds: 240_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(Theme.Motion.roundScore) { stage = .collecting }

        try? await Task.sleep(nanoseconds: 500_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(Theme.Motion.roundScore) {
            stage = .award
            displayedAward = award
        }

        try? await Task.sleep(nanoseconds: 700_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.18)) { stage = .summary }
    }
}

private struct RoundSeatScoreChip: View {
    let score: RoundSeatScoreViewState

    var body: some View {
        VStack(spacing: 1) {
            Text(score.name.uppercased())
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.45)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text("\(score.remainingPoints)")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .monospacedDigit()
            Text("IN HAND")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(0.55)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Space.s3)
        .padding(.vertical, Theme.Space.s2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.r3, style: .continuous)
                .fill(Color.black.opacity(0.80))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r3, style: .continuous)
                .strokeBorder(.white.opacity(0.72), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.44), radius: 8, y: 4)
        .accessibilityLabel("\(score.name) had \(score.remainingPoints) points remaining")
    }
}

/// Native SwiftUI Solo control. The urgent state has the energy of a table call, but the text,
/// outline, and megaphone carry the meaning when motion, glow, or colour are unavailable.
private struct SoloTableCallButton: View {
    let isEnabled: Bool
    let reducedMotion: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var pulse = false

    private var motionDisabled: Bool { reducedMotion || systemReduceMotion }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isEnabled {
                    SoloBurstShape(points: 15, innerRatio: 0.82)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xFFD85A), Theme.Palette.warning, Color(hex: 0xD46A1A)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    SoloBurstShape(points: 15, innerRatio: 0.82)
                        .strokeBorder(.white.opacity(0.90), lineWidth: 1.5)
                } else {
                    Capsule()
                        .fill(Color.black.opacity(0.50))
                    Capsule()
                        .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                }

                VStack(spacing: 0) {
                    HStack(spacing: Theme.Space.s1) {
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 15, weight: .black))
                        Text("Solo!")
                            .font(.title3.weight(.black))
                            .minimumScaleFactor(0.72)
                            .lineLimit(1)
                    }
                    if isEnabled {
                        Text("CALL BEFORE PLAY")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.45)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(isEnabled ? Theme.Palette.onAccent : .white.opacity(0.58))
                .shadow(color: isEnabled ? .white.opacity(0.28) : .clear, radius: 1, y: -1)
            }
            .frame(width: 124, height: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(SoloCallPressStyle(motionDisabled: motionDisabled))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.62)
        .scaleEffect(isEnabled && pulse ? 1.045 : 1)
        .shadow(
            color: isEnabled ? Theme.Palette.warning.opacity(pulse ? 0.52 : 0.30) : .clear,
            radius: pulse ? 16 : 9,
            y: 3
        )
        // Three finite emphasis beats teach urgency without becoming permanent table noise.
        .task(id: isEnabled && !motionDisabled) {
            pulse = false
            guard isEnabled, !motionDisabled else { return }
            for _ in 0..<3 {
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.14)) { pulse = true }
                try? await Task.sleep(nanoseconds: 150_000_000)
                withAnimation(.easeIn(duration: 0.18)) { pulse = false }
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
        }
        .accessibilityLabel("Solo!")
        .accessibilityIdentifier("game-solo-button")
        .accessibilityValue(isEnabled ? "Ready to call" : "Not available yet")
        .accessibilityHint(
            isEnabled
                ? "Call Solo before playing down to your final card."
                : "Solo becomes available when you are about to play down to your final card."
        )
    }

}

private struct SoloCallPressStyle: ButtonStyle {
    let motionDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !motionDisabled ? 0.94 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(motionDisabled ? nil : .easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

private struct SoloBurstShape: InsettableShape {
    let points: Int
    let innerRatio: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let centre = CGPoint(x: bounds.midX, y: bounds.midY)
        let outer = min(bounds.width, bounds.height) * 0.5
        let inner = outer * innerRatio
        let vertexCount = max(points, 3) * 2
        var path = Path()

        for index in 0..<vertexCount {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * CGFloat.pi / CGFloat(points)
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: centre.x + cos(angle) * radius,
                y: centre.y + sin(angle) * radius
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> SoloBurstShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

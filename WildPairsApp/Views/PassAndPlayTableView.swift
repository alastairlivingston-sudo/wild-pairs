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

    @State private var showPause = false

    private var showColourName: Bool { settings.userSettings.colourBlindMode }
    private var showPattern: Bool { settings.userSettings.colourBlindMode && settings.userSettings.patternFills }
    private var reducedMotion: Bool { settings.userSettings.reducedVisualEffects }

    private var vs: GameViewState { vm.viewState }             // bottom (You) perspective: seats, opponents
    private var avs: GameViewState { vm.activeViewState }      // acting human: centre draw affordance + hand
    private var current: UUID? { vm.currentHumanID }
    private var elementGlow: Color { Theme.Element.scene(for: vs.currentColour).glow }

    var body: some View {
        ZStack {
            TableBackground(element: vs.currentColour).ignoresSafeArea()

            VStack(spacing: Theme.Space.s2) {
                humanHalf(for: vm.topHumanID, rotated: true)
                middleRow
                humanHalf(for: vm.bottomHumanID, rotated: false)
            }
            .padding(.vertical, Theme.Space.s2)
            .saturation(tableSaturation)
            .animation(.easeInOut(duration: 0.4), value: current)

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

    // MARK: A human end

    @ViewBuilder private func humanHalf(for humanID: UUID?, rotated: Bool) -> some View {
        if let humanID {
            let isActive = current == humanID
            Group {
                if isActive { activeHalf(humanID) } else { collapsedStrip(humanID) }
            }
            .rotationEffect(.degrees(rotated ? 180 : 0))
            .frame(maxWidth: .infinity)
            .frame(maxHeight: isActive ? .infinity : nil)
        }
    }

    /// The acting teammate's expanded, lit half: name + count + Solo!, then their playable hand.
    private func activeHalf(_ humanID: UUID) -> some View {
        VStack(spacing: Theme.Space.s2) {
            HStack(spacing: Theme.Space.s2) {
                Text(humanID == vm.bottomHumanID ? "Your turn" : "\(vm.name(for: humanID))'s turn")
                    .font(.subheadline).fontWeight(.bold).foregroundStyle(Theme.Palette.accent)
                Text("\(vm.handCount(for: humanID))")
                    .font(.caption).fontWeight(.heavy).monospacedDigit()
                    .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
                    .background(Capsule().fill(Theme.Palette.accent)).foregroundStyle(Theme.Palette.onAccent)
                if avs.soloButtonVisible {
                    Button { vm.callSolo(as: humanID) } label: {
                        Label("Solo!", systemImage: "exclamationmark.circle.fill").font(.caption).fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.Palette.warning).controlSize(.small)
                }
            }
            HandView(hand: avs.localHand, cardSize: Theme.CardSize.compactHand,
                     showColourName: showColourName, showPattern: showPattern,
                     reducedMotion: reducedMotion, onPlay: { vm.play($0.card, as: humanID) })
        }
        .padding(.horizontal, Theme.Space.s3).padding(.vertical, Theme.Space.s2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.r4)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.r4)
                    .strokeBorder(Theme.Palette.accent.opacity(0.6), lineWidth: 1.5))
                .shadow(color: reducedMotion ? .clear : Theme.Palette.accent.opacity(0.4), radius: 20)
        )
        .padding(.horizontal, Theme.Space.s3)
    }

    /// The waiting teammate's collapsed strip: name, count, a few card-backs.
    private func collapsedStrip(_ humanID: UUID) -> some View {
        HStack(spacing: Theme.Space.s2) {
            Text(vm.name(for: humanID)).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
            Text("\(vm.handCount(for: humanID))")
                .font(.caption2).fontWeight(.heavy).monospacedDigit()
                .padding(.horizontal, Theme.Space.s2).padding(.vertical, 1)
                .background(Capsule().fill(Theme.Palette.accent.opacity(0.85))).foregroundStyle(Theme.Palette.onAccent)
            HStack(spacing: -14) {
                ForEach(0..<min(vm.handCount(for: humanID), 5), id: \.self) { _ in
                    CardBackView(size: CGSize(width: 26, height: 38))
                }
            }
            Text("waiting").font(.caption2).foregroundStyle(.tertiary).textCase(.uppercase)
        }
        .padding(.horizontal, Theme.Space.s3).padding(.vertical, Theme.Space.s2)
        .opacity(0.75)
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
                showColourName: showColourName, showPattern: showPattern, reducedMotion: reducedMotion,
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
                reducedMotion: reducedMotion, isThinking: seat.id == vm.thinkingPlayerID,
                thinkingDotCount: vm.thinkingDifficulty == .easy ? 2 : 3, accent: elementGlow,
                onCatchSolo: seat.id == vs.catchableSoloPlayerID ? { vm.callOut(seat.id) } : nil)
            .frame(width: 84)
        } else {
            Color.clear.frame(width: 84)
        }
    }

    // MARK: Pause

    private var pauseButton: some View {
        VStack {
            HStack {
                Spacer()
                Button { showPause = true; vm.pause() } label: {
                    Image(systemName: "pause.fill").font(.footnote)
                        .frame(width: 28, height: 28).wpGlassCircle()
                        .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("Pause").accessibilityIdentifier("game-pause-button")
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Space.s3)
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

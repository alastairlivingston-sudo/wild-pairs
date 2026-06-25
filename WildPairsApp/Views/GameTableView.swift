import SwiftUI
import WildPairsCore

// The primary gameplay screen. Seats are arranged to match the table geometry (you at the
// bottom, partner opposite, opponents to the sides). Adapts hand-card size to the size class.
// All game logic lives in the ViewModel/Core; this view only renders state and forwards taps.

struct GameTableView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var settings: AppSettings
    let onExit: () -> Void

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.colorScheme) private var scheme
    @State private var showPause = false

    private var vs: GameViewState { vm.viewState }
    private func cardSize(isLandscape: Bool) -> CGSize {
        let large = settings.userSettings.largeCards
        if isLandscape { return Theme.CardSize.landscapeHand }
        if hSize == .regular { return large ? Theme.CardSize.selected : Theme.CardSize.regularHand }
        return large ? Theme.CardSize.regularHand : Theme.CardSize.compactHand
    }
    private var showColourName: Bool { settings.userSettings.colourBlindMode }
    private var showPattern: Bool { settings.userSettings.colourBlindMode && settings.userSettings.patternFills }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height
                let spacing = isLandscape ? Theme.Space.s2 : Theme.Space.s3
                let seatBackSize = isLandscape ? Theme.CardSize.landscapeBack : Theme.CardSize.opponentBack
                let centerSize = isLandscape ? Theme.CardSize.landscapeHand : Theme.CardSize.regularHand
                let handCardSize = cardSize(isLandscape: isLandscape)

                ZStack {
                    tableBackground.ignoresSafeArea()

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: spacing) {
                            if isLandscape {
                                landscapeSeatsRow(spacing: spacing, seatBackSize: seatBackSize, centerSize: centerSize)
                            } else {
                                portraitSeatsStack(spacing: spacing, seatBackSize: seatBackSize, centerSize: centerSize)
                            }

                            Spacer(minLength: 0)
                            PromptBanner(prompt: vs.prompt).padding(.horizontal, Theme.Space.s4)
                            bottomControls
                            HandView(hand: vs.localHand, cardSize: handCardSize,
                                     showColourName: showColourName, showPattern: showPattern, onPlay: vm.play)
                        }
                        .padding(.vertical, spacing)
                        .frame(minHeight: geo.size.height)
                    }

                    if let hint = vm.lastInvalidHint { invalidTooltip(hint, handCardSize: handCardSize) }

                    if vs.phase != .playing { RoundEndView(vs: vs, onNext: vm.beginNextRound, onExit: onExit) }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Round \(vs.roundNumber)").font(.footnote).foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .principal) { scoreChip }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showPause = true; vm.pause() } label: {
                        Image(systemName: "pause.fill").font(.title3)
                    }
                    .accessibilityLabel("Pause")
                    .accessibilityIdentifier("game-pause-button")
                }
            }
        }
        .sheet(isPresented: colourSheetBinding) {
            ColourPickerView(onChoose: vm.chooseColour)
        }
        .sheet(isPresented: targetSheetBinding) {
            TargetPickerView(candidates: targetCandidates, onChoose: vm.chooseTarget)
        }
        .sheet(isPresented: $showPause) {
            PauseMenuView(settings: settings, onResume: { showPause = false; vm.resume() },
                          onEndGame: onExit)
        }
        .onChange(of: showPause) { _, paused in if paused { vm.pause() } }
    }

    private var scoreChip: some View {
        HStack(spacing: Theme.Space.s2) {
            ForEach(vs.scoreboard) { row in
                Text("\(row.displayName) \(row.score)")
                    .font(.caption).fontWeight(.semibold)
            }
        }
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

    /// Portrait: partner stacked above a row of (left opponent, table centre, right opponent).
    private func portraitSeatsStack(spacing: CGFloat, seatBackSize: CGSize, centerSize: CGSize) -> some View {
        VStack(spacing: spacing) {
            if let partner = seat(at: 2) {
                PlayerZoneView(seat: partner, showColourName: showColourName, showPattern: showPattern,
                               cardBackSize: seatBackSize, openHandCardSize: Theme.CardSize.compactHand)
            }
            HStack(alignment: .center, spacing: spacing) {
                if let left = seat(at: 1) { opponentZone(left, backSize: seatBackSize) }
                Spacer(minLength: 0)
                tableCenter(size: centerSize)
                Spacer(minLength: 0)
                if let right = seat(at: 3) { opponentZone(right, backSize: seatBackSize) }
            }
        }
    }

    /// Landscape: all four seats and the table centre share a single row, halving the
    /// vertical footprint so nothing requires scrolling to reach on short landscape heights.
    private func landscapeSeatsRow(spacing: CGFloat, seatBackSize: CGSize, centerSize: CGSize) -> some View {
        HStack(alignment: .center, spacing: spacing) {
            if let left = seat(at: 1) { opponentZone(left, backSize: seatBackSize) }
            Spacer(minLength: 0)
            if let partner = seat(at: 2) {
                PlayerZoneView(seat: partner, showColourName: showColourName, showPattern: showPattern,
                               cardBackSize: seatBackSize, openHandCardSize: Theme.CardSize.landscapeHand)
            }
            Spacer(minLength: 0)
            tableCenter(size: centerSize)
            Spacer(minLength: 0)
            if let right = seat(at: 3) { opponentZone(right, backSize: seatBackSize) }
        }
    }

    private func tableCenter(size: CGSize) -> some View {
        TableCenterView(
            topDiscard: vs.topDiscard, currentColour: vs.currentColour,
            drawPileCount: vs.drawPileCount, turnDirection: vs.turnDirection,
            canDraw: vs.isLocalPlayerTurn, showColourName: showColourName, showPattern: showPattern,
            cardSize: size, onDraw: vm.drawCard
        )
    }

    private func opponentZone(_ seat: PlayerSeatViewState, backSize: CGSize) -> some View {
        PlayerZoneView(
            seat: seat, cardBackSize: backSize,
            onCatchSolo: seat.id == vs.catchableSoloPlayerID ? { vm.callOut(seat.id) } : nil
        )
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

    private var tableBackground: Color {
        scheme == .dark ? Theme.Palette.tableDark : Theme.Palette.tableLight
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
}

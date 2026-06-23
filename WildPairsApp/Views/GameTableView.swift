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
    private var cardSize: CGSize {
        let large = settings.userSettings.largeCards
        if hSize == .regular { return large ? Theme.CardSize.selected : Theme.CardSize.regularHand }
        return large ? Theme.CardSize.regularHand : Theme.CardSize.compactHand
    }
    private var showColourName: Bool { settings.userSettings.colourBlindMode }

    var body: some View {
        NavigationStack {
            ZStack {
                tableBackground.ignoresSafeArea()

                VStack(spacing: Theme.Space.s3) {
                    if let partner = seat(at: 2) {
                        PlayerZoneView(seat: partner, showColourName: showColourName)
                    }

                    HStack(alignment: .center, spacing: Theme.Space.s3) {
                        if let left = seat(at: 1) { opponentZone(left) }
                        Spacer(minLength: 0)
                        TableCenterView(
                            topDiscard: vs.topDiscard, currentColour: vs.currentColour,
                            drawPileCount: vs.drawPileCount, turnDirection: vs.turnDirection,
                            canDraw: vs.isLocalPlayerTurn, showColourName: showColourName,
                            onDraw: vm.drawCard
                        )
                        Spacer(minLength: 0)
                        if let right = seat(at: 3) { opponentZone(right) }
                    }

                    Spacer(minLength: 0)
                    PromptBanner(prompt: vs.prompt).padding(.horizontal, Theme.Space.s4)
                    bottomControls
                    HandView(hand: vs.localHand, cardSize: cardSize,
                             showColourName: showColourName, onPlay: vm.play)
                }
                .padding(.vertical, Theme.Space.s3)

                if let hint = vm.lastInvalidHint { invalidTooltip(hint) }

                if vs.phase != .playing { RoundEndView(vs: vs, onNext: vm.beginNextRound, onExit: onExit) }
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

    private func opponentZone(_ seat: PlayerSeatViewState) -> some View {
        PlayerZoneView(
            seat: seat,
            onCatchSolo: seat.id == vs.catchableSoloPlayerID ? { vm.callOut(seat.id) } : nil
        )
    }

    private func invalidTooltip(_ hint: String) -> some View {
        VStack {
            Spacer()
            Text(hint)
                .font(.callout).padding(Theme.Space.s3)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.r2).fill(.ultraThinMaterial))
                .padding(.bottom, cardSize.height + Theme.Space.s6)
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

import SwiftUI
import WildPairsCore

struct PauseMenuView: View {
    @ObservedObject var settings: AppSettings
    let onResume: () -> Void
    let onEndGame: () -> Void

    @State private var confirmEnd = false

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackground()
                List {
                    Section {
                        Button { onResume() } label: { Label("Resume", systemImage: "play.fill") }
                    }
                    .listRowBackground(Color.black.opacity(0.25))
                    Section {
                        NavigationLink { RulesView() } label: { Label("Rules", systemImage: "questionmark.circle.fill") }
                        NavigationLink { SettingsView(settings: settings) } label: { Label("Settings", systemImage: "gearshape.fill") }
                    }
                    .listRowBackground(Color.black.opacity(0.25))
                    Section {
                        Button(role: .destructive) {
                            if settings.userSettings.confirmEndGame { confirmEnd = true } else { onEndGame() }
                        } label: {
                            Label("End game", systemImage: "xmark.circle.fill")
                        }
                        .accessibilityIdentifier("pause-end-game")
                    }
                    .listRowBackground(Color.black.opacity(0.25))
                }
                .scrollContentBackground(.hidden)
                .tint(Theme.Palette.accent)
            }
            .navigationTitle("Paused")
            .navigationBarTitleDisplayMode(.inline)
            .alert("End this game?", isPresented: $confirmEnd) {
                Button("End game", role: .destructive, action: onEndGame)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your current game will be lost.")
            }
        }
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
    }
}

// Round/game end overlay (ux-spec.md §10): win shows a colour glow + confetti burst
// (reduced motion: static celebration badge, no confetti); loss gently desaturates and
// shows "So close!" if the human had 3 or fewer cards. Exact copy from ux-spec.md §10/§14.
struct RoundEndView: View {
    let vs: GameViewState
    @ObservedObject var settings: AppSettings
    let onNext: () -> Void
    let onExit: () -> Void

    private var isGameOver: Bool {
        if case .gameOver = vs.prompt { return true }
        return vs.phase == .gameEnded
    }
    private var isTimeout: Bool {
        if case .roundOverByTimeout = vs.prompt { return true }
        return false
    }
    private var didWin: Bool { vs.localTeamWon ?? false }
    private var winningTeamName: String? {
        switch vs.prompt {
        case .roundOver(let name), .roundOverByTimeout(let name), .gameOver(let name): return name
        default: return nil
        }
    }

    private var headline: String {
        if didWin { return isGameOver ? "Your team wins the game!" : "Your team wins this round!" }
        return isGameOver ? "Opponents win the game." : "Opponents win this round."
    }
    private var subheadline: String? {
        if isTimeout { return "Nobody emptied their hand — decided by lowest score." }
        if !didWin && vs.localHand.count <= 3 { return "So close!" }
        return nil
    }
    private var reducedMotion: Bool { settings.userSettings.reducedVisualEffects }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            if didWin && !reducedMotion {
                ConfettiView().allowsHitTesting(false)
            }
            VStack(spacing: Theme.Space.s5) {
                if didWin {
                    Circle()
                        .fill(Theme.Palette.accent)
                        .frame(width: 84, height: 84)
                        .overlay(
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.Palette.onAccent)
                        )
                        .shadow(color: reducedMotion ? .clear : Theme.Palette.accent.opacity(0.5), radius: 18)
                } else {
                    Image(systemName: "hand.thumbsdown.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                }
                Text(headline).font(.largeTitle).fontWeight(.bold).multilineTextAlignment(.center)
                if let subheadline {
                    Text(subheadline).font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: Theme.Space.s2) {
                    ForEach(vs.scoreboard) { row in
                        HStack {
                            Text(row.displayName)
                            if row.displayName == winningTeamName {
                                Text("WON")
                                    .font(.caption2).fontWeight(.bold)
                                    .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.Palette.accent))
                                    .foregroundStyle(Theme.Palette.onAccent)
                            }
                            Spacer()
                            Text("\(row.score)").fontWeight(.semibold).monospacedDigit()
                        }
                    }
                }
                .padding(Theme.Space.s4)
                .frame(maxWidth: 320)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.r3).fill(Theme.Palette.surface.opacity(0.4)))

                VStack(spacing: Theme.Space.s3) {
                    if !isGameOver {
                        Button { onNext() } label: {
                            Text("Next round")
                        }
                        .buttonStyle(.wpPrimary)
                        .accessibilityIdentifier("roundend-next")
                    }
                    Button { onExit() } label: {
                        Text(isGameOver ? "Back to Home" : "End game")
                    }
                    .buttonStyle(.wpSecondary)
                }
                .frame(maxWidth: 320)
            }
            .padding(Theme.Space.s6)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.r4).fill(Theme.Felt.base(.dark))
                    .shadow(color: (didWin && !reducedMotion) ? Theme.Palette.accent.opacity(0.4) : .clear, radius: 24)
            )
            .padding(Theme.Space.s5)
            .shadow(color: .black.opacity(0.2), radius: 16, y: 4)
        }
        .preferredColorScheme(.dark)
        .accessibilityAddTraits(.isModal)
    }
}

// A brief, lightweight confetti burst from the top of the screen (ux-spec.md §10 "Round
// win celebration", normal duration 1.5s). Pieces are plain shapes, not images, to stay
// fully offline with no bundled assets.
private struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = Int.random(in: 0..<Int.max)
        let xFraction: CGFloat
        let colour: Color
        let delay: Double
        let rotation: Double
    }

    @State private var fallen = false
    private let pieces: [Piece] = (0..<24).map { _ in
        Piece(
            xFraction: .random(in: 0...1),
            colour: [Theme.Palette.teamA, Theme.Palette.teamB, Color(hex: 0x2E7BFF), Color(hex: 0xFFB01F), Theme.Palette.accent]
                .randomElement()!,
            delay: .random(in: 0...0.3),
            rotation: .random(in: 0...360)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.colour)
                        .frame(width: 8, height: 12)
                        .rotationEffect(.degrees(fallen ? piece.rotation : 0))
                        .position(x: piece.xFraction * geo.size.width, y: fallen ? geo.size.height * 0.6 : -20)
                        .opacity(fallen ? 0 : 1)
                        .animation(.easeIn(duration: 1.5).delay(piece.delay), value: fallen)
                }
            }
        }
        .onAppear { fallen = true }
    }
}

import SwiftUI
import WildPairsCore

struct PauseMenuView: View {
    @ObservedObject var settings: AppSettings
    let onResume: () -> Void
    let onEndGame: () -> Void

    @State private var confirmEnd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { onResume() } label: { Label("Resume", systemImage: "play.fill") }
                }
                Section {
                    NavigationLink { RulesView() } label: { Label("Rules", systemImage: "questionmark.circle.fill") }
                    NavigationLink { SettingsView(settings: settings) } label: { Label("Settings", systemImage: "gearshape.fill") }
                }
                Section {
                    Button(role: .destructive) {
                        if settings.userSettings.confirmEndGame { confirmEnd = true } else { onEndGame() }
                    } label: {
                        Label("End game", systemImage: "xmark.circle.fill")
                    }
                    .accessibilityIdentifier("pause-end-game")
                }
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
    }
}

struct RoundEndView: View {
    let vs: GameViewState
    let onNext: () -> Void
    let onExit: () -> Void

    private var headline: String {
        switch vs.prompt {
        case .roundOver(let team): return "\(team) wins this round!"
        case .gameOver(let team):  return "\(team) wins the game!"
        default:                   return "Round over"
        }
    }
    private var isGameOver: Bool {
        if case .gameOver = vs.prompt { return true }
        return vs.phase == .gameEnded
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: Theme.Space.s5) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 56)).foregroundStyle(Theme.Palette.warning)
                Text(headline).font(.largeTitle).fontWeight(.bold).multilineTextAlignment(.center)

                VStack(spacing: Theme.Space.s2) {
                    ForEach(vs.scoreboard) { row in
                        HStack {
                            Text(row.displayName)
                            Spacer()
                            Text("\(row.score)").fontWeight(.semibold).monospacedDigit()
                        }
                    }
                }
                .padding(Theme.Space.s4)
                .frame(maxWidth: 320)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.r3).fill(Theme.Palette.surface))

                VStack(spacing: Theme.Space.s3) {
                    if !isGameOver {
                        Button { onNext() } label: {
                            Text("Next round").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("roundend-next")
                    }
                    Button { onExit() } label: {
                        Text(isGameOver ? "Back to Home" : "End game").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: 320)
            }
            .padding(Theme.Space.s6)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.r4).fill(Theme.Palette.background))
            .padding(Theme.Space.s5)
            .shadow(color: .black.opacity(0.2), radius: 16, y: 4)
        }
        .accessibilityAddTraits(.isModal)
    }
}

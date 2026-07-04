import SwiftUI
import WildPairsCore

struct HomeView: View {
    @ObservedObject var settings: AppSettings
    let onStart: (GameConfig) -> Void
    let onContinue: () -> Void

    @State private var showNewGame = false
    @Environment(\.horizontalSizeClass) private var hSize
    private var reducedMotion: Bool { settings.userSettings.reducedVisualEffects }
    private var isPad: Bool { hSize == .regular }

    var body: some View {
        NavigationStack {
            ZStack {
                TableBackground()
                VStack(spacing: Theme.Space.s5) {
                    Spacer()
                    VStack(spacing: Theme.Space.s3) {
                        wordmark
                        Text("Wild Pairs").font(.largeTitle).fontWeight(.bold)
                            .foregroundStyle(Theme.Palette.cream)
                        Text("Offline 2-v-2 team card game").font(.subheadline)
                            .foregroundStyle(Theme.Palette.cream.opacity(0.7))
                    }
                    Spacer()

                    VStack(spacing: Theme.Space.s3) {
                        if settings.hasSavedGame {
                            Button(action: onContinue) {
                                Label("Continue Game", systemImage: "play.fill")
                            }
                            .buttonStyle(.wpPrimary)
                            .accessibilityIdentifier("home-continue")
                        }
                        if settings.hasSavedGame {
                            Button { showNewGame = true } label: {
                                Label("New Game", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.wpGlassButton)
                            .accessibilityIdentifier("home-new-game")
                        } else {
                            Button { showNewGame = true } label: {
                                Label("New Game", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.wpPrimary)
                            .accessibilityIdentifier("home-new-game")
                        }

                        // iPad: the utility trio shares one row inside a wider column, so the
                        // menu fills the canvas instead of reading as a stretched phone list
                        // (design-plan.md §3.6).
                        if isPad {
                            HStack(spacing: Theme.Space.s3) { utilityButtons }
                        } else {
                            utilityButtons
                        }
                    }
                    .frame(maxWidth: isPad ? 560 : 360)
                    .padding(.horizontal, Theme.Space.s4)
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showNewGame) {
                NewGameFlowView(stackingEnabled: settings.userSettings.stackingEnabled) { config in
                    showNewGame = false
                    onStart(config)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var utilityButtons: some View {
        NavigationLink { RulesView() } label: {
            Label("Rules", systemImage: "questionmark.circle.fill")
        }.buttonStyle(.wpGlassButton)

        NavigationLink { StatisticsView(settings: settings) } label: {
            Label("Statistics", systemImage: "chart.bar.fill")
        }.buttonStyle(.wpGlassButton)

        NavigationLink { SettingsView(settings: settings) } label: {
            Label("Settings", systemImage: "gearshape.fill")
        }.buttonStyle(.wpGlassButton)
        .accessibilityIdentifier("home-settings")
    }

    /// Branded wordmark monogram built from the four bespoke suit symbols (A11) — no SF
    /// Symbol logo placeholder.
    private var wordmark: some View {
        HStack(spacing: Theme.Space.s3) {
            ForEach(CardColour.allCases, id: \.self) { colour in
                SuitSymbol(colour: colour, lineWidth: 2.5)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(colour.highlightColor(.dark))
                    .shadow(color: reducedMotion ? .clear : Theme.Element.scene(for: colour).glow.opacity(0.8),
                            radius: 8)
            }
        }
        .padding(.horizontal, Theme.Space.s5).padding(.vertical, Theme.Space.s4)
        .wpGlassCapsule()
        // Purely decorative — the "Wild Pairs" text immediately below already names the
        // app, so VoiceOver should skip these four shapes rather than read them individually.
        .accessibilityHidden(true)
    }
}

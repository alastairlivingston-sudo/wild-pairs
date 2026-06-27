import SwiftUI
import WildPairsCore

struct HomeView: View {
    @ObservedObject var settings: AppSettings
    let onStart: (GameConfig) -> Void
    let onContinue: () -> Void

    @State private var showNewGame = false
    private var reducedMotion: Bool { settings.userSettings.reducedVisualEffects }

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
                            .buttonStyle(.wpSecondary)
                            .accessibilityIdentifier("home-new-game")
                        } else {
                            Button { showNewGame = true } label: {
                                Label("New Game", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.wpPrimary)
                            .accessibilityIdentifier("home-new-game")
                        }

                        NavigationLink { RulesView() } label: {
                            Label("Rules", systemImage: "questionmark.circle.fill")
                        }.buttonStyle(.wpSecondary)

                        NavigationLink { StatisticsView(settings: settings) } label: {
                            Label("Statistics", systemImage: "chart.bar.fill")
                        }.buttonStyle(.wpSecondary)

                        NavigationLink { SettingsView(settings: settings) } label: {
                            Label("Settings", systemImage: "gearshape.fill")
                        }.buttonStyle(.wpSecondary)
                        .accessibilityIdentifier("home-settings")
                    }
                    .frame(maxWidth: 360)
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

    /// Branded wordmark monogram built from the four bespoke suit symbols (A11) — no SF
    /// Symbol logo placeholder.
    private var wordmark: some View {
        HStack(spacing: Theme.Space.s3) {
            ForEach(CardColour.allCases, id: \.self) { colour in
                SuitSymbol(colour: colour, lineWidth: 2.5)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(colour.fillColor(.dark))
            }
        }
        .padding(Theme.Space.s4)
        .background(
            Circle().fill(Theme.Palette.surface.opacity(0.5)).frame(width: 110, height: 110)
                .shadow(color: reducedMotion ? .clear : Theme.Palette.accent.opacity(0.35), radius: 26)
        )
        // Purely decorative — the "Wild Pairs" text immediately below already names the
        // app, so VoiceOver should skip these four shapes rather than read them individually.
        .accessibilityHidden(true)
    }
}

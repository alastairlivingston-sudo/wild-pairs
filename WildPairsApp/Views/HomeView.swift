import SwiftUI
import WildPairsCore

struct HomeView: View {
    @ObservedObject var settings: AppSettings
    let onStart: (GameConfig) -> Void
    let onContinue: () -> Void

    @State private var showNewGame = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Space.s5) {
                Spacer()
                VStack(spacing: Theme.Space.s2) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 56)).foregroundStyle(Theme.Palette.accent)
                    Text("Wild Pairs").font(.largeTitle).fontWeight(.bold)
                    Text("Offline 2-v-2 team card game").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()

                VStack(spacing: Theme.Space.s3) {
                    if settings.hasSavedGame {
                        Button(action: onContinue) {
                            Label("Continue Game", systemImage: "play.fill").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("home-continue")
                    }
                    if settings.hasSavedGame {
                        Button { showNewGame = true } label: {
                            Label("New Game", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("home-new-game")
                    } else {
                        Button { showNewGame = true } label: {
                            Label("New Game", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("home-new-game")
                    }

                    NavigationLink { RulesView() } label: {
                        Label("Rules", systemImage: "questionmark.circle.fill").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)

                    NavigationLink { StatisticsView(settings: settings) } label: {
                        Label("Statistics", systemImage: "chart.bar.fill").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)

                    NavigationLink { SettingsView(settings: settings) } label: {
                        Label("Settings", systemImage: "gearshape.fill").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                }
                .frame(maxWidth: 360)
                .padding(.horizontal, Theme.Space.s4)
                Spacer()
            }
            .navigationDestination(isPresented: $showNewGame) {
                NewGameFlowView { config in
                    showNewGame = false
                    onStart(config)
                }
            }
        }
    }
}

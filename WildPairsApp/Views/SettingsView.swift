import SwiftUI
import WildPairsCore

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var confirmResetStats = false
    @State private var confirmResetAll = false

    private var s: Binding<UserSettings> { $settings.userSettings }

    var body: some View {
        ZStack {
            TableBackground()
            Form {
                Section("Gameplay") {
                    Picker("Animation speed", selection: s.animationSpeed) {
                        Text("Normal").tag(AnimationSpeed.normal)
                        Text("Fast").tag(AnimationSpeed.fast)
                        Text("Off").tag(AnimationSpeed.off)
                    }
                    Toggle("Confirm end game", isOn: s.confirmEndGame)
                    Toggle("Draw stacking", isOn: s.stackingEnabled)
                        .accessibilityIdentifier("settings-stacking-toggle")
                        .accessibilityHint("When on, a Draw Two or Draw Four can be answered with another instead of drawing.")
                }
                .listRowBackground(Color.black.opacity(0.25))

                Section("Accessibility") {
                    Toggle("Haptics", isOn: s.hapticsEnabled)
                    Toggle("Sound effects", isOn: s.soundEnabled)
                        .accessibilityIdentifier("settings-sound-toggle")
                    Toggle("Reduced visual effects", isOn: s.reducedVisualEffects)
                    Toggle("Colour-blind mode", isOn: s.colourBlindMode)
                        .accessibilityIdentifier("settings-colourblind-toggle")
                    if settings.userSettings.colourBlindMode {
                        Toggle("Pattern fills", isOn: s.patternFills)
                            .accessibilityIdentifier("settings-patternfills-toggle")
                    }
                    Toggle("Large cards", isOn: s.largeCards)
                }
                .listRowBackground(Color.black.opacity(0.25))

                Section {
                    Button("Reset statistics") { confirmResetStats = true }
                    Button("Reset all local data", role: .destructive) { confirmResetAll = true }
                } header: {
                    Text("Data")
                } footer: {
                    Text("All data is stored only on this device. Nothing is sent anywhere.")
                }
                .listRowBackground(Color.black.opacity(0.25))
            }
            .scrollContentBackground(.hidden)
            .tint(Theme.Palette.accent)
            // iPad: a centred reading column instead of full-width rows with a huge gap
            // between each label and its control (ux-spec §7). No effect on iPhone.
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Settings")
        .preferredColorScheme(.dark)
        .alert("Reset statistics?", isPresented: $confirmResetStats) {
            Button("Reset", role: .destructive) { settings.resetStats() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Reset all local data?", isPresented: $confirmResetAll) {
            Button("Reset everything", role: .destructive) { settings.resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes your saved game, statistics, and preferences. This cannot be undone.")
        }
    }
}

struct StatisticsView: View {
    @ObservedObject var settings: AppSettings
    private var stats: GameStats { settings.stats }

    var body: some View {
        ZStack {
            TableBackground()
            Form {
                Section("Overview") {
                    row("Games played", "\(stats.totalGamesPlayed)")
                    row("Wins", "\(stats.totalWins)")
                    row("Win rate", percent(stats.totalWins, stats.totalGamesPlayed))
                    row("Average turns / round", String(format: "%.0f", stats.averageTurnsPerRound))
                    row("Current win streak", "\(stats.currentWinStreak)")
                    row("Best win streak", "\(stats.bestWinStreak)")
                }
                .listRowBackground(Color.black.opacity(0.25))
                Section("By difficulty") {
                    ForEach(Difficulty.allCases, id: \.self) { d in
                        let ds = stats.byDifficulty[d.rawValue] ?? DifficultyStats()
                        row(d.rawValue.capitalized, "\(ds.wins)/\(ds.gamesPlayed)  (\(percent(ds.wins, ds.gamesPlayed)))")
                    }
                }
                .listRowBackground(Color.black.opacity(0.25))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Statistics")
        .preferredColorScheme(.dark)
        .overlay {
            if stats.totalGamesPlayed == 0 {
                ContentUnavailableView("No games yet", systemImage: "chart.bar",
                                       description: Text("Play a round to start tracking your stats."))
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(.secondary).monospacedDigit() }
    }
    private func percent(_ n: Int, _ d: Int) -> String {
        d == 0 ? "—" : "\(Int((Double(n) / Double(d) * 100).rounded()))%"
    }
}

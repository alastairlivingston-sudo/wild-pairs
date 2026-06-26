import SwiftUI
import WildPairsCore

// Single configuration screen: mode, difficulty, and card set. Builds a GameConfig with the
// canonical seat→team mapping and hands it back to start the game.

struct NewGameFlowView: View {
    let onStart: (GameConfig) -> Void

    @State private var mode: GameMode = .standardTeams
    @State private var difficulty: Difficulty = .medium
    @State private var cardSet: CardSet = .standard

    var body: some View {
        ZStack {
            TableBackground()
            Form {
                Section("Mode") {
                    Picker("Mode", selection: $mode) {
                        Text("Standard Teams").tag(GameMode.standardTeams)
                        Text("All-Wild Teams").tag(GameMode.allWild)
                        Text("Side-to-Side Teams").tag(GameMode.sideToSide)
                    }
                    .pickerStyle(.inline)
                    Text(modeBlurb).font(.footnote).foregroundStyle(.secondary)
                }
                .listRowBackground(Color.black.opacity(0.25))
                Section("Difficulty") {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.black.opacity(0.25))
                Section("Card set") {
                    Picker("Card set", selection: $cardSet) {
                        Text("Beginner").tag(CardSet.beginner)
                        Text("Standard").tag(CardSet.standard)
                        Text("Advanced").tag(CardSet.advanced)
                    }
                    .pickerStyle(.segmented)
                    Text(cardSetBlurb).font(.footnote).foregroundStyle(.secondary)
                }
                .listRowBackground(Color.black.opacity(0.25))
                Section {
                    Button {
                        onStart(.standardFourPlayer(mode: mode, difficulty: difficulty, cardSet: cardSet))
                    } label: {
                        Text("Start Game")
                    }
                    .buttonStyle(.wpPrimary)
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("newgame-start")
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var modeBlurb: String {
        switch mode {
        case .standardTeams: return "Match by colour, number, or action type."
        case .allWild:       return "Every card is playable every turn — pure chaos."
        case .sideToSide:    return "Standard rules plus a team card-pass at round start."
        }
    }
    private var cardSetBlurb: String {
        switch cardSet {
        case .beginner: return "Numbers, Skip, Reverse, Change Colour."
        case .standard: return "Beginner plus Draw Two and Draw Four."
        case .advanced: return "Everything, including Forced Swap, Skip Two, and Team Play."
        }
    }
}

extension GameConfig {
    /// Canonical 1-human + 3-AI table (seats 0,2 = Team A; 1,3 = Team B).
    static func standardFourPlayer(
        mode: GameMode, difficulty: Difficulty, cardSet: CardSet, seed: UInt64? = nil
    ) -> GameConfig {
        var profile: RuleProfile
        switch mode {
        case .standardTeams: profile = .standardTeams()
        case .allWild:       profile = .allWild()
        case .sideToSide:    profile = .sideToSide()
        }
        profile.cardSet = cardSet
        return GameConfig(
            mode: mode,
            players: [
                PlayerConfig(name: "You", role: .human, teamID: .teamA, difficulty: difficulty, seatPosition: 0),
                PlayerConfig(name: "Left Opponent", role: .ai, teamID: .teamB, difficulty: difficulty, seatPosition: 1),
                PlayerConfig(name: "Partner", role: .ai, teamID: .teamA, difficulty: difficulty, seatPosition: 2),
                PlayerConfig(name: "Right Opponent", role: .ai, teamID: .teamB, difficulty: difficulty, seatPosition: 3)
            ],
            ruleProfile: profile,
            seed: seed
        )
    }
}

import SwiftUI
import WildPairsCore

// Single configuration screen: mode, difficulty, and card set. Builds a GameConfig with the
// canonical seat→team mapping and hands it back to start the game.

struct NewGameFlowView: View {
    /// Settings-screen house-rule toggle (Phase 11 F) — stacking is on by default at the
    /// `RuleProfile` level; this lets a player opt out before starting a new game.
    var stackingEnabled: Bool = true
    let onStart: (GameConfig) -> Void

    @State private var mode: GameMode = .standardTeams
    @State private var difficulty: Difficulty = .medium
    @State private var cardSet: CardSet = .standard

    var body: some View {
        ZStack {
            TableBackground()
            // No ScrollView (Phase 11 C): the three segmented controls + Start button always
            // fit a portrait screen, so a fixed VStack with the button pinned to the bottom
            // reads as a complete, intentional layout instead of leaving dead space below an
            // accidentally-short scroll view.
            VStack(alignment: .leading, spacing: 0) {
                Text("New game")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, Theme.Space.s5)
                    .padding(.bottom, Theme.Space.s5)

                VStack(alignment: .leading, spacing: Theme.Space.s4) {
                    NeonSegmented(title: "Mode", options: [
                        (GameMode.standardTeams, "Standard Teams"),
                        (GameMode.allWild, "All-Wild Teams"),
                        (GameMode.sideToSide, "Side-to-Side Teams")
                    ], selection: $mode, blurb: modeBlurb)

                    NeonSegmented(title: "Difficulty", options: Difficulty.allCases.map {
                        ($0, $0.rawValue.capitalized)
                    }, selection: $difficulty, blurb: difficultyBlurb)

                    NeonSegmented(title: "Card set", options: [
                        (CardSet.beginner, "Beginner"),
                        (CardSet.standard, "Standard"),
                        (CardSet.advanced, "Advanced")
                    ], selection: $cardSet, blurb: cardSetBlurb)
                }

                Spacer(minLength: Theme.Space.s5)

                Button {
                    onStart(.standardFourPlayer(mode: mode, difficulty: difficulty, cardSet: cardSet,
                                                 stackingEnabled: stackingEnabled))
                } label: {
                    Text("Start Game")
                }
                .buttonStyle(.wpPrimary)
                .accessibilityIdentifier("newgame-start")
                .padding(.bottom, Theme.Space.s4)
            }
            .padding(.horizontal, Theme.Space.s4)
            // iPad: keep the controls from stretching edge-to-edge at regular width.
            .frame(maxWidth: 480)
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
    private var difficultyBlurb: String {
        switch difficulty {
        case .easy:   return "Random valid move — relaxed pace."
        case .medium: return "Prefers action cards, basic team awareness."
        case .hard:   return "Scores every move across multiple factors."
        case .expert: return "Simulates ahead and plays for the team."
        case .master: return "Same strategy as Expert, highest score multiplier."
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
        mode: GameMode, difficulty: Difficulty, cardSet: CardSet, stackingEnabled: Bool = true,
        seed: UInt64? = nil
    ) -> GameConfig {
        var profile: RuleProfile
        switch mode {
        case .standardTeams: profile = .standardTeams()
        case .allWild:       profile = .allWild()
        case .sideToSide:    profile = .sideToSide()
        }
        profile.cardSet = cardSet
        profile.stackDrawCards = stackingEnabled
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

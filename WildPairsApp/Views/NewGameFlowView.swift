import SwiftUI
import WildPairsCore

// Single configuration screen: players (solo vs two-player pass-and-play), mode, difficulty,
// and card set. Builds a GameConfig with the canonical seat→team mapping and hands it back to
// start the game. Two-player mode adds name entry with one-tap saved-name suggestions.

/// Who is at the table: one human + 3 AI, or two humans partnered (seats 0+2) vs 2 AI.
enum PlayerSetup: Hashable {
    case solo
    case twoPlayer
}

struct NewGameFlowView: View {
    @ObservedObject var settings: AppSettings
    let onStart: (GameConfig) -> Void

    @State private var playerSetup: PlayerSetup = .solo
    @State private var mode: GameMode = .standardTeams
    @State private var difficulty: Difficulty = .medium
    @State private var cardSet: CardSet = .standard
    @State private var playerOneName: String = ""
    @State private var playerTwoName: String = ""
    @FocusState private var focusedNameField: Int?

    var body: some View {
        ZStack {
            TableBackground()
            // The Start button lives outside the ScrollView so it's always visible without
            // scrolling at normal Dynamic Type sizes (Phase 11 C: no dead space below it) —
            // but the controls above it still scroll, so at huge accessibility text sizes
            // (AX3+) nothing becomes unreachable (regression caught by
            // testDynamicTypeAX3LayoutSurvives).
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ScrollView {
                        // Centre the controls in the scroll viewport so the form isn't top-loaded
                        // with a void above the bottom-pinned Start button. At large Dynamic Type
                        // the controls exceed the viewport and the spacers collapse, so it scrolls
                        // and the Start button stays reachable (testDynamicTypeAX3LayoutSurvives).
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            controls
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: geo.size.height - 96)
                    }
                    startButton
                }
                // iPad: keep the controls from stretching edge-to-edge at regular width.
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s4) {
            Text("New game")
                .font(.largeTitle.weight(.bold))
                .padding(.top, Theme.Space.s5)
                .padding(.bottom, Theme.Space.s1)

            NeonSegmented(title: "Players", options: [
                (PlayerSetup.solo, "Solo"),
                (PlayerSetup.twoPlayer, "Two Players")
            ], selection: $playerSetup, blurb: playerSetupBlurb)

            if playerSetup == .twoPlayer {
                nameEntry
            }

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
        .padding(.horizontal, Theme.Space.s4)
    }

    // MARK: Two-player name entry

    private var nameEntry: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            nameField("Player 1 (you)", text: $playerOneName, field: 1, identifier: "newgame-name-1")
            nameField("Player 2 (partner)", text: $playerTwoName, field: 2, identifier: "newgame-name-2")
            if !suggestedNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.s2) {
                        ForEach(suggestedNames, id: \.self) { name in
                            Button { fillSuggestion(name) } label: {
                                Text(name)
                                    .font(.caption).fontWeight(.semibold)
                                    .padding(.horizontal, Theme.Space.s3)
                                    .padding(.vertical, Theme.Space.s1)
                                    .wpGlassCapsule()
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Use saved name \(name)")
                        }
                    }
                }
                .accessibilityIdentifier("newgame-name-suggestions")
            }
        }
    }

    private func nameField(_ label: String, text: Binding<String>, field: Int,
                           identifier: String) -> some View {
        TextField(label, text: text, prompt: Text(label).foregroundStyle(.secondary))
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($focusedNameField, equals: field)
            .padding(Theme.Space.s3)
            .wpGlass(cornerRadius: Theme.Radius.r3)
            .foregroundStyle(.white)
            .accessibilityIdentifier(identifier)
    }

    /// Saved names not already used by either field.
    private var suggestedNames: [String] {
        settings.userSettings.savedPlayerNames.filter { saved in
            saved.caseInsensitiveCompare(playerOneName.trimmingCharacters(in: .whitespaces)) != .orderedSame
                && saved.caseInsensitiveCompare(playerTwoName.trimmingCharacters(in: .whitespaces)) != .orderedSame
        }
    }

    /// A tapped suggestion fills the focused field, else the first empty one.
    private func fillSuggestion(_ name: String) {
        switch focusedNameField {
        case 1: playerOneName = name
        case 2: playerTwoName = name
        default:
            if playerOneName.trimmingCharacters(in: .whitespaces).isEmpty {
                playerOneName = name
            } else {
                playerTwoName = name
            }
        }
    }

    private var resolvedNames: (String, String) {
        let one = playerOneName.trimmingCharacters(in: .whitespaces)
        let two = playerTwoName.trimmingCharacters(in: .whitespaces)
        return (one.isEmpty ? "Player 1" : one, two.isEmpty ? "Player 2" : two)
    }

    // MARK: Start

    private var startButton: some View {
        Button {
            let stacking = settings.userSettings.stackingEnabled
            let challenge = settings.userSettings.drawFourChallengeEnabled
            switch playerSetup {
            case .solo:
                onStart(.standardFourPlayer(mode: mode, difficulty: difficulty, cardSet: cardSet,
                                            stackingEnabled: stacking,
                                            drawFourChallengeEnabled: challenge))
            case .twoPlayer:
                let (one, two) = resolvedNames
                settings.userSettings.rememberPlayerNames([one, two])
                onStart(.twoPlayerPartners(mode: mode, difficulty: difficulty, cardSet: cardSet,
                                           stackingEnabled: stacking,
                                           drawFourChallengeEnabled: challenge,
                                           playerOneName: one, playerTwoName: two))
            }
        } label: {
            Text("Start Game")
        }
        .buttonStyle(.wpPrimary)
        .accessibilityIdentifier("newgame-start")
        .padding(.horizontal, Theme.Space.s4)
        .padding(.bottom, Theme.Space.s4)
    }

    // MARK: Blurbs

    private var playerSetupBlurb: String {
        switch playerSetup {
        case .solo:      return "You and an AI partner vs. two AI opponents."
        case .twoPlayer: return "Pass-and-play: you and a friend partner up vs. two AI opponents."
        }
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
        drawFourChallengeEnabled: Bool = false, seed: UInt64? = nil
    ) -> GameConfig {
        var profile = ruleProfile(for: mode)
        profile.cardSet = cardSet
        profile.stackDrawCards = stackingEnabled
        profile.drawFourChallengeable = drawFourChallengeEnabled
        return GameConfig(
            mode: mode,
            players: fourPlayerSeats(mode: mode, humanName: "You", partnerName: "Partner",
                                     partnerRole: .ai, difficulty: difficulty),
            ruleProfile: profile,
            seed: seed
        )
    }

    /// Two-player pass-and-play table (Phase 15): both humans on Team A, two AI opponents on
    /// Team B. Seat layout follows `fourPlayerSeats` for the mode.
    static func twoPlayerPartners(
        mode: GameMode, difficulty: Difficulty, cardSet: CardSet, stackingEnabled: Bool = true,
        drawFourChallengeEnabled: Bool = false,
        playerOneName: String, playerTwoName: String, seed: UInt64? = nil
    ) -> GameConfig {
        var profile = ruleProfile(for: mode)
        profile.cardSet = cardSet
        profile.stackDrawCards = stackingEnabled
        profile.drawFourChallengeable = drawFourChallengeEnabled
        return GameConfig(
            mode: mode,
            players: fourPlayerSeats(mode: mode, humanName: playerOneName, partnerName: playerTwoName,
                                     partnerRole: .human, difficulty: difficulty),
            ruleProfile: profile,
            seed: seed
        )
    }

    /// Seat order for a 2v2 table. Standard and All-Wild alternate teams (You, Opponent,
    /// Partner, Opponent — an opponent plays after you). **Side-to-Side seats your partner
    /// immediately after you** (You, Partner, Opponent, Opponent) so your partner takes the very
    /// next turn (Phase 17 B3, the new default for that mode). The role-based table layout
    /// (`GameViewState`) keeps you at the bottom, your partner across the top, and the two
    /// opponents on the sides regardless of these seat indices.
    private static func fourPlayerSeats(
        mode: GameMode, humanName: String, partnerName: String,
        partnerRole: PlayerRole, difficulty: Difficulty
    ) -> [PlayerConfig] {
        let partnerSeat = mode == .sideToSide ? 1 : 2
        let leftOppSeat = mode == .sideToSide ? 2 : 1
        return [
            PlayerConfig(name: humanName, role: .human, teamID: .teamA, difficulty: difficulty, seatPosition: 0),
            PlayerConfig(name: partnerName, role: partnerRole, teamID: .teamA, difficulty: difficulty, seatPosition: partnerSeat),
            PlayerConfig(name: "Left Opponent", role: .ai, teamID: .teamB, difficulty: difficulty, seatPosition: leftOppSeat),
            PlayerConfig(name: "Right Opponent", role: .ai, teamID: .teamB, difficulty: difficulty, seatPosition: 3)
        ].sorted { $0.seatPosition < $1.seatPosition }
    }

    private static func ruleProfile(for mode: GameMode) -> RuleProfile {
        switch mode {
        case .standardTeams: return .standardTeams()
        case .allWild:       return .allWild()
        case .sideToSide:    return .sideToSide()
        }
    }
}

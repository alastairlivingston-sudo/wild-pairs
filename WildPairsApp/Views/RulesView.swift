import SwiftUI
import WildPairsCore

// Static rules reference. Copy mirrors docs/game-rules.md; card glossary is generated from
// the card catalogue so it never drifts from the engine's card set.

struct RulesView: View {
    var body: some View {
        ZStack {
            TableBackground()
            List {
                Section("How to play") {
                    bullet("Match the top card by colour, number, or action type — or play a wild.")
                    bullet("Can't match? Draw a card. If it's playable you may play it right away.")
                    bullet("Call Solo! the moment you're down to one card, or risk a 2-card penalty.")
                    bullet("You and your partner are a team. Both of you must empty your hands to win the round.")
                }
                .listRowBackground(Color.black.opacity(0.25))
                Section("Card glossary") {
                    ForEach(GlossaryEntry.all) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name).font(.headline)
                            Text(entry.text).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listRowBackground(Color.black.opacity(0.25))
                Section("Modes") {
                    bullet("Standard Teams — match by colour, number, or action.")
                    bullet("All-Wild Teams — every card is playable every turn; pure action chaos.")
                    bullet("Side-to-Side Teams — Standard rules plus an optional team card-pass at round start.")
                }
                .listRowBackground(Color.black.opacity(0.25))
                Section("Difficulty") {
                    bullet("Easy — random valid plays.")
                    bullet("Medium — prefers action cards, basic team sense.")
                    bullet("Hard — scores every move across multiple factors.")
                    bullet("Expert — looks ahead and plays the highest-value move.")
                }
                .listRowBackground(Color.black.opacity(0.25))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Rules")
        .preferredColorScheme(.dark)
    }

    private func bullet(_ text: String) -> some View {
        Label(text, systemImage: "circle.fill")
            .labelStyle(BulletLabelStyle())
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s2) {
            Image(systemName: "circle.fill").font(.system(size: 5)).foregroundStyle(.secondary)
            configuration.title
        }
    }
}

struct GlossaryEntry: Identifiable {
    let id = UUID()
    let name: String
    let text: String

    static let all: [GlossaryEntry] = [
        .init(name: "Number (0–9)", text: "Play if the colour or number matches. No special effect."),
        .init(name: "Skip", text: "The next player loses their turn."),
        .init(name: "Reverse", text: "Turn direction flips."),
        .init(name: "Change Colour", text: "Play on anything. You choose the new colour."),
        .init(name: "Draw Two", text: "The next player draws 2 and loses their turn."),
        .init(name: "Draw Four", text: "Play only with no other match. Choose a colour; next player draws 4 and is skipped."),
        .init(name: "Discard All", text: "Choose a colour and discard every card of it from your hand."),
        .init(name: "Targeted Draw", text: "Choose any opponent; they draw 2. Their turn is not skipped."),
        .init(name: "Forced Swap", text: "Choose any player; swap entire hands with them."),
        .init(name: "Skip Two", text: "The next two players each lose their turn."),
        .init(name: "Team Play", text: "You and your partner each draw 1 card.")
    ]
}

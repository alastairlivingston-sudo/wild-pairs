import SwiftUI
import WildPairsCore

// Design-review card gallery, reachable only via the `--uitest-cardgallery` launch argument.
// Renders every card face the deck can produce (all types × colours, wilds, resolved-wild
// tints, the back) at hand and table sizes so a single screenshot judges the whole deck.

struct CardGalleryView: View {
    private let colours = CardColour.allCases
    private let colouredTypes: [CardType] = [
        .number(7), .number(0), .skip, .skipTwo, .reverse, .drawTwo,
        .targetedDraw, .forcedSwap, .teamPlay, .discardColour
    ]
    private let wildTypes: [CardType] = [.changeColour, .drawFour, .discardAll]

    private let handSize = CGSize(width: 88, height: 132)
    private let focusSize = CGSize(width: 112, height: 168)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s4) {
                section("Numbers and actions — one row per colour") {
                    ForEach(colours, id: \.self) { colour in
                        HStack(spacing: Theme.Space.s2) {
                            ForEach(Array(colouredTypes.enumerated()), id: \.offset) { _, type in
                                CardView(card: Card(type: type, colour: colour), size: handSize)
                            }
                        }
                    }
                }
                section("Wilds — unresolved, then resolved per colour") {
                    HStack(spacing: Theme.Space.s2) {
                        ForEach(Array(wildTypes.enumerated()), id: \.offset) { _, type in
                            CardView(card: Card(type: type, colour: nil), size: focusSize)
                        }
                        ForEach(colours, id: \.self) { colour in
                            CardView(card: Card(type: .drawFour, colour: nil),
                                     size: focusSize, wildTint: colour)
                        }
                    }
                }
                section("Table centre — normal, must-draw, forced pickup") {
                    HStack(alignment: .top, spacing: Theme.Space.s6) {
                        tableCentre(mustDraw: false, forced: false, pending: nil)
                        tableCentre(mustDraw: true, forced: false, pending: nil)
                        tableCentre(mustDraw: true, forced: true, pending: 6)
                    }
                    .padding(.top, Theme.Space.s5)
                }
                section("States — playable glow, back, colour-blind plate + pattern") {
                    HStack(spacing: Theme.Space.s2) {
                        CardView(card: Card(type: .number(5), colour: .crimson),
                                 size: focusSize, isPlayable: true)
                        CardBackView(size: focusSize)
                        ForEach(colours, id: \.self) { colour in
                            CardView(card: Card(type: .number(5), colour: colour),
                                     size: focusSize, showColourName: true, showPattern: true)
                        }
                    }
                }
            }
            .padding(Theme.Space.s5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(TableBackground())
        .preferredColorScheme(.dark)
    }

    private func tableCentre(mustDraw: Bool, forced: Bool, pending: Int?) -> some View {
        TableCenterView(
            topDiscard: Card(type: .drawTwo, colour: .crimson), currentColour: .crimson,
            drawPileCount: 43, pendingDrawCount: pending, turnDirection: .clockwise,
            canDraw: true, mustDraw: mustDraw, forcedPickup: forced,
            showColourName: false, cardSize: focusSize, onDraw: {}
        )
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }
}

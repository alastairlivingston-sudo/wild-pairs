import SwiftUI
import WildPairsCore

// Modal sheets for the two mid-resolution decisions: choosing a colour after a wild, and
// choosing a target after Targeted Draw / Forced Swap.

struct ColourPickerView: View {
    let onChoose: (CardColour) -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: Theme.Space.s4) {
            Text("Choose a colour").font(.title2).fontWeight(.semibold)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Space.s3) {
                ForEach(CardColour.allCases, id: \.self) { colour in
                    Button { onChoose(colour) } label: {
                        VStack(spacing: Theme.Space.s2) {
                            Image(systemName: colour.symbolName).font(.title)
                            Text(colour.displayName).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).frame(height: 88)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.r3)
                            .fill(colour.fillColor(scheme)))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(colour.displayName)
                    .accessibilityIdentifier("colour-pick-\(colour.rawValue)")
                }
            }
        }
        .padding(Theme.Space.s5)
        .presentationDetents([.height(280)])
        .interactiveDismissDisabled()
    }
}

struct TargetPickerView: View {
    let candidates: [PlayerSeatViewState]
    let onChoose: (UUID) -> Void

    var body: some View {
        VStack(spacing: Theme.Space.s4) {
            Text("Choose a player").font(.title2).fontWeight(.semibold)
            ForEach(candidates) { seat in
                Button { onChoose(seat.id) } label: {
                    HStack {
                        Text(seat.name).fontWeight(.semibold)
                        Spacer()
                        Text("\(seat.handCount) cards").foregroundStyle(.secondary)
                    }
                    .padding(Theme.Space.s4)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.r3).fill(Theme.Palette.surface))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(seat.name), \(seat.handCount) cards")
                .accessibilityIdentifier("target-pick-\(seat.seatPosition)")
            }
        }
        .padding(Theme.Space.s5)
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }
}

// The single guidance line above the hand (§ux tone of voice).
struct PromptBanner: View {
    let prompt: PromptKind

    var body: some View {
        Text(text)
            .font(.body).fontWeight(.medium)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Space.s4).padding(.vertical, Theme.Space.s2)
            .frame(maxWidth: .infinity)
            // A capsule's corner radius is height/2, so at large Dynamic Type sizes this
            // banner wraps to several lines, the capsule grows tall, and its semicircular
            // ends balloon inward and clip the text. A fixed-radius rounded rect has no
            // such failure mode regardless of how many lines the text wraps to.
            .background(RoundedRectangle(cornerRadius: Theme.Radius.r4).fill(Theme.Palette.surface))
            .accessibilityIdentifier("game-prompt")
    }

    private var text: String {
        switch prompt {
        case .yourTurn(let hint):        return hint
        case .waitingFor(let name):      return "\(name) is playing…"
        case .chooseColour:              return "Choose the new colour."
        case .chooseTarget:              return "Choose a player."
        case .mustDraw:                  return "No match — draw a card."
        case .roundOver(let team):       return "\(team) wins this round!"
        case .gameOver(let team):        return "\(team) wins the game!"
        case .paused:                    return "Paused."
        }
    }
}

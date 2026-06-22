import SwiftUI
import WildPairsCore

// A non-local player's seat: name, fanned card backs, a count badge, and status badges
// (current turn, Solo!, Out!). When the seat owes a Solo! call the local player can tap to
// catch them for a penalty.

struct PlayerZoneView: View {
    let seat: PlayerSeatViewState
    var onCatchSolo: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Space.s1) {
            HStack(spacing: Theme.Space.s2) {
                Text(seat.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(seat.isCurrentPlayer ? Theme.Palette.accent : .secondary)
                countBadge
            }

            backsFan

            statusBadges
        }
        .padding(Theme.Space.s2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .fill(Theme.Palette.surface)
                .opacity(seat.isCurrentPlayer ? 1 : 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .strokeBorder(Theme.Palette.accent, lineWidth: seat.isCurrentPlayer ? 2 : 0)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var countBadge: some View {
        Text("\(seat.handCount)")
            .font(.caption).fontWeight(.bold).monospacedDigit()
            .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
            .background(Capsule().fill(Theme.Palette.accent.opacity(0.15)))
    }

    private var backsFan: some View {
        HStack(spacing: -Theme.CardSize.opponentBack.width * 0.55) {
            ForEach(0..<min(seat.handCount, 5), id: \.self) { _ in
                CardBackView()
            }
            if seat.handCount == 0 {
                Color.clear.frame(width: Theme.CardSize.opponentBack.width,
                                  height: Theme.CardSize.opponentBack.height)
            }
        }
    }

    @ViewBuilder private var statusBadges: some View {
        if seat.hasFinishedRound {
            badge("Out!", system: "checkmark.circle.fill", tint: Theme.Palette.success)
        } else if seat.needsSoloCall {
            Button { onCatchSolo?() } label: {
                badge("Solo?", system: "exclamationmark.circle.fill", tint: Theme.Palette.warning)
            }
            .buttonStyle(.plain)
            .disabled(onCatchSolo == nil)
            .accessibilityHint(onCatchSolo == nil ? "" : "Double tap to call them out")
        }
    }

    private func badge(_ text: String, system: String, tint: Color) -> some View {
        Label(text, systemImage: system)
            .font(.caption2).fontWeight(.semibold)
            .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
            .background(Capsule().fill(tint.opacity(0.2)))
            .foregroundStyle(tint)
    }

    private var accessibilityLabel: String {
        var parts = ["\(seat.name), \(seat.handCount) cards"]
        if seat.isCurrentPlayer { parts.append("their turn") }
        if seat.hasFinishedRound { parts.append("out of the round") }
        else if seat.needsSoloCall { parts.append("has one card and has not called Solo") }
        return parts.joined(separator: ", ")
    }
}

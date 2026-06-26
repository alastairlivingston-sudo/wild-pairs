import SwiftUI

// First-launch rules explainer, shown once over the home screen. Dismissible at any time;
// the "seen" flag is persisted via UserSettings so it never reappears automatically.

struct OnboardingView: View {
    let onDismiss: () -> Void

    @State private var page = 0
    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            TableBackground()
            VStack(spacing: Theme.Space.s4) {
                HStack {
                    Spacer()
                    Button("Skip", action: onDismiss)
                        .buttonStyle(.wpGhost)
                        .accessibilityIdentifier("onboarding-skip")
                }
                .padding([.top, .horizontal], Theme.Space.s4)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        pageView(item).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(page == pages.count - 1 ? "Let's play" : "Next") {
                    if page == pages.count - 1 {
                        onDismiss()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .buttonStyle(.wpPrimary)
                .frame(maxWidth: 280)
                .padding(.bottom, Theme.Space.s5)
                .accessibilityIdentifier("onboarding-next")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func pageView(_ item: OnboardingPage) -> some View {
        VStack(spacing: Theme.Space.s4) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 64))
                .foregroundStyle(Theme.Palette.accent)
            Text(item.title).font(.title2).fontWeight(.bold).multilineTextAlignment(.center)
            Text(item.body).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Space.s5)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.body)")
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String

    static let all: [OnboardingPage] = [
        .init(
            symbol: "person.2.fill",
            title: "You and a partner vs. two opponents",
            body: "Wild Pairs is 2-v-2. You sit across from your partner — empty your hand, or be the team whose partner does, before the other team."
        ),
        .init(
            symbol: "rectangle.stack.fill",
            title: "Match colour, number, or action",
            body: "Play a card that matches the discard pile's colour, number, or action type — or play a wild card, which matches anything."
        ),
        .init(
            symbol: "exclamationmark.circle.fill",
            title: "Call \"Solo!\" at one card",
            body: "Drop to one card and you must call Solo! immediately. Forget, and an opponent who catches you can make you draw two."
        ),
        .init(
            symbol: "eye.fill",
            title: "Your partner's hand is open",
            body: "Teamwork is the point — you can always see your partner's cards, and your partner can see yours. Opponents' hands stay hidden."
        )
    ]
}

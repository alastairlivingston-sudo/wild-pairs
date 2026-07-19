# Source anchors and diagnosis

Line numbers below are relative to the supplied Phase 19 snapshot. Claude Code must reopen the live repository before editing.

## 1. Standard table state was split across top, centre, and hand regions

`WildPairsApp/Views/GameTableView.swift:118–155`:

```swift
ZStack {
    TableBackground(element: vs.currentColour).ignoresSafeArea()

    VStack(spacing: 0) {
        scoreBar.padding(.top, spacing)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if isPad { Spacer(minLength: spacing) }
                VStack(spacing: spacing) {
                    partnerZone(maxWidth: partnerMaxWidth, seatBackSize: seatBackSize,
                                openHandCardSize: partnerCardSize)
                    zoneGap(isPad: isPad, compact: isLandscape)
                    tableStateRail(compact: isLandscape)
                    opponentCenterRow(spacing: spacing, seatBackSize: seatBackSize,
                                      centerSize: centerSize, sideWidth: resolvedSide, spread: isPad)
                    zoneGap(isPad: isPad, compact: isLandscape)

                    PromptBanner(prompt: vs.prompt, tint: elementGlow)
                        .padding(.horizontal, Theme.Space.s4)
                    if let moveRemaining = vm.moveTimeRemaining, moveRemaining <= vm.moveTimeLimit {
                        MoveTimerBar(remaining: moveRemaining, total: vm.moveTimeLimit)
                            .padding(.horizontal, Theme.Space.s4)
                    }
                    bottomControls
                    HandView(hand: vs.localHand, cardSize: handSize,
                             showColourName: showColourName, showPattern: showPattern,
                             reducedMotion: motionDisabled, onPlay: vm.play)
                }
            }
        }
    }
}
```

The approved change consolidates round time, scores, compact turn/direction, move time, and pause in a fixed top HUD.

## 2. AX card sizing checked only the persisted preference

`WildPairsApp/Views/GameTableView.swift:54–59`:

```swift
private var handCardSize: CGSize {
    let large = settings.userSettings.largeCards
    if hSize == .regular { return large ? Theme.CardSize.padHandLarge : Theme.CardSize.padHand }
    return large ? Theme.CardSize.regularHand : Theme.CardSize.compactHand
}
```

The two-human table separately hard-coded compact hand cards. The approved presentation derives effective large cards from the preference or `.accessibility3` and above, without writing back to settings.

## 3. The move timer occupied hand space

`WildPairsApp/Views/DecisionViews.swift:310–330`:

```swift
struct MoveTimerBar: View {
    let remaining: TimeInterval
    let total: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Int(remaining.rounded()))s to play")
            ProgressView(value: progress)
        }
        .accessibilityIdentifier("game-move-timer")
    }
}
```

The identifier and exact countdown move into the fixed reserved HUD slot.

## 4. Persistent direction text was small and duplicated below the piles

`WildPairsApp/Views/TableCenterView.swift:290–304`:

```swift
Text(turnDirection == .clockwise ? "CLOCKWISE" : "COUNTER-CLOCKWISE")
    .font(.system(size: 9, weight: .black, design: .rounded))
```

`Theme.Table.directionOrbitRestOpacity` was `0.24`. The approved change moves compact full direction text to the top HUD, retains central arrow geometry, and raises the resting orbit to `0.42`.

## 5. The existing background already had authoritative colour but deliberately stayed still

`WildPairsApp/Theme/TableBackground.swift:20–40`:

```swift
ZStack {
    Rectangle().fill(reducedVisualEffects ? Theme.Element.neutral.base : palette.base)

    if reducedVisualEffects {
        Rectangle().fill(
            RadialGradient(
                colors: [Theme.Felt.baseDarkHighlight.opacity(0.78), Theme.Element.neutral.base],
                center: .center,
                startRadius: 0,
                endRadius: radius * 0.78
            )
        )
    } else {
        // The table itself stays still. Gameplay motion belongs to cards, turns, and
        // scoring; a moving background competed with those events in real play.
        atmosphere(radius: radius)

        ElementSurfacePattern(element: element)
            .opacity(0.030)
    }
}
```

The user explicitly superseded that presentation decision with a subtle direction pulse and clearer element surface. Direction remains sourced from `GameViewState.turnDirection`; no rule is reimplemented.

## 6. Both gameplay tables already passed the real active element

`GameTableView.swift` and `PassAndPlayTableView.swift` each used:

```swift
TableBackground(element: vs.currentColour).ignoresSafeArea()
```

They now also pass existing direction, phase/animation state, and the persisted appearance style.

## 7. Settings had no appearance choice

`WildPairsApp/Views/SettingsView.swift:11–14`:

```swift
var body: some View {
    ZStack {
        TableBackground()
        Form {
```

The approved change adds one built-in background picker and a live preview.

## 8. UserSettings already supported backward-compatible missing-key defaults

`WildPairsCore/Persistence/UserSettings.swift:88–101`:

```swift
public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    animationSpeed = try c.decodeIfPresent(AnimationSpeed.self, forKey: .animationSpeed) ?? .normal
    confirmEndGame = try c.decodeIfPresent(Bool.self, forKey: .confirmEndGame) ?? true
    hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
    soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
    reducedVisualEffects = try c.decodeIfPresent(Bool.self, forKey: .reducedVisualEffects) ?? false
    colourBlindMode = try c.decodeIfPresent(Bool.self, forKey: .colourBlindMode) ?? false
    patternFills = try c.decodeIfPresent(Bool.self, forKey: .patternFills) ?? false
    largeCards = try c.decodeIfPresent(Bool.self, forKey: .largeCards) ?? false
    hasSeenOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
    stackingEnabled = try c.decodeIfPresent(Bool.self, forKey: .stackingEnabled) ?? true
    drawFourChallengeEnabled = try c.decodeIfPresent(Bool.self, forKey: .drawFourChallengeEnabled) ?? false
    savedPlayerNames = try c.decodeIfPresent([String].self, forKey: .savedPlayerNames) ?? []
}
```

`tableBackgroundStyle` belongs in this owner with `.felt` as the missing-key fallback.

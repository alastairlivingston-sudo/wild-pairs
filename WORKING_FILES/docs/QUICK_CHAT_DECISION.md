# Quick-chat decision

## Decision for this patch

Quick chat is **not** included in the visual integration patch.

The supplied project contains no authoritative path from a phrase such as “Play +2” to the AI partner’s decision. Specifically, there is no:

- `GameAction` for a partner instruction;
- pending instruction field in `GameState`;
- presenter method;
- view-model intent;
- AI scoring/preference hook;
- deterministic test contract.

Adding tappable phrases that only animate or show a toast would imply strategic communication without changing partner behaviour. That would be misleading product design.

## Recommended future contract

Implement quick chat as a separately reviewed rules/AI feature with this shape:

```swift
public enum PartnerInstruction: String, Codable, CaseIterable, Sendable {
    case playDrawCard
    case changeColour
    case saveWild
}
```

Suggested state:

```swift
public struct PendingPartnerInstruction: Codable, Equatable, Sendable {
    public let fromPlayerID: UUID
    public let partnerID: UUID
    public let instruction: PartnerInstruction
    public let expiresAfterTurnNumber: Int
}
```

Suggested intent path:

```text
QuickChatStrip tap
-> GameViewModel.sendPartnerInstruction(...)
-> GamePresenter.sendPartnerInstruction(...)
-> GameAction.partnerInstruction(...)
-> GameState stores one pending non-binding preference
-> AI decision scorer applies a small deterministic preference when legal
-> preference is consumed on the partner’s next decision
-> UI receives followed / impossible / overridden result
```

## Product behaviour

- One pending instruction at a time.
- Valid for the partner’s next decision only.
- Non-binding: forced moves and materially stronger legal moves may override it.
- No network, social, currency, or message history.
- The UI reports one of: followed, impossible, overridden by forced move.
- VoiceOver reads the instruction and result.
- The feature is disabled when no AI partner exists.

## Tests required before UI is added

1. Instruction is stored for the correct partner.
2. It expires after one partner decision.
3. It never causes an illegal move.
4. Forced draws/choices override it.
5. Repeated taps replace rather than stack instructions.
6. Save/load is either deliberately supported or deliberately clears it.
7. Seeded AI tests prove deterministic outcomes.
8. Pass-and-play and human-partner modes do not present a fake AI instruction strip.

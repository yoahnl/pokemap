# PSDK Fight Misc Action Scope

Date: 2026-05-17

## Decision

Lot 63 ports the local non-attack action grammar that can be represented by the
current clean battle engine without inventing external runtime contracts.

## Implemented Scope

- `BattleDecision.flee()` maps to `PsdkBattleFleeAction`.
- `BattleEngineSetup.singles(canFlee: true)` marks an eligible wild-style battle
  for the clean engine.
- Successful flee sets `PsdkBattleOutcomeKind.fled` and emits a
  `BattleFleeAttemptTimelineEvent`.
- Trainer/non-fleeable battles emit the same flee attempt event with
  `succeeded: false` and continue.
- `BattleDecision.noAction()` maps to `PsdkBattleNoAction` and consumes the
  submitted action without spending PP or resolving move effects.
- `BattleDecision.shift(target: ...)` maps to `PsdkBattleShiftAction`.
- `BattleShiftActionHandler` swaps two adjacent active slots on the same bank
  and marks both battlers as `hasJustShifted`.

## Explicitly Out Of Scope

- Safari battle commands.
- Safari bait/rock/ball state.
- Capture odds and Safari flee odds.
- Runtime bag/inventory ownership for Safari balls.
- Multi-battle setup construction through `BattleEngineSetup`.

Safari needs a runtime/capture contract that is broader than the current clean
combat engine. This lot intentionally documents it instead of silently faking a
partial Safari action.

## Parity Note

This closes the local action-topology gap for flee, no-action, and shift. It
does not promote any move method or strict attack coverage because these are
turn/action grammar behaviors, not attack-method implementations.

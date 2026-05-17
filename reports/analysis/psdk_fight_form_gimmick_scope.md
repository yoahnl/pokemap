# PSDK Fight Form/Gimmick Scope

Date: 2026-05-17

## Decision

Lot 62 implements a narrow, data-driven Mega Evolution action for the clean PSDK
battle lane. It does not implement a global form catalog, Z-Moves, Dynamax/Max,
Terastal, Primal Reversion, Ultra Burst, or species-specific form scripting.

## Implemented Scope

- `BattleDecision.mega(form: ...)` maps to `PsdkBattleMegaAction`.
- `PsdkBattleMegaEvolution` carries the already-resolved battle form data:
  - required base species id
  - resulting species id
  - display name
  - battle types
  - battle stats
  - battle ability id
- The action uses the existing PSDK `mega` action ordering bucket, which runs
  after switch actions and before regular fight actions.
- The handler applies the resulting form to the active battler while preserving:
  - current HP
  - max HP
  - move list
  - major status
  - volatile/effect state, except hydrated ability effects are refreshed
- The active party entry is updated alongside the active slot so later switches
  keep the Mega form snapshot.
- A bank may Mega Evolve only once per battle.
- Ineligible attempts fail atomically through the existing turn rollback path.
- Timeline output uses a PSDK effect event with `effectId: mega:<speciesId>` and
  `reason: mega`.

## Explicitly Out Of Scope

- Item/key-stone ownership validation.
- A species/form database lookup inside `map_battle`.
- Automatic Mega target discovery from held item.
- Primal Reversion and Ultra Burst.
- Z-Moves, Max/Dynamax moves, and Terastal behavior.
- Form changes driven by field abilities, species scripts, or external runtime
  animation state.

Those require a broader runtime/import contract and should not be silently
guessed by the battle engine.

## Parity Note

This lot closes the action-topology gap for a resolved Mega action. It does not
promote any move method or strict attack coverage because PSDK gimmicks are
action/form state, not attack-method behavior.

# P3 Outcome Battle Continuation Fixture

Technical non-Selbrume fixture for P3-04.

It proves:

- `emitOutcome` writes `scenario.outcome.<outcomeId>`.
- `sourceOutcome` / explicit `outcomeReceived` can continue a global scenario.
- `startTrainerBattle` returns a `ScenarioRuntimeEffectType.battle` handoff.
- `battle:<battleId>:victory` and `battle:<battleId>:defeat` stay separate from
  `scenario.outcome.*`.
- Post-battle continuation can be simulated through the existing
  `dispatchContinuation` API after setting the battle outcome flag.

It does not prove a full battle engine run, rewards, money, XP, save/load
roundtrip, World Rules, UI, PlayableMapGame hooks, or a host smoke test.

# PSDK Golden Fixture Schema

Required top-level fields:

- `scenarioId`: stable snake-case identifier.
- `sourcePsdkVersion`: source Pokemon SDK version, branch, or local snapshot.
- `initialBattle`: deterministic singles setup consumed by `PsdkBattleSetup`.
- `actions`: ordered player actions to submit to the Dart engine.
- `expectedFinalState`: observable HP and outcome expectations after the last
  action.
- `expectedTimeline`: expected event kinds and optional event payload checks for
  the last submitted action.
- `notes`: short audit notes explaining why the scenario exists.

`initialBattle` contains:

- `rngSeeds`: `moveDamage`, `moveCritical`, `moveAccuracy`, and `generic`.
- `player`: a combatant object.
- `opponent`: a combatant object.

Combatant objects contain:

- Identity: `id`, `speciesId`, `displayName`, `level`.
- HP: `maxHp`, `currentHp`.
- `types`: `primary` and optional `secondary`.
- `stats`: `attack`, `defense`, `specialAttack`, `specialDefense`, `speed`.
- `moves`: ordered move objects.

Move objects contain:

- `id`, `dbSymbol`, `name`, `type`.
- `category`: `physical`, `special`, or `status`.
- `power`, `accuracy`, `pp`, optional `currentPp`.
- `priority`, optional `criticalRate`, optional `effectChance`.
- `battleEngineMethod`: Pokemon SDK method symbol such as `s_basic`.
- `target`: a `PsdkBattleMoveTarget` enum name such as `adjacentFoe`.
- Optional booleans: `protectable`, `sound`.

Actions currently support:

- `{ "actor": "player", "kind": "fight", "moveSlot": 0 }`

`expectedFinalState` currently supports:

- `player.currentHp`
- `opponent.currentHp`
- optional `outcomeKind`: `victory`, `defeat`, `draw`, or `escaped`

`expectedTimeline` currently supports:

- `eventKinds`: exact ordered list of emitted event kinds.
- `damageEvents`: optional list of `{ "moveId", "damage", "remainingHp" }`
  checks, in emitted order.

# PSDK Golden Fixture Schema

Required top-level fields:

- `scenarioId`: stable snake-case identifier.
- `tags`: stable fixture tags used by the final parity gate. Current tags are
  `move_method`, `effect_family`, `ability`, `item`, `status`, `field`,
  `doubles`, `runtime_bridge`, and focused behavior tags such as `damage`.
- `psdkSourcePaths`: one or more source files under
  `pokemonsdk-development/scripts/5 Battle` that justify the expected behavior.
- `sourcePsdkVersion`: source Pokemon SDK version, branch, or local snapshot.
- `initialBattle`: deterministic singles setup consumed by `PsdkBattleSetup`.
- `actions`: ordered player actions to submit to the Dart engine.
- `expectedFinalState`: observable HP and outcome expectations after the last
  action.
- `expectedTimeline`: expected event kinds and optional event payload checks for
  the last submitted action.
- `expectedAuditDeltas`: optional expected contribution to audit axes when the
  fixture's represented behavior is fully strict. Omitted deltas default to `0`.
- `notes`: short audit notes explaining why the scenario exists.

`initialBattle` contains:

- `rngSeeds`: `moveDamage`, `moveCritical`, `moveAccuracy`, and `generic`.
- optional `field`: active `weather` and/or `terrain`, each with `id` and
  `remainingTurns`.
  `id` values use Dart enum names such as `rain` or `electricTerrain`.
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
- Optional booleans: `contact`, `protectable`, `sound`.
- Optional `statuses`: ordered status riders. Major statuses use
  `{ "status": "paralysis", "chance": 100 }`; volatile statuses use
  `{ "volatileStatus": "confusion", "chance": 100 }`.
- Optional `stageMods`: ordered stat-stage riders, each with `stat`, `stages`
  and optional `chance`.

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
- `statusEvents`: optional list of `{ "moveId", "status" }` checks, in
  emitted order.
- `statStageEvents`: optional list of `{ "stat", "amount", "currentStage" }`
  checks, in emitted order.

At least one tag must be a parity-gate tag:

- `move_method`
- `effect_family`
- `ability`
- `item`
- `status`
- `field`
- `doubles`
- `runtime_bridge`

Focused behavior tags such as `damage` may be added alongside gate tags.

The final PSDK parity gate currently requires the golden corpus to contain at
least the `move_method`, `status`, and `field` gate tags. This prevents the
100% counter gate from being backed only by one narrow fixture family.

`expectedAuditDeltas`, when present, contains:

- `strictAttacks`: number of strict attack entries represented by the fixture.
- `portedMethods`: number of PSDK move methods represented by the fixture.
- `portedEffects`: number of PSDK effect classes represented by the fixture.

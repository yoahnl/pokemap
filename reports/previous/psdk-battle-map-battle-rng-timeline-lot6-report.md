# PSDK Battle Migration - Lot 6 RNG Streams et Timeline

## Nom exact du lot

Lot 6 - RNG streams et timeline riche.

## Résumé exécutif

Le lot 6 ajoute une couche clean pour les quatre RNG PSDK (`moveDamage`,
`moveCritical`, `moveAccuracy`, `generic`) et remplace la timeline clean qui
contenait directement des `PsdkBattleEvent` par des `BattleTimelineEvent`
runtime-agnostic.

La compatibilité est conservée :

- `BattleEngine` retourne maintenant une `BattleTimeline` clean;
- `PsdkBattleEngine` continue de retourner une `PsdkBattleTimeline`;
- le CLI conserve exactement les mêmes `kind` JSON historiques;
- le legacy `BattleRng`, `BattleSeededRng`, `BattleTurnEvent` et
  `BattleTurnResult` ne sont pas modifiés.

## Sources PSDK relues

Fichiers Ruby inspectés :

- `pokemonsdk-development/scripts/5 Battle/04 Logic/100 Logic.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/101 Damage_Calc.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/104 Chance of Hit.rb`
- `pokemonsdk-development/scripts/5 Battle/02 Visual/206 Show_stuff.rb`

Constats retenus :

- PSDK utilise des RNG séparées pour damage, critical, accuracy et generic.
- Les couches Visual Ruby (`show_hp_animations`, `show_move_animation`,
  `display_message_and_wait`) ne doivent pas être copiées dans le domaine Dart.
- En Dart clean, on expose des événements descriptifs et stables; le runtime
  décidera plus tard comment les animer.

## Fichiers créés

- `packages/map_battle/lib/src/domain/rng/battle_seeded_rng.dart`
- `packages/map_battle/lib/src/domain/rng/battle_rng_streams.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline_builder.dart`
- `packages/map_battle/test/psdk_rng_streams_test.dart`
- `packages/map_battle/test/psdk_timeline_test.dart`

## Fichiers modifiés

### `packages/map_battle/lib/src/domain/battle/battle_context.dart`

- Remplace le stockage interne `PsdkBattleRngStreams` par
  `BattleRngStreams`.
- Expose `BattlePublicState.rngSeeds` pour prouver les consommations RNG en
  test.

### `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`

- Les behaviors PSDK reçoivent maintenant les streams clean.
- La logique existante reste identique : accuracy consomme `moveAccuracy`,
  damage consomme `moveDamage`, status probabiliste consomme `generic`.

### `packages/map_battle/lib/src/application/battle_turn_runner.dart`

- Construit une `BattleTimeline` clean via `BattleTimelineBuilder`.
- Convertit les événements PSDK temporaires des behaviors vers des
  `BattleTimelineEvent`.
- Ajoute `BattleEndedTimelineEvent` clean au lieu de pousser directement un
  `PsdkBattleEndedEvent`.

### `packages/map_battle/lib/src/domain/timeline/battle_timeline.dart`

- `BattleTimeline.events` contient désormais des `BattleTimelineEvent`.
- `BattleTimeline.psdkTimeline` est un adaptateur de compatibilité pour
  `PsdkBattleEngine` et le CLI.

### `packages/map_battle/lib/map_battle.dart`

- Exports publics bornés pour les nouveaux types RNG et timeline clean.

## Logique créée

### RNG

- `BattleRngStream` est un stream déterministe immutable.
- `BattleRngSeeds` transporte les quatre seeds.
- `BattleRngStreams` transporte les quatre streams indépendants :
  `moveDamage`, `moveCritical`, `moveAccuracy`, `generic`.
- `BattleRngStreams.fromPsdkSeeds` et `BattleRngSeeds.psdkSeeds` servent de
  pont avec les DTO PSDK actuels.
- `moveCritical` est présent et transporté mais pas encore consommé : les crits
  PSDK complets restent un lot ultérieur.

### Timeline

La timeline clean contient des events descriptifs :

- `turn_started`, `turn_ended`;
- `decision_requested`;
- `action_started`, `action_ended`;
- `move_declared`, `move_failed`, `miss`, `move_immune`;
- `animation_cue`;
- `damage`, `heal`;
- `status`, `stat_stage_change`;
- `effect_added`, `effect_removed`, `effect_ticked`;
- `switch_out`, `switch_in`;
- `item_used`, `item_consumed`;
- `ability_triggered`;
- `weather_changed`, `terrain_changed`;
- `capture_attempt`, `flee_attempt`;
- `battle_ended`.

Ces events n'ont aucune dépendance Flutter/Flame et ne transportent que des ids
stables ou des `BattlePositionRef`.

## Tests créés

### `packages/map_battle/test/psdk_rng_streams_test.dart`

Couverture :

- avancer `moveAccuracy` ne modifie pas les autres streams;
- les contrats de chance invalides échouent explicitement;
- un miss consomme `moveAccuracy` mais pas `moveDamage`, `moveCritical` ou
  `generic`;
- un status probabiliste consomme `generic` mais pas `moveDamage`.

### `packages/map_battle/test/psdk_timeline_test.dart`

Couverture :

- `BattleTimeline` stocke des events clean immutables;
- l'adaptation `BattleTimeline.psdkTimeline` conserve les `kind` historiques;
- `BattleEngine` émet des `BattleDamageTimelineEvent`;
- `PsdkBattleEngine` continue d'émettre des `PsdkBattleDamageEvent`;
- les `kind` JSON du CLI restent stables.

## Sub-agent

Sub-agent Peirce lancé en lecture seule.

Recommandations intégrées :

- ne pas toucher au legacy `BattleRng` / `BattleSeededRng`;
- ne pas réutiliser `BattleTurnEvent`;
- faire porter à `BattleTimeline` des events clean, avec adaptateur vers PSDK;
- conserver les `kind` JSON historiques;
- ne pas copier la couche Visual Ruby dans le domaine;
- vérifier que les bypass accuracy ne consomment pas de RNG;
- vérifier qu'un miss ne produit pas d'`animation_cue`.

## Commandes de test lancées

Depuis `packages/map_battle` :

```bash
dart test test/psdk_rng_streams_test.dart test/psdk_timeline_test.dart
```

Résultat exact :

```text
00:00 +6: All tests passed!
```

```bash
dart test test/psdk_rng_streams_test.dart test/psdk_timeline_test.dart test/psdk_battle_topology_test.dart test/psdk_battler_state_test.dart test/battle_engine_clean_architecture_test.dart test/psdk_engine_smoke_test.dart test/battle_state_topology_test.dart
```

Résultat exact :

```text
00:00 +50: All tests passed!
```

```bash
dart test test/psdk_battle_cli_test.dart
```

Résultat exact :

```text
00:00 +2: All tests passed!
```

```bash
dart test
```

Résultat exact :

```text
00:00 +254: All tests passed!
```

## Commandes d'analyse et build

Depuis `packages/map_battle` :

```bash
dart analyze
```

Résultat exact :

```text
Analyzing map_battle...
No issues found!
```

```bash
dart compile exe bin/psdk_battle_cli.dart -o /tmp/pokemon_project_psdk_battle_cli
```

Résultat exact :

```text
Generated: /tmp/pokemon_project_psdk_battle_cli
```

Depuis la racine :

```bash
git diff --check
```

Résultat exact :

```text
<no output>
```

## Smoke CLI

Depuis `packages/map_battle` :

```bash
dart run bin/psdk_battle_cli.dart --format json
```

Résultat exact :

```json
{"outcome":"victory","turns":1,"playerHp":44,"opponentHp":0,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","moveName":"Scratch"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","damage":18,"remainingHp":0},{"kind":"battle_ended","outcome":"victory"}]}
```

```bash
dart run bin/psdk_battle_cli.dart --format text
```

Résultat exact :

```text
outcome=victory turns=1 playerHp=44 opponentHp=0
```

## Limites conservées

- Les critical hits PSDK ne sont pas encore portés dans la lane clean; le stream
  `moveCritical` est seulement transporté.
- Les behaviors retournent encore temporairement des événements PSDK internes,
  puis le runner les adapte en events clean. Les lots move/effects suivants
  pourront faire produire directement des `BattleTimelineEvent`.
- Les events clean riches ne sont pas encore tous produits par le moteur; ils
  définissent le vocabulaire attendu pour les lots suivants.
- Le legacy `battle_resolution.dart` et `battle_rng.dart` restent en place pour
  la coexistence runtime actuelle.

## Prochaines étapes proposées

- Lot 7 : move data / move instance / registry `battleEngineMethod` clean.
- Déplacer progressivement les behaviors depuis `src/psdk/application` vers le
  domaine/application clean.
- Brancher les futurs handlers pour produire directement les events clean.

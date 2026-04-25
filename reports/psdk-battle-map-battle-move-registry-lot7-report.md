# PSDK Battle Migration - Lot 7 Move Registry

## Nom exact du lot

Lot 7 - Move data, move instance et registry `battleEngineMethod`.

## Résumé exécutif

Le lot 7 introduit le triptyque clean PSDK côté `map_battle` :

- `BattleMoveDefinition` pour la donnée catalogue immutable;
- `BattleMoveInstance` pour l'état mutable par battler;
- `BattleMoveRegistry` / `BattleMoveBehavior` pour résoudre les behaviors par
  `battleEngineMethod`.

Pour éviter les collisions avec le legacy, aucun nouveau `BattleMoveData` clean
n'a été exporté. Le legacy `BattleMoveData` reste le type historique de
`battle_setup.dart`; la lane PSDK clean utilise `BattleMoveDefinition`.

`PsdkBattleMoveBehaviorRegistry` reste compatible et devient une façade vers la
registry clean. Les tests et le CLI existants continuent donc de fonctionner.

## Sources PSDK relues

Fichiers Ruby inspectés :

- `pokemonsdk-development/scripts/5 Battle/10 Move/100 Move.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/100 Basic.rb`

Constats retenus :

- PSDK sépare l'instance de move mutable (`@pp`, `@used`) de la donnée
  catalogue (`data_move`).
- Les moves sont enregistrés par symbole de behavior (`s_basic`, etc.), pas par
  id d'attaque.
- Le Ruby a un fallback `Hash.new(Move)`, mais le plan Dart conserve le choix
  inverse : échec explicite pour les methods non portées.

## Fichiers créés

- `packages/map_battle/lib/src/domain/move/battle_move_data.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_instance.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_registry.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/test/psdk_move_registry_test.dart`

## Fichiers modifiés

### `packages/map_battle/lib/src/domain/battle/battle_battler.dart`

- `BattleMoveInstance` a été déplacé vers `src/domain/move`.
- `BattleBattler.fromPsdkSetup` et `fromPsdkCombatant` créent maintenant des
  `BattleMoveDefinition` puis des `BattleMoveInstance`.

### `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`

- `PsdkBattleMoveBehaviorRegistry` reste l'API PSDK existante.
- Son constructeur historique accepte toujours une map de callbacks PSDK.
- `defaults()` délègue désormais à `createStaticBasicMoveRegistry()`.
- `fromClean()` permet d'injecter directement une `BattleMoveRegistry`.
- Les methods inconnues continuent de jeter `UnsupportedPsdkBattleMoveBehavior`.

### `packages/map_battle/lib/map_battle.dart`

- Exports publics bornés pour :
  - `BattleMoveDefinition`;
  - `BattleMoveFlags`;
  - `BattleStageMod`;
  - `BattleMoveInstance`;
  - `BattleMoveBehavior`;
  - `BattleMoveRegistry`;
  - `UnsupportedBattleMoveBehavior`;
  - `createStaticBasicMoveRegistry`.

## Logique créée

### Move definition

`BattleMoveDefinition` porte :

- `id`, `dbSymbol`, `name`, `type`;
- `category`, `power`, `accuracy`, `pp`, `priority`;
- `criticalRate`, `effectChance`;
- `battleEngineMethod`;
- `target`;
- `flags`;
- `stageMods`;
- `statuses`.

Il peut être construit depuis `PsdkBattleMoveData` et se reconvertir en DTO
PSDK pour l'adaptateur existant.

### Move instance

`BattleMoveInstance` porte :

- `pp`, `maxPp`;
- `used`;
- `consecutiveUseCount`;
- `damageDealt`;
- `originalTargets`;
- un lien optionnel vers sa `BattleMoveDefinition`.

La donnée catalogue ne change pas quand l'instance dépense des PP ou marque un
usage.

### Registry

`BattleMoveRegistry` mappe `battleEngineMethod -> BattleMoveBehavior`.

`createStaticBasicMoveRegistry()` fournit les deux behaviors actuellement
supportés :

- `s_basic`;
- `s_status`.

Le lookup reste volontairement par behavior et pas par move id, afin que
plusieurs moves Studio puissent partager le même handler.

## Tests créés

### `packages/map_battle/test/psdk_move_registry_test.dart`

Couverture :

- résolution par `battleEngineMethod`, pas par move id;
- deux moves différents pointant vers `s_basic` utilisent le même behavior;
- method inconnue : échec explicite côté clean et côté façade PSDK;
- snapshot immutable de la collection de behaviors;
- conservation de `accuracy: 0` comme sentinelle PSDK;
- séparation `BattleMoveDefinition` immutable / `BattleMoveInstance` mutable;
- non-shadowing du legacy `BattleMoveData` à la racine.

## Sub-agent

Sub-agent Russell lancé en lecture seule.

Recommandations intégrées :

- ne pas créer/exporter de `BattleMoveData` clean à la racine;
- utiliser `BattleMoveDefinition`;
- garder `PsdkBattleMoveBehaviorRegistry` comme façade compatible;
- résoudre par `battleEngineMethod`;
- conserver le fail loud pour les methods non portées;
- ne pas normaliser `accuracy: 0`;
- ne pas toucher au legacy `battle_move.dart` / `battle_setup.dart`.

## Commandes de test lancées

Depuis `packages/map_battle` :

```bash
dart test test/psdk_move_registry_test.dart
```

Résultat exact :

```text
00:00 +6: All tests passed!
```

```bash
dart test test/psdk_move_registry_test.dart test/psdk_engine_smoke_test.dart test/battle_engine_clean_architecture_test.dart test/psdk_battle_cli_test.dart test/psdk_rng_streams_test.dart test/psdk_timeline_test.dart test/psdk_battle_topology_test.dart test/psdk_battler_state_test.dart
```

Résultat exact :

```text
00:00 +54: All tests passed!
```

```bash
dart test
```

Résultat exact :

```text
00:00 +260: All tests passed!
```

## Commandes d'analyse

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

- Les behaviors `s_basic` et `s_status` produisent encore des
  `PsdkBattleEvent`, adaptés ensuite par le runner en timeline clean.
- Le moteur n'utilise pas encore `criticalRate`, `stageMods` ou les flags.
- Le pipeline complet `Move#proceed` de PSDK reste le sujet du lot 8.
- Le legacy `BattleMove` / `BattleMoveData` reste inchangé.

## Prochaines étapes proposées

- Lot 8 : introduire `BattleMoveExecution`, targeting et accuracy resolver.
- Faire produire progressivement des `BattleTimelineEvent` directement par les
  behaviors clean.
- Brancher `BattleMoveInstance.markUsed` dans le pipeline réel quand le
  scheduler clean remplacera le runner singles provisoire.

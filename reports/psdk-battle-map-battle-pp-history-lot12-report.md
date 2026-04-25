# PSDK Battle Migration - Lot 12 PP et historique

## Nom exact du lot

Lot 12 - PP courants, refus PP, historique de move et failures PSDK.

## Resume executif

La lane clean PSDK ne traite plus les moves comme des definitions statiques
uniquement. Elle porte maintenant un etat de PP courant par move, consomme les
PP selon l'ordre PSDK, expose l'historique attempted/successful par combatant,
et rend les echecs de move compatibles avec la timeline PSDK/CLI.

Changement visible : le CLI smoke par defaut emet maintenant
`move_pp_spent` avant `move_declared`. C'est volontaire : Pokemon SDK consomme
les PP dans `move_usable_by_user`, avant le message d'usage, l'accuracy et
l'immunite.

## Sources PSDK relues

Fichiers Ruby inspectes :

- `pokemonsdk-development/scripts/5 Battle/10 Move/100 Move.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/130 Move Prevention.rb`
- `pokemonsdk-development/scripts/5 Battle/03 PokemonBattler/001 PokemonBattler.rb`
- `pokemonsdk-development/scripts/5 Battle/03 PokemonBattler/100 MoveHistory.rb`
- `pokemonsdk-development/scripts/5 Battle/05 Actions/002 Attack.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/101 Damage_Calc.rb`

Constats retenus :

- les PP vivent sur l'instance `Battle::Move` ;
- `Move#pp=` clamp entre `0` et `ppmax` ;
- `move_usable_by_user` lance les hooks de prevention user, refuse si `pp == 0`,
  puis appelle `decrease_pp` ;
- `decrease_pp` retire `1` PP, puis un PP additionnel avec Pressure ;
- la consommation PP arrive avant `usage_message`, accuracy, immunity et no
  target ;
- un move tente est ajoute a `move_history` meme si le precheck echoue ;
- un move reussi est ajoute a `successful_move_history` apres les gates
  accuracy/immunity et la procedure normale ;
- `on_move_failure` est appele pour `usable_by_user`, `no_target`, `accuracy`,
  `immunity`, `pp` ;
- `forced_next_move_decrease_pp` existe pour les moves forces, mais Encore et les
  effets associes restent hors scope.

## Fichiers modifies

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_move.dart`

Ajouts :

- `currentPp` sur `PsdkBattleMoveData` ;
- validation `0..pp` ;
- getter `hasUsablePp` ;
- methode immutable `spendPp()`.

Objectif :

- separer le PP maximum (`pp`) du PP courant (`currentPp`) sans introduire une
  dependance runtime/editor.

### `packages/map_battle/lib/src/domain/move/battle_move_data.dart`

Ajouts :

- `currentPp` dans `BattleMoveDefinition` ;
- mapping `fromPsdk` depuis `PsdkBattleMoveData.currentPp` ;
- mapping `psdkMove` vers `PsdkBattleMoveData.currentPp`.

Objectif :

- garder la couche clean comme passage obligatoire entre DTO PSDK et handlers.

### `packages/map_battle/lib/src/domain/move/battle_move_instance.dart`

Changement :

- `BattleMoveInstance.fromDefinition` initialise `pp` depuis
  `definition.currentPp`, pas depuis le PP maximum.

Objectif :

- preparer les futurs ponts vers les battlers clean mutables sans perdre le PP
  courant importe.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`

Ajouts :

- `PsdkBattleMoveHistoryEntry` ;
- `PsdkBattleMoveHistory` ;
- `moveHistory` sur `PsdkBattleCombatantSetup` et `PsdkBattleCombatant` ;
- `replaceMoveAt` pour remplacer un move DTO apres depense PP ;
- `recordMoveAttempt` ;
- `recordMoveSuccess`.

Objectif :

- exposer les donnees PSDK dont beaucoup de moves speciaux auront besoin
  ensuite : last move, last successful move, targets et turn.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`

Ajout :

- `updateBattler(slot, update)` pour centraliser les remplacements immutables.

### `packages/map_battle/lib/src/application/battle_turn_runner.dart`

Changement principal :

- `_BattleResolvedAction` transporte maintenant `moveSlot` ;
- le runner verifie `currentPp` avant resolution ;
- si `currentPp == 0` :
  - record attempted history ;
  - emet `move_failed` avec `reason: pp` ;
  - ne consomme aucun RNG ;
  - ne declare pas le move ;
- si le move a du PP :
  - depense 1 PP ;
  - emet `move_pp_spent` ;
  - appelle le behavior ;
  - record attempted history ;
  - record successful history seulement si le behavior est marque successful.

Ordre obtenu :

```text
turn_started
move_pp_spent
move_declared
...
```

### `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`

Ajout :

- `BattleMoveBehaviorResolution.successful`.

Semantique :

- `true` par defaut pour les behaviors qui passent leur procedure ;
- `false` pour les failures de preparation comme accuracy, no target ou
  immunity.

### `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`

Ajout :

- propagation du flag `successful` entre facade PSDK et behavior clean.

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Changements :

- `_PreparedMove.toResolution()` renvoie `successful: false` par defaut ;
- `s_status` sans status declaratif peut encore etre considere comme successful
  si la procedure est passee.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_timeline.dart`

Ajouts :

- `PsdkBattleMovePpSpentEvent` ;
- `PsdkBattleMoveFailedEvent`.

### `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`

Ajouts :

- `BattleMovePpSpentTimelineEvent` ;
- conversion PSDK -> clean pour `move_pp_spent` ;
- conversion clean -> PSDK pour `move_pp_spent` ;
- conversion PSDK -> clean pour `move_failed` ;
- conversion clean -> PSDK pour `move_failed`.

Note :

- `move_declared` avec zero cible clean reste non convertible en PSDK car
  `PsdkBattleMoveDeclaredEvent` exige une cible.

### `packages/map_battle/lib/src/domain/decision/battle_decision.dart`

Changement :

- `BattleEngineDecisionRequest` n'expose plus les moves dont `currentPp == 0`
  dans `fightChoices`.

Objectif :

- rapprocher le choix joueur de PSDK, qui filtre les moves sans PP avant
  execution, tout en gardant la protection engine si un caller soumet quand meme
  un slot sans PP.

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Ajout :

- scenario `pp_empty` / `pp-empty`.

Le scenario configure le move joueur `empty_ember` avec `currentPp: 0`, puis
verifie que l'engine raconte un `move_failed` avec `reason: pp`.

### `packages/map_battle/lib/map_battle.dart`

Export ajoute :

- `BattleMovePpSpentTimelineEvent`.

### `packages/map_battle/test/psdk_pp_history_test.dart`

Nouveau fichier.

Couverture :

- un move reussi consomme 1 PP et record attempted + successful history ;
- un move rate consomme 1 PP, record attempted seulement et ne record pas
  successful ;
- un move a 0 PP echoue avant declaration, garde le RNG intact et record
  attempted seulement.

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Ajout :

- test du scenario `pp_empty`.

### `packages/map_battle/test/psdk_move_procedure_test.dart`

Mise a jour :

- `move_failed` est maintenant convertible en event PSDK ;
- le test no-target attend donc un `PsdkBattleMoveFailedEvent`.

## Logique detaillee

### PP

Regle implementee :

- `pp` = maximum ;
- `currentPp` = etat courant ;
- `currentPp` est clamp/valide entre `0` et `pp` ;
- `spendPp()` retourne un nouveau `PsdkBattleMoveData`.

Le runner depense 1 PP avant d'appeler le behavior. Cela signifie que miss,
immunity et failures de procedure apres PP consomment deja le PP, comme PSDK.

### Historique

Chaque combatant porte maintenant :

- `attempts` ;
- `successes` ;
- `lastMoveId` ;
- `lastSuccessfulMoveId` ;
- `usedMoveIds` ;
- `successfulMoveIds`.

Le lot conserve un historique simple, mais les entrees portent deja :

- `moveId` ;
- `turn` ;
- `targets`.

### Timeline

Nouveaux events :

```json
{"kind":"move_pp_spent","user":{"bank":0,"position":0},"moveId":"scratch","spent":1,"remainingPp":34}
```

```json
{"kind":"move_failed","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"empty_ember","reason":"pp"}
```

## Sub-agent

Sub-agent Pascal lance en lecture seule.

Ce qu'il a confirme :

- PP consomme dans `move_usable_by_user`, avant accuracy/immunity ;
- PP zero refuse avant `usage_message` ;
- miss, immunity et no-target peuvent deja avoir consomme le PP ;
- attempted history et successful history sont deux listes differentes ;
- `successful_move_history` est ajoute apres le passage des gates de procedure ;
- le lot doit garder Pressure, abilities/items, Encore et forced moves hors
  scope.

## Commandes de test lancees

Depuis `packages/map_battle` :

```bash
dart test test/psdk_pp_history_test.dart
```

Resultat exact :

```text
00:00 +3: All tests passed!
```

```bash
dart test test/psdk_move_procedure_test.dart test/psdk_pp_history_test.dart test/psdk_battle_cli_test.dart
```

Resultat exact :

```text
00:00 +13: All tests passed!
```

```bash
dart test test/psdk_pp_history_test.dart test/psdk_battle_cli_test.dart test/psdk_timeline_test.dart test/psdk_engine_smoke_test.dart test/battle_engine_clean_architecture_test.dart test/psdk_rng_streams_test.dart test/psdk_type_damage_test.dart test/psdk_secondary_effects_test.dart
```

Resultat exact :

```text
00:00 +45: All tests passed!
```

```bash
dart test
```

Resultat exact :

```text
00:00 +282: All tests passed!
```

## Commandes d'analyse

Depuis `packages/map_battle` :

```bash
dart analyze
```

Resultat exact :

```text
Analyzing map_battle...
No issues found!
```

```bash
dart compile exe bin/psdk_battle_cli.dart -o /tmp/pokemon_project_psdk_battle_cli
```

Resultat exact :

```text
Generated: /tmp/pokemon_project_psdk_battle_cli
```

Depuis la racine :

```bash
git diff --check
```

Resultat exact :

```text
<no output>
```

## Smoke CLI

### Scenario par defaut

Commande :

```bash
dart run bin/psdk_battle_cli.dart --format json
```

Resultat exact :

```json
{"outcome":"victory","turns":1,"playerHp":44,"opponentHp":0,"events":[{"kind":"turn_started","turn":1},{"kind":"move_pp_spent","user":{"bank":0,"position":0},"moveId":"scratch","spent":1,"remainingPp":34},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","moveName":"Scratch"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","damage":18,"remainingHp":0},{"kind":"battle_ended","outcome":"victory"}]}
```

### Scenario `pp_empty`

Commande :

```bash
dart run bin/psdk_battle_cli.dart --scenario pp_empty --format json
```

Resultat exact :

```json
{"outcome":"ongoing","turns":1,"playerHp":100,"opponentHp":100,"events":[{"kind":"turn_started","turn":1},{"kind":"move_failed","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"empty_ember","reason":"pp"},{"kind":"move_pp_spent","user":{"bank":1,"position":0},"moveId":"opponent_wait","spent":1,"remainingPp":34},{"kind":"move_declared","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait","moveName":"opponent_wait"},{"kind":"miss","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait"}]}
```

## Limites connues et prochains lots

Pas encore porte :

- Pressure ;
- Struggle ;
- disabled moves ;
- prevention user hooks effectifs ;
- target prevention hooks effectifs ;
- `pre_accuracy_check_effects` / `post_accuracy_check_effects` effectifs ;
- `post_accuracy_check_move` specialise ;
- forced next move / Encore ;
- `damage_dealt` snapshot dans history ;
- `consecutive_use_count` aligne sur PSDK Damage_Calc ;
- move history complet avec attack order et original move.

Prochain lot recommande :

- Lot 13 - hooks de procedure minimaux et move prevention extensible, sans
  abilities/items complets.

# PSDK Battle Migration - Lot 11 Effets secondaires

## Nom exact du lot

Lot 11 - Effets secondaires PSDK pour `s_basic` : statuts majeurs, changements
de stages et scenario CLI.

## Resume executif

Le moteur clean `map_battle` sait maintenant appliquer les riders de base des
moves PSDK apres un coup reussi :

- statut majeur secondaire sur une attaque de degats ;
- changement de stage cible sur une attaque de degats ;
- chance globale `effectChance` pour les effets secondaires de `s_basic` ;
- consommation du stream RNG `generic` pour ces effets ;
- evenement timeline `stat_stage_change` ;
- scenario CLI `secondary_effect` pour tester le comportement sans Flutter.

La logique reste volontairement scopee au chemin `s_basic`. Les moves `s_status`
gardent leur comportement precedent, car Pokemon SDK signale explicitement que
les moves stat/status ignorent `effect_chance`.

## Sources PSDK relues

Fichiers Ruby inspectes :

- `pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/100 Move.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/100 Basic.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/102 Status Stat.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/120 StatAndStageEdit.rb`
- `pokemonsdk-development/scripts/5 Battle/03 PokemonBattler/003 Statistics.rb`

Constats retenus :

- la procedure PSDK execute `deal_damage && effect_working? && deal_status &&
  deal_stats && deal_effect` apres l'animation ;
- `Basic#deal_damage` retire les cibles dont les degats n'ont pas vraiment
  abouti, donc les riders ne doivent pas partir sur miss, immunite ou degat nul ;
- `Basic#effect_working?` applique une chance globale basee sur
  `effect_chance`, modifiee plus tard par abilities/effects ;
- `Move#effect_chance` normalise `0` en `100` cote Ruby ;
- `deal_status` utilise `generic_rng` pour choisir/appliquer le statut ;
- `deal_stats` parcourt `battle_stage_mod` et passe par le handler de changement
  de stats ;
- les stages PSDK sont bornes entre `-6` et `+6` ;
- `StatusStat` logge que les moves `s_stat`/`s_status` ignorent
  `effect_chance` quand il est entre `1` et `99`.

## Fichiers crees

### `packages/map_battle/lib/src/domain/move/battle_move_secondary_effect_resolver.dart`

Responsabilite :

- recevoir l'etat PSDK, le RNG courant, le lanceur, la cible et la definition de
  move clean ;
- ne rien faire si le move n'a ni statut secondaire ni stage mod ;
- appliquer la chance globale `effectChance` quand elle existe ;
- consommer `generic` pour les chances individuelles quand il n'y a pas de
  chance globale ;
- appliquer les statuts majeurs seulement si la cible n'en a pas deja un ;
- appliquer les stage mods avec clamp `-6..6` ;
- retourner un objet resultat contenant `state`, `rng` et `events`.

Evenements emis :

- `PsdkBattleStatusEvent` pour les statuts ;
- `PsdkBattleStatStageEvent` pour les changements de stages.

## Fichiers modifies

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_move.dart`

Ajouts :

- `PsdkBattleMoveStageMod` avec `stat`, `stages`, `chance` ;
- `effectChance` sur `PsdkBattleMoveData` ;
- `stageMods` sur `PsdkBattleMoveData` ;
- preservation dans `copyWith`.

Validation :

- `effectChance` accepte `1..100` quand il est present ;
- les listes de statuts et stage mods restent exposees en vue immutable.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`

Ajouts :

- `PsdkBattleStatStages` ;
- factory `neutral()` ;
- lecture `valueOf(stat)` ;
- mutation immutable `apply(stat: ..., stages: ...)` ;
- clamp PSDK `-6..6` ;
- transport optionnel depuis `PsdkBattleCombatantSetup` ;
- champ non-null `statStages` dans `PsdkBattleCombatant` ;
- propagation via `copyWith`.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_timeline.dart`

Ajout :

- `PsdkBattleStatStageEvent`.

JSON produit :

```json
{"kind":"stat_stage_change","target":{"bank":1,"position":0},"stat":"defense","amount":-1,"currentStage":-1}
```

### `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`

Ajouts :

- conversion `PsdkBattleStatStageEvent` vers
  `BattleStatStageChangeTimelineEvent` ;
- conversion inverse `BattleStatStageChangeTimelineEvent.toPsdkEvent()`.

Objectif :

- garder le flux runtime clean compatible avec la timeline PSDK interne ;
- laisser le CLI et les tests inspecter les stages sans connaitre les classes
  PSDK.

### `packages/map_battle/lib/src/domain/move/battle_move_data.dart`

Ajouts :

- `effectChance` dans `BattleMoveDefinition` ;
- `BattleStageMod` ;
- mapping `fromPsdk` depuis `PsdkBattleMoveStageMod` ;
- mapping `psdkMove` vers `PsdkBattleMoveStageMod`.

Objectif :

- garder une definition de move clean cote domaine ;
- ne pas forcer les handlers a dependre directement du DTO import PSDK.

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Changement principal :

- `_resolveBasic` calcule les degats comme avant ;
- si les degats sont valides, il remplace la cible, emet `damage`, puis appelle
  `BattleMoveSecondaryEffectResolver` ;
- les evenements sont ordonnes comme PSDK : `animation_cue`, `damage`,
  `status`, `stat_stage_change`.

Important :

- `_resolveStatus` n'a pas ete branche au resolver secondaire ;
- cela respecte la distinction PSDK entre `s_basic` et `s_status`.

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Ajouts :

- scenario `secondary_effect` / `secondary-effect` ;
- fixture Fire vs Grass avec move `flame_bite` ;
- status rider `burn 100%` ;
- stage rider `defense -1 100%` ;
- seeds deterministes pour degats, critique, accuracy et generic.

### `packages/map_battle/lib/map_battle.dart`

Export ajoute :

- `BattleMoveSecondaryEffectResolver` ;
- `BattleMoveSecondaryEffectResult`.

### `packages/map_battle/test/psdk_secondary_effects_test.dart`

Nouveau fichier de tests unitaires.

Couverture :

- une attaque de degats applique un statut majeur apres les degats ;
- un echec de `effectChance` consomme `generic`, conserve les degats et
  n'applique pas le statut ;
- une attaque de degats applique un changement de stage cible apres les degats.

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Ajout :

- test du scenario CLI `secondary_effect`.

Verification :

- `outcome == "ongoing"` ;
- HP adversaire inferieur a `100` ;
- ordre observe : `damage`, `status`, `stat_stage_change`.

## Logique detaillee

### Ordre d'execution

Pour `s_basic`, le chemin clean est maintenant :

1. declaration du move ;
2. accuracy / bypass accuracy ;
3. precheck immunite type ;
4. `animation_cue` ;
5. calcul de degats ;
6. application HP ;
7. riders secondaires ;
8. fin de tour / reponse adverse / outcome.

Les riders secondaires ne partent donc pas si :

- le move miss ;
- la cible est immune ;
- le move ne produit pas de degats ;
- le move a `power <= 0` ou category `status` dans le chemin degats.

### `effectChance`

Quand `effectChance` existe et vaut moins que `100`, le resolver consomme une
fois `rng.generic.nextPercent()`.

- roll reussi : tous les riders secondaires declaratifs du move sont traites ;
- roll rate : aucun rider secondaire n'est applique ;
- les degats restent appliques, comme dans PSDK.

Quand `effectChance` est absent :

- chaque status avec `chance < 100` consomme son propre roll generic ;
- chaque stage mod avec `chance < 100` consomme son propre roll generic ;
- les effets avec chance `100` ne consomment pas de RNG.

### Statuts

Regle implementee :

- un statut majeur est applique seulement si la cible n'a pas deja de statut
  majeur ;
- aucun overwrite n'est fait ;
- l'event `status` est ajoute apres l'event `damage`.

Limite volontaire :

- les immunites de statut, Safeguard, Substitute, abilities, terrain et items ne
  sont pas encore portes.

### Stages

Regle implementee :

- les stages sont stockes par nom de stat ;
- un stage absent vaut `0` ;
- l'application est immutable ;
- le resultat est clamp entre `-6` et `+6` ;
- l'event indique `amount` demande et `currentStage` final.

Limite volontaire :

- les handlers complets PSDK (`Contrary`, `Clear Body`, messages de fail,
  redirections d'effets, Mist, Substitute, etc.) ne sont pas encore portes.

## Sub-agent

Sub-agent Kepler lance en lecture seule.

Ce qu'il a confirme :

- le bon ordre PSDK est bien `deal_damage`, puis `effect_working?`, puis
  `deal_status`, puis `deal_stats` ;
- `Basic#deal_damage` filtre les cibles sans degat reussi ;
- `effectChance` est une chance globale pour `s_basic` ;
- `deal_status` et `deal_stats` passent par le RNG/handlers generiques ;
- il faut eviter de brancher cette logique telle quelle dans `s_status`.

## Commandes de test lancees

Depuis `packages/map_battle` :

```bash
dart test test/psdk_secondary_effects_test.dart
```

Resultat exact :

```text
00:00 +3: All tests passed!
```

```bash
dart test test/psdk_battle_cli_test.dart test/psdk_secondary_effects_test.dart
```

Resultat exact :

```text
00:00 +9: All tests passed!
```

```bash
dart test test/psdk_secondary_effects_test.dart test/psdk_battle_cli_test.dart test/psdk_type_damage_test.dart test/psdk_rng_streams_test.dart test/psdk_engine_smoke_test.dart test/psdk_move_registry_test.dart test/psdk_timeline_test.dart
```

Resultat exact :

```text
00:00 +39: All tests passed!
```

```bash
dart test
```

Resultat exact :

```text
00:00 +278: All tests passed!
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
{"outcome":"victory","turns":1,"playerHp":44,"opponentHp":0,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","moveName":"Scratch"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","damage":18,"remainingHp":0},{"kind":"battle_ended","outcome":"victory"}]}
```

### Scenario `secondary_effect`

Commande :

```bash
dart run bin/psdk_battle_cli.dart --scenario secondary_effect --format json
```

Resultat exact :

```json
{"outcome":"ongoing","turns":1,"playerHp":100,"opponentHp":76,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"flame_bite","moveName":"flame_bite"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"flame_bite"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"flame_bite","damage":24,"remainingHp":76},{"kind":"status","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"flame_bite","status":"burn"},{"kind":"stat_stage_change","target":{"bank":1,"position":0},"stat":"defense","amount":-1,"currentStage":-1},{"kind":"move_declared","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait","moveName":"opponent_wait"},{"kind":"miss","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait"}]}
```

## Limites connues et prochains lots

Pas encore porte :

- `effect_chance == 0` normalise en `100` comme dans PSDK Studio ;
- Magic Coat / Magic Bounce ;
- Serene Grace et modifiers d'effect chance ;
- choix aleatoire multi-statut facon Tri Attack ;
- immunites et protections de statut ;
- handlers complets de changement de stat ;
- self stat moves, self status moves, targets multiples ;
- PP, move history et hooks `on_move_failure` / `post_accuracy_check_effects`.

Prochain lot recommande :

- Lot 12 - Move prevention, PP, historique et hooks minimaux de procedure PSDK.

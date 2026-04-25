# Lot 13 - map_battle PSDK move hooks et prevention

Date: 2026-04-24
Package principal: `packages/map_battle`

## Objectif

Mettre en place un seam extensible inspire de la procedure Ruby Pokemon SDK pour:

- bloquer un move cote utilisateur avant PP/declaration (`move_usable_by_user`);
- notifier les echecs de move (`on_move_failure`);
- exposer les hooks autour de la precision (`pre_accuracy_check`, `post_accuracy_check`, `post_accuracy_check_move`);
- garder le comportement par defaut strictement no-op;
- fournir un scenario CLI testable par sub-agents.

Ce lot ne porte pas encore les abilities/items/statuts complets. Il ajoute la surface propre qui permettra de les brancher sans recasser le runner.

## Audit initial

Sources lues:

- `codex_rule.md`
- `packages/map_battle/pubspec.yaml`
- `packages/map_battle/lib/src/application/battle_engine.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_engine.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/test/psdk_pp_history_test.dart`
- `packages/map_battle/test/psdk_move_procedure_test.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`
- Pokemon SDK Ruby: `pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb`

Ordre PSDK confirme dans `120 Procedure.rb`:

1. `move_usable_by_user`
2. `usage_message`
3. `pre_accuracy_check_effects`
4. `no_target`
5. `proceed_move_accuracy`
6. `proceed_battlers_remap`
7. `accuracy_immunity_test`
8. `post_accuracy_check_effects`
9. `post_accuracy_check_move`
10. animation
11. damage / status / stats / effects
12. move history

## Agents et passes

- Audit / Architecture: sub-agent Ramanujan a confirme les points de branchement engine -> runner -> behavior context -> procedure, et a recommande les exports barrel.
- Implementation: main thread en TDD.
- Tests / Build: main thread avec tests cibles, analyse statique, test complet, CLI compile.
- Critique finale: sub-agent Zeno a trouve deux ecarts PSDK (`preAccuracy` saute sur no-target, `postAccuracy` avant immunite) et un garde CLI trop strict. Les trois points ont ete corriges et couverts.

## Git status

Initial et final: worktree deja sale avant le lot. Je n'ai pas revert les changements hors scope.

Changements hors scope deja presents et ignores:

- `.idea/libraries/Dart_Packages.xml`
- `packages/map_core/**`
- `packages/map_editor/**`
- anciens rapports et fichiers PSDK deja non suivis

Changements du lot 13:

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/application/battle_engine.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_engine.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/lib/src/psdk/psdk_battle.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`
- `packages/map_battle/test/psdk_move_hooks_test.dart`
- `reports/psdk-battle-map-battle-move-hooks-lot13-report.md`

## Implementation

### Hooks domaine

`battle_move_prevention.dart` contient maintenant:

- `BattleMoveProcedureHooks`
- `BattleMoveUserPreventionHook`
- `BattleMoveUserPreventionResult`
- `BattleMoveUserPreventionContext`
- `BattleMoveFailureHook`
- `BattleMoveFailureContext`
- `BattleMoveAccuracyHook`
- `BattleMoveAccuracyHookContext`

Les hooks sont no-op par defaut via `BattleMoveProcedureHooks.none`.

Semantique:

- `userPreventionHooks`: seuls hooks qui peuvent bloquer un move;
- `failureHooks`: notification observationnelle sur `userFainted`, `noTarget`, `unusableByUser`, `accuracy`, `immunity`, `pp`;
- `preAccuracyHooks`: apres declaration / message d'usage, avant no-target;
- `postAccuracyHooks`: apres accuracy + precheck immunite, avec les cibles restantes;
- `postAccuracyMoveHooks`: juste apres `postAccuracyHooks`, avant animation.

### Branchement engine / runner

`BattleEngine` et `PsdkBattleEngine` acceptent:

```dart
BattleMoveProcedureHooks moveProcedureHooks = BattleMoveProcedureHooks.none
```

Le runner applique `userPreventionHooks` apres le check KO user/target, mais avant PP:

- pas de PP depense;
- pas de declaration;
- pas d'accuracy/RNG;
- historique `attempted` conserve;
- timeline `move_failed` avec `unusable_by_user`;
- `failureHooks` notifies.

Le cas PP vide continue d'echouer avant declaration, et notifie aussi `failureHooks`.

### Branchement procedure

`BattleMoveProcedure` accepte `hooks`.

Ordre final:

1. user faint -> failure hook;
2. resolve targets;
3. `move_declared`;
4. `preAccuracyHooks`;
5. no-target -> `move_failed` + failure hook;
6. accuracy resolver;
7. miss -> failure hook accuracy;
8. target precheck / immunite;
9. immunite complete -> failure hook immunity;
10. `postAccuracyHooks`;
11. `postAccuracyMoveHooks`;
12. `animation_cue`;
13. behavior.

`static_basic_move_registry.dart` passe `context.moveProcedureHooks` a `BattleMoveProcedure`.

### Contextes et adapters

`BattleMoveBehaviorContext` et `PsdkBattleMoveContext` transportent maintenant `moveProcedureHooks`, afin que:

- les registries propres puissent l'utiliser;
- les callbacks PSDK custom gardent la meme surface;
- les tests / CLI puissent brancher des hooks sans Flutter.

### Exports

Les nouveaux types sont exportes par:

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/psdk/psdk_battle.dart`

### CLI

Scenario ajoute:

```bash
dart run bin/psdk_battle_cli.dart --scenario prevented --format json
```

Sortie observee:

```json
{"outcome":"ongoing","turns":1,"playerHp":100,"opponentHp":100,"events":[{"kind":"turn_started","turn":1},{"kind":"move_failed","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"blocked_tackle","reason":"unusable_by_user"},{"kind":"move_pp_spent","user":{"bank":1,"position":0},"moveId":"opponent_wait","spent":1,"remainingPp":34},{"kind":"move_declared","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait","moveName":"opponent_wait"},{"kind":"miss","user":{"bank":1,"position":0},"target":{"bank":0,"position":0},"moveId":"opponent_wait"}]}
```

Le garde `mustFinish` du CLI a aussi ete corrige: il ne jette plus si la bataille finit exactement au tour limite, et le message utilise maintenant `config.turnLimit`.

## Tests ajoutes

`test/psdk_move_hooks_test.dart`:

- prevention utilisateur avant PP/declaration/RNG;
- hooks `pre`, `post`, `post_move` sur succes;
- `preAccuracyHooks` execute avant `no_target`;
- `postAccuracyHooks` et `postAccuracyMoveHooks` skips si le precheck retire toutes les cibles;
- `failureHooks` observe PP et accuracy.

`test/psdk_battle_cli_test.dart`:

- scenario `prevented`;
- verification qu'il n'y a ni `move_pp_spent`, ni `move_declared`, ni `animation_cue`, ni `damage` pour `blocked_tackle`.

## Commandes et resultats

Rouge initial:

```bash
cd packages/map_battle
dart test test/psdk_move_hooks_test.dart test/psdk_battle_cli_test.dart
```

Resultat attendu: API hooks absente, scenario CLI inconnu.

Revue Zeno puis rouge ciblant les deux P2:

```bash
dart test test/psdk_move_hooks_test.dart
```

Resultat attendu avant correction:

- `pre:0` absent sur `no_target`;
- `post` appele avant immunite complete.

Vert cible:

```bash
dart test test/psdk_move_hooks_test.dart test/psdk_battle_cli_test.dart
```

Resultat: `+13: All tests passed!`

Filet autour du lot:

```bash
dart test test/psdk_move_hooks_test.dart test/psdk_pp_history_test.dart test/psdk_move_procedure_test.dart test/psdk_timeline_test.dart test/battle_engine_clean_architecture_test.dart test/psdk_battle_cli_test.dart
```

Resultat: `+29: All tests passed!`

Analyse:

```bash
dart analyze
```

Resultat: `No issues found!`

Test complet:

```bash
dart test
```

Resultat: `+288: All tests passed!`

CLI source:

```bash
dart run bin/psdk_battle_cli.dart --scenario prevented --format json
```

Resultat: `blocked_tackle` echoue avec `reason=unusable_by_user`, sans PP/declaration/animation/damage.

CLI compile:

```bash
dart compile exe bin/psdk_battle_cli.dart -o /tmp/pokemon_project_psdk_battle_cli
/tmp/pokemon_project_psdk_battle_cli --scenario prevented --format json
```

Resultat: executable genere et scenario `prevented` OK.

Whitespace:

```bash
git diff --check
```

Resultat: aucune sortie.

## Decisions

- Pas d'event timeline nouveau: `BattleMoveFailedTimelineEvent` suffit.
- Pas de mutation d'etat via hooks pour ce lot: user-prevention peut bloquer, les autres hooks observent.
- Pas d'abilities/items reels dans ce lot: le seam est pret, mais les effets concrets restent dans les prochains lots.
- PP reste dans `BattleTurnRunner`, parce que le lot 12 l'a place la pour garder l'ordre atomique du tour.

## Limites restantes

- Les hooks sont synchrones et peuvent faire des effets de bord externes; si un hook throw, le battle context est restaure, mais pas les effets externes du callback.
- Les hooks ne peuvent pas encore transformer la liste de cibles ni muter proprement l'etat; il faudra un systeme de resultats/effects dedie pour les abilities/items.
- Le runner reste singles-only avec adversaire auto `moveSlot: 0`.
- Les procedures specifiques PSDK (`TwoTurn`, `Pledge`, `DragonDarts`, etc.) ne sont pas encore portees.

## Critique finale

Les trois findings de Zeno ont ete traites:

- `preAccuracy` avant `no_target`: corrige et teste.
- `postAccuracy` apres immunite/precheck: corrige et teste.
- garde CLI `mustFinish`: corrige.

Etat final: le lot est coherent avec l'ordre Ruby PSDK pour les hooks portes dans cette tranche, et le package `map_battle` est vert.

## Prochaine suite conseillee

Lot 14: porter un premier vrai handler d'effet PSDK sur ce seam, par exemple `Protect` ou une prevention simple liee a condition, avec:

- contrat effet/handler separant lecture de contexte et mutation d'etat;
- tests CLI dedies;
- timeline de trigger si necessaire;
- aucun couplage Flutter/Flame.

# PSDK Battle Migration - Lot 8 Move Procedure, Targeting et Accuracy

## Nom exact du lot

Lot 8 - Procedure clean minimale de move, resolution de cible et accuracy.

## Resume executif

Le lot 8 ajoute la premiere vraie tranche du pipeline `Move#proceed` de
Pokemon SDK dans la lane clean `map_battle`.

Le but n'etait pas encore de porter toute la procedure Ruby, mais de retirer la
logique "declare + miss + animation" des handlers `s_basic` / `s_status` et de
la concentrer dans une procedure clean reutilisable :

- resolution de cible `user` et `adjacentFoe`;
- rejet explicite des cibles absentes ou KO;
- bypass d'accuracy pour `accuracy <= 0` et `accuracy >= 100`;
- consommation du stream RNG `moveAccuracy` uniquement quand un jet est utile;
- emission des evenements clean `move_declared`, `move_failed`, `miss` et
  `animation_cue`;
- execution du behavior uniquement apres precheck cible + accuracy.

Le JSON CLI reste stable afin que les sub-agents puissent l'utiliser comme
sonde de comportement de combat.

## Sources PSDK relues

Fichiers Ruby inspectes :

- `pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/104 Chance of Hit.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/110 Target.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/130 Move Prevention.rb`

Constats retenus :

- `Move#proceed` ignore l'action si l'utilisateur est KO.
- La procedure commence par calculer les cibles possibles, puis passe par une
  precheck interne avant l'animation et les effets reels.
- `proceed_internal_precheck` ordonne les etapes : utilisabilite, message,
  pre-accuracy hooks, no-target, accuracy, remap, immunite.
- `proceed_move_accuracy` utilise un stream dedie `move_accuracy_rng`.
- `accuracy <= 0` est une sentinelle de bypass PSDK.
- Le targeting PSDK distingue les targets one-target et no-choice; ce lot ne
  porte volontairement que `user` et `adjacent_foe`.
- Les hooks riches (`Snatch`, `Magic Coat`, `Magic Bounce`, `Protect`,
  abilities, PP, history) restent hors scope de ce lot.

## Fichiers crees

- `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_execution.dart`
- `packages/map_battle/lib/src/domain/move/battle_target_resolver.dart`
- `packages/map_battle/lib/src/domain/move/battle_accuracy_resolver.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- `packages/map_battle/test/psdk_targeting_test.dart`
- `packages/map_battle/test/psdk_accuracy_test.dart`
- `packages/map_battle/test/psdk_move_procedure_test.dart`

## Fichiers modifies

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

- Remplacement de l'ancien debut de handler `_beginMove` par `_prepareMove`.
- `_prepareMove` construit une `BattleMoveProcedureExecution`.
- La procedure clean produit les evenements de declaration, miss/failure et
  animation.
- `s_basic` applique les degats uniquement si
  `BattleMoveProcedureResult.shouldExecuteBehavior == true`.
- `s_status` applique le statut uniquement apres cible + accuracy valides.
- Les evenements clean sont adaptes vers `PsdkBattleEvent` pour maintenir la
  compatibilite avec le runner et le CLI existants.

### `packages/map_battle/lib/map_battle.dart`

Exports ajoutes pour la surface clean du lot :

- `BattleMoveProcedureExecution`;
- `BattleMoveFailureReason`;
- `BattleTargetResolver`;
- `BattleAccuracyResolver`;
- `BattleMoveProcedure`;
- `BattleMoveProcedureResult`.

## Logique mise en place

### `BattleMoveProcedureExecution`

Objet de contexte pour une tentative de move :

- `context` : `BattleMoveBehaviorContext` existant;
- `timeline` : builder clean recevant les evenements de procedure;
- `user` : slot clean du lanceur;
- `move` : `BattleMoveDefinition`;
- `turn` : numero du tour;
- `requestedTarget` : cible demandee, optionnelle;
- `actualTargets` : cibles finales une fois la procedure preparee.

Le nom `BattleMoveProcedureExecution` a ete choisi pour eviter une collision
avec le type legacy `BattleMoveExecution` deja exporte par
`battle_resolution.dart`.

### `BattleTargetResolver`

Resolution portee dans ce lot :

- `PsdkBattleMoveTarget.user` cible le lanceur;
- `PsdkBattleMoveTarget.adjacentFoe` cible la cible demandee si elle existe,
  sinon le slot adverse de meme position.

Le resolver filtre ensuite :

- les slots inexistants;
- les battlers KO.

Une liste vide devient un echec `no_target` dans la procedure.

### `BattleAccuracyResolver`

Regles portees :

- `accuracy <= 0` bypass comme dans PSDK;
- `accuracy >= 100` bypass egalement, pour eviter de consommer du RNG sur un
  move certain;
- sinon un jet par cible via `BattleRngStreams.moveAccuracy.nextPercent()`.

Convention Dart utilisee :

- `nextPercent()` retourne une valeur de `1..100`;
- le hit est `roll.value <= accuracy`.

C'est equivalent au modele PSDK `rand(100) < hit_chance` pour des chances
entieres en pourcentage, tout en gardant le stream clean deja introduit au lot 6.

### `BattleMoveProcedure`

Ordre minimal :

1. refuser si le lanceur est KO;
2. resoudre les cibles;
3. emettre `BattleMoveDeclaredTimelineEvent`;
4. emettre `BattleMoveFailedTimelineEvent(no_target)` si aucune cible valide;
5. resoudre l'accuracy;
6. emettre un `BattleMoveMissedTimelineEvent` par cible ratee;
7. stopper si aucune cible ne touche;
8. stocker `actualTargets`;
9. emettre `BattleAnimationCueTimelineEvent`;
10. retourner `ready` pour laisser `s_basic` / `s_status` appliquer leurs
    effets.

## Tests crees

### `packages/map_battle/test/psdk_targeting_test.dart`

Couverture :

- `adjacentFoe` resout l'adversaire en face;
- la cible demandee est respectee quand elle est valide;
- `user` cible le lanceur;
- cible inexistante ou KO filtree en liste vide;
- snapshot de resultats immuable.

### `packages/map_battle/test/psdk_accuracy_test.dart`

Couverture :

- `accuracy <= 0` bypass sans consommer le stream `moveAccuracy`;
- `accuracy >= 100` bypass sans consommer le stream;
- miss consomme uniquement `moveAccuracy`;
- hit consomme `moveAccuracy` et conserve la cible.

### `packages/map_battle/test/psdk_move_procedure_test.dart`

Couverture :

- un miss n'emet pas `animation_cue`;
- un miss ne consomme pas les streams `moveDamage` ou `generic`;
- une cible absente emet un echec `no_target`;
- un hit emet la declaration puis l'animation;
- le handler `s_basic` n'applique les degats qu'apres procedure valide.

## Sub-agents

Sub-agent Plato lance en lecture/revue de conception.

Recommandations integrees :

- garder le lot 8 minimal : `user`, `adjacentFoe`, no-target, miss, animation;
- ne pas porter encore Snatch, Magic Coat, Protect, PP, history et immunites;
- eviter la collision avec le legacy `BattleMoveExecution`;
- ne pas doubler les evenements entre procedure et handlers;
- garder le JSON CLI stable.

Note Averroes :

- le CLI `psdk_battle_cli.dart` est conserve comme outil de smoke test pour les
  sub-agents qui doivent verifier rapidement un comportement de combat.

## Commandes de test lancees

Depuis `packages/map_battle` :

```bash
dart test test/psdk_move_procedure_test.dart test/psdk_targeting_test.dart test/psdk_accuracy_test.dart
```

Resultat exact :

```text
00:00 +8: All tests passed!
```

```bash
dart test test/psdk_move_procedure_test.dart test/psdk_targeting_test.dart test/psdk_accuracy_test.dart test/psdk_engine_smoke_test.dart test/battle_engine_clean_architecture_test.dart test/psdk_battle_cli_test.dart test/psdk_move_registry_test.dart test/psdk_rng_streams_test.dart test/psdk_timeline_test.dart test/psdk_battle_topology_test.dart test/psdk_battler_state_test.dart
```

Resultat exact :

```text
00:00 +62: All tests passed!
```

```bash
dart test
```

Resultat exact :

```text
00:00 +268: All tests passed!
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

Depuis `packages/map_battle` :

```bash
dart run bin/psdk_battle_cli.dart --format json
```

Resultat exact :

```json
{"outcome":"victory","turns":1,"playerHp":44,"opponentHp":0,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","moveName":"Scratch"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","damage":18,"remainingHp":0},{"kind":"battle_ended","outcome":"victory"}]}
```

```bash
dart run bin/psdk_battle_cli.dart
```

Resultat exact :

```text
outcome=victory turns=1 playerHp=44 opponentHp=0
```

Note CLI :

- l'option valide est `--format json`;
- `--format=json` est refusee par le parseur actuel.

## Limites conservees

- `BattleMoveProcedure` est branche dans les behaviors `s_basic` / `s_status`,
  pas encore directement au niveau du scheduler de tour.
- Les evenements clean sont encore adaptes vers les DTO PSDK pour cohabiter avec
  `PsdkBattleMoveBehaviorRegistry`.
- Les hooks PSDK riches restent a porter : PP, usable-by-user, Snatch, Magic
  Bounce, Magic Coat, Protect, abilities, immunites et historique.
- Les targets multi-battlers ne sont pas encore portees.
- Le calcul de degats reste la version minimale du lot 4/7; type chart, STAB,
  critical et effectiveness sont le prochain gros chantier.

## Prochaines etapes proposees

- Lot 9 : porter le type processing PSDK dans la lane clean.
- Introduire `BattleDamageResolver` clean avant d'etendre `s_basic`.
- Ajouter des tests CLI scenarios pour verifier :
  - miss deterministe;
  - no-target;
  - type immunity;
  - STAB;
  - effectiveness super efficace / pas tres efficace.

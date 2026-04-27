# PSDK Battle Migration - Lot 9 Type Processing et Degats

## Nom exact du lot

Lot 9 - Type processing, STAB, immunites, formule de degats PSDK et critiques
minimaux.

## Resume executif

Le lot 9 remplace le calcul de degats provisoire de `s_basic` par un calcul
clean inspire de Pokemon SDK :

- STAB simple `1.5`;
- effectiveness standard 18 types via le type chart existant;
- immunite type `0` avant animation et avant RNG de degats;
- formule de degats avec paliers `floor`;
- random damage via le stream `moveDamage`;
- critical minimal via le stream `moveCritical` et `criticalRate`;
- extension du DTO `PsdkBattleMoveData` pour transporter `criticalRate`.

Le smoke CLI garde le meme JSON pour le combat fixture actuel.

## Sources PSDK relues

Fichiers Ruby inspectes :

- `pokemonsdk-development/scripts/5 Battle/10 Move/103 Type Processing.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/101 Damage_Calc.rb`
- `pokemonsdk-development/scripts/5 Battle/04 Logic/103 Critical_hit.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/100 Move.rb`
- `pokemonsdk-development/scripts/5 Battle/03 PokemonBattler/003 Statistics.rb`

Constats retenus :

- `calc_stab` retourne `1.5` si le lanceur possede le type du move.
- `type_modifier` multiplie les matchups du move contre les types defensifs.
- Une immunite `0` doit stopper le move avant l'animation.
- Le random de degats utilise un stream dedie `move_damage_rng` sur `85..100`.
- Le critique utilise une table par critical count et un multiplicateur `1.5`.
- Les abilities/items/effects enrichissent fortement ces calculs dans PSDK,
  mais restent hors scope de ce lot.

## Fichiers crees

- `packages/map_battle/lib/src/domain/move/battle_move_type_processor.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_critical_resolver.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- `packages/map_battle/test/psdk_type_damage_test.dart`

## Fichiers modifies

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

- `s_basic` utilise maintenant `BattleMoveDamageCalculator`.
- Le RNG de degats n'est plus consomme directement dans le handler.
- Le calculator consomme `moveCritical` puis `moveDamage` et renvoie le RNG final.
- `_prepareMove` passe une precheck d'immunite type a `BattleMoveProcedure`.
- Les cibles immunisees emettent `move_immune` et ne declenchent pas
  `animation_cue`.

### `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`

- Ajout de `BattleMoveTargetPrecheck`.
- La precheck s'execute apres l'accuracy et avant `animation_cue`.
- Si toutes les cibles sont retirees, la procedure echoue avec
  `BattleMoveFailureReason.immunity`.

### `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart`

- `PsdkBattleImmuneEvent` est converti vers
  `BattleMoveImmuneTimelineEvent`.
- `BattleMoveImmuneTimelineEvent.toPsdkEvent()` renvoie maintenant un event PSDK
  compatible.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_timeline.dart`

- Ajout de `PsdkBattleImmuneEvent`.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_move.dart`

- Ajout de `criticalRate` a `PsdkBattleMoveData`.
- `copyWith` conserve et peut remplacer `criticalRate`.

### `packages/map_battle/lib/src/domain/move/battle_move_data.dart`

- `BattleMoveDefinition.fromPsdk` lit `criticalRate`.
- `BattleMoveDefinition.psdkMove` le reemet vers le DTO PSDK.
- `criticalRate` accepte maintenant `0` pour rester compatible avec la table
  PSDK, meme si les fixtures actuelles utilisent `1+`.

### `packages/map_battle/lib/map_battle.dart`

Exports ajoutes :

- `BattleMoveTypeProcessor`;
- `BattleTypeEffectivenessResult`;
- `BattleMoveCriticalResolver`;
- `BattleMoveCriticalResult`;
- `BattleMoveDamageCalculator`;
- `BattleMoveDamageContext`;
- `BattleMoveDamageResult`;
- `BattleMoveTargetPrecheck`;
- `BattleMoveTargetPrecheckResult`.

## Logique mise en place

### Type processor

`BattleMoveTypeProcessor` reutilise `BattleTypeChart` :

- `resolveStabMultiplier(moveType, userTypes)`;
- `resolveEffectiveness(moveType, targetTypes)`;
- result `BattleTypeEffectivenessResult(multiplier)` avec `isImmune`.

Limite : pas d'Adaptability, Ring Target, Scrappy, Freeze-Dry,
Thousand Arrows, Levitate, Air Balloon, Magnet Rise ou Telekinesis.

### Critical resolver

`BattleMoveCriticalResolver` applique la table minimale :

- `criticalRate 0` : jamais critique;
- `criticalRate 1` : `6250 / 100000`;
- `criticalRate 2` : `12500 / 100000`;
- `criticalRate 3` : `50000 / 100000`;
- `criticalRate >= 4` : critique garanti sans consommer de RNG.

Le multiplicateur est `1.5`. Sniper reste hors scope.

### Damage calculator

`BattleMoveDamageCalculator` :

1. ignore les moves status ou `power <= 0`;
2. calcule STAB et effectiveness;
3. stoppe sans consommer `moveCritical` ni `moveDamage` si immunite;
4. resout le critique;
5. consomme `moveDamage.nextDamagePercent()`;
6. applique la formule :

```text
base = (((((2 * level) ~/ 5 + 2) * power * attack) ~/ defense) ~/ 50) + 2
criticalDamage = floor(base * criticalMultiplier)
randomDamage = floor(criticalDamage * random / 100)
stabDamage = floor(randomDamage * stab)
typedDamage = floor(stabDamage * effectiveness)
```

Le clamp au HP restant reste dans `s_basic`.

## Tests crees

### `packages/map_battle/test/psdk_type_damage_test.dart`

Couverture :

- STAB + super-effective donnent un degat exact attendu :
  - neutral hit : `8`;
  - Fire STAB vs Grass : `24`;
- Electric vs Ground :
  - `damageToOpponent == 0`;
  - `moveDamage` non consomme;
  - event `move_immune`;
  - pas d'`animation_cue`;
  - pas de `damage`;
- `criticalRate` transporte par `PsdkBattleMoveData` peut forcer un critique
  et augmente les degats.

## Sub-agent

Sub-agent Singer lance en lecture seule.

Recommandations integrees :

- creer `BattleMoveTypeProcessor`;
- creer `BattleMoveCriticalResolver`;
- creer `BattleMoveDamageCalculator`;
- eviter de doubler la consommation RNG dans `static_basic_move_registry.dart`;
- faire l'immunite avant animation;
- garder hors scope abilities, items, type3, move type changes et Mod1/2/3.

## Commandes de test lancees

Depuis `packages/map_battle` :

```bash
dart test test/psdk_type_damage_test.dart
```

Resultat exact :

```text
00:00 +3: All tests passed!
```

```bash
dart test test/psdk_type_damage_test.dart test/psdk_move_procedure_test.dart test/psdk_targeting_test.dart test/psdk_accuracy_test.dart test/psdk_engine_smoke_test.dart test/battle_engine_clean_architecture_test.dart test/psdk_battle_cli_test.dart test/psdk_move_registry_test.dart test/psdk_rng_streams_test.dart test/psdk_timeline_test.dart test/psdk_battle_topology_test.dart test/psdk_battler_state_test.dart
```

Resultat exact :

```text
00:00 +65: All tests passed!
```

```bash
dart test
```

Resultat exact :

```text
00:00 +271: All tests passed!
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

## Limites conservees

- Pas d'abilities/items/effects dans le calcul type.
- Pas de `type3`.
- Pas de move type change via effects.
- Pas de stat stages clean dans `PsdkBattleCombatant`.
- Pas de messages d'efficacite/critique dedies dans la timeline.
- `BattleTypeChart` reste le chart existant du package; le lot ne duplique pas
  la table.

## Prochaines etapes proposees

- Lot 10 : effets secondaires de moves (`stageMods`, status riders offensifs,
  chances d'effet) en clean architecture.
- Ajouter des scenarios CLI parametrables pour lancer directement :
  - miss;
  - no-target;
  - immunity;
  - STAB/super-effective;
  - critical.

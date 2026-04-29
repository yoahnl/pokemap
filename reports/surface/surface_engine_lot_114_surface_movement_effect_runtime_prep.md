# Lot 114 — Surface Movement Effect Runtime Prep V0

## 1. Résumé exécutif honnête

Le Lot 114 introduit le contrat porteur minimal côté `map_gameplay` pour les futurs effets de mouvement Surface.

Résultat :

- `GameplayMovementEffect` existe dans `map_gameplay`.
- `GameplayMovementEffectKind` existe avec `slide` et `movementCost`.
- `Moved` porte maintenant un champ optionnel `movementEffect`.
- `movementEffect` vaut `null` par défaut.
- `hazardEffect` reste séparé et intact.
- `stepGameplayWorld` ne produit pas encore de `movementEffect`.
- Aucun comportement `ice` ou `mud` n'est résolu.
- Aucun modèle `map_core`, éditeur Flutter, runtime Flutter, battle ou example n'a été modifié.

Le lot reste donc un siège passager dans le moteur : le transport existe, mais personne ne conduit encore la glissade ou la boue.

## 2. Périmètre

Inclus :

- création d'un modèle pur `GameplayMovementEffect` ;
- création de l'enum pure `GameplayMovementEffectKind` ;
- ajout de `Moved.movementEffect` sans breaking change ;
- export public depuis `packages/map_gameplay/lib/map_gameplay.dart` ;
- tests unitaires du modèle et du portage par `Moved` ;
- tests de non-régression confirmant que `stepGameplayWorld` laisse `movementEffect` à `null`.

Exclus :

- aucun code ice ;
- aucun code mud ;
- aucune glissade ;
- aucun ralentissement appliqué ;
- aucun movement cost appliqué ;
- aucune résolution de zone ice/mud ;
- aucune modification `map_core` ;
- aucune modification `map_editor` ;
- aucune modification `map_runtime` ;
- aucune modification `map_battle` ;
- aucune modification `examples`.

## 3. Gate 0 — status initial

Commande exécutée depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 12
find . -name AGENTS.md -print
```

Sortie complète :

```text
/Users/karim/Project/pokemonProject
main
?? reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md
011b4bc1 fix bridge
09a9b0df lot 112: Ice Mud Movement Semantics Decision
f57ade04 Merge PSDK battle parity work
993b0033 Complete PSDK battle parity batch
a294999b lot 110: Lava Hazard Runtime E2E Closure
af24a783 lot 109: Editor Generate Lava Hazard Zone from Surface
3ef5fc92 lot 108: Hazard Runtime Consumption Prep
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
d9a1a3e3 Port PSDK battle parity moves
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
./AGENTS.md
```

`git diff --stat` initial n'a produit aucune ligne.

Changements préexistants au Gate 0 :

- `reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md` était déjà non suivi au Gate 0.

Observation finale complémentaire :

- le status final ne liste plus ce fichier ;
- `git ls-files reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md` le rapporte comme fichier suivi ;
- il n'a pas été modifié par le Lot 114.

Changements du Lot 114 :

- création de `packages/map_gameplay/lib/src/gameplay_movement_effect.dart` ;
- création de `packages/map_gameplay/test/gameplay_movement_effect_test.dart` ;
- modification de `packages/map_gameplay/lib/src/gameplay_step_result.dart` ;
- modification de `packages/map_gameplay/lib/map_gameplay.dart` ;
- création du présent rapport.

## 4. Context Mode usage

Context Mode a été utilisé pour les audits, les sorties de tests et les sorties potentiellement volumineuses.

Volumes explicitement relevés :

- audit batch : 8 commandes, 781 lignes, 47.1 KB indexés ;
- test rouge TDD initial : 5 sections, 89 lignes, 5.6 KB indexés ;
- runtime surface smoke : 2 sections, 33 lignes, 6.4 KB indexés.

Commande finale demandée :

```bash
ctx stats
```

Résultat exact :

```text
Exit code: 127

stdout:


stderr:
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-nOONfs/script.sh: line 1: ctx: command not found
```

Interprétation : Context Mode était disponible et utilisé pendant le travail, mais l'exécutable shell `ctx` n'était pas disponible pour la commande statistique finale.

## 5. Audit Lot 113

Commande obligatoire exécutée :

```bash
rg -n "Lot 113|GameplayMovementEffect|Moved\.movementEffect|movementEffect|SlideEffect|MovementCostEffect|Surface Movement Effects|ice first|mud first" reports/surface packages/map_gameplay/lib packages/map_gameplay/test
```

Fichier prioritaire lu :

- `reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md`

Findings importants :

- Lot 113 recommande un contrat `GameplayMovementEffect` côté `map_gameplay`.
- Lot 113 recommande `Moved.movementEffect` plutôt qu'un helper séparé ou un nouveau résultat de step.
- Lot 113 tranche pour un seul effet optionnel en V0.
- Lot 113 maintient `ice` et `mud` hors scope tant que le contrat porteur n'existe pas.
- Lot 113 refuse de modifier `map_core` dans ce lot : aucun payload persistant honnête pour ice/mud n'est encore décidé.

Décision appliquée au Lot 114 :

- créer uniquement le modèle porteur côté `map_gameplay` ;
- ne pas résoudre de zone ;
- ne pas modifier `stepGameplayWorld` pour produire un effet.

## 6. Audit GameplayHazardEffect

Commande obligatoire exécutée :

```bash
rg -n "GameplayHazardEffect|hazardEffect|gameplay_hazard|Moved\(" packages/map_gameplay/lib packages/map_gameplay/test
```

Fichiers prioritaires lus :

- `packages/map_gameplay/lib/src/gameplay_hazard.dart`
- `packages/map_gameplay/lib/src/gameplay_step_result.dart`
- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_gameplay/test/hazard_runtime_consumption_test.dart`

Findings importants :

- `GameplayHazardEffect` est un modèle pur dans `map_gameplay`.
- Il est immutable, sans Flutter, sans JSON, sans génération.
- Il porte `zoneId`, `zoneName`, `hazardKind`, `damagePerStep`, `position` et `priority`.
- Il utilise une equality et un `hashCode` manuels.
- `Moved` porte déjà `hazardEffect` comme effet optionnel post-mouvement réussi.
- `stepGameplayWorld` produit `hazardEffect` pour les zones hazard valides, mais ce Lot 114 ne devait pas copier cette résolution pour movement effects.

Ce qui est imité :

- modèle pur ;
- champs orientés zone source et position ;
- equality/hashCode manuels ;
- export public depuis `map_gameplay.dart`.

Ce qui n'est pas copié aveuglément :

- pas de dépendance à `HazardKind` ;
- pas de `damagePerStep` ;
- pas de résolution dans `stepGameplayWorld`.

## 7. Audit GameplayStepResult / Moved

Commande obligatoire exécutée :

```bash
rg -n "sealed class GameplayStepResult|final class Moved|hazardEffect|pathAnimationSignals|Blocked|WarpTriggered|ConnectionTriggered|PlacedElementInteracted" packages/map_gameplay/lib/src/gameplay_step_result.dart packages/map_gameplay/test
```

Findings importants :

- `GameplayStepResult` est une classe sealed avec `world` et `pathAnimationSignals`.
- `Moved` était une classe finale simple :
  - `world` ;
  - `hazardEffect` optionnel ;
  - `pathAnimationSignals`.
- Ajouter `movementEffect` comme named parameter optionnel est non breaking.
- `pathAnimationSignals` reste porté par le super constructor.
- Aucun autre résultat de step n'a besoin de changer.

Décision appliquée :

```dart
final GameplayMovementEffect? movementEffect;
```

dans `Moved`, avec valeur par défaut `null`.

## 8. Audit exports map_gameplay

Commande obligatoire exécutée :

```bash
rg -n "gameplay_hazard|GameplayHazardEffect|gameplay_step_result|Moved|map_gameplay" packages/map_gameplay/lib/map_gameplay.dart packages/map_gameplay/lib/src
```

Findings importants :

- `GameplayHazardEffect` est exporté depuis `packages/map_gameplay/lib/map_gameplay.dart`.
- Les tests et le futur runtime consomment les types publics via le barrel `map_gameplay.dart`.
- `GameplayMovementEffect` doit donc être exporté au même niveau que `GameplayHazardEffect`.

Décision appliquée :

```dart
export 'src/gameplay_movement_effect.dart'
    show GameplayMovementEffect, GameplayMovementEffectKind;
```

## 9. Décision de design GameplayMovementEffect

Design retenu :

- enum `GameplayMovementEffectKind` avec :
  - `slide`
  - `movementCost`
- classe finale `GameplayMovementEffect` ;
- deux factories nommées :
  - `GameplayMovementEffect.slide(...)`
  - `GameplayMovementEffect.movementCost(...)`
- champs communs :
  - `kind`
  - `zoneId`
  - `zoneName`
  - `position`
  - `priority`
- champs spécifiques optionnels :
  - `direction`
  - `movementCost`

Justification :

- les factories évitent un constructeur trop permissif ;
- `slide` exige une `Direction` ;
- `movementCost` exige un entier positif ;
- `zoneId` et `zoneName` non vides évitent des effets impossibles à diagnostiquer plus tard ;
- le modèle reste pur, immutable, sans Flutter, sans JSON et sans génération.

Ce design reste volontairement minimal : il porte l'effet, mais ne décide pas encore comment le runtime enchaîne une glissade ou applique un ralentissement.

## 10. Modèle GameplayMovementEffect

Le modèle est créé dans :

- `packages/map_gameplay/lib/src/gameplay_movement_effect.dart`

Garanties :

- `GameplayMovementEffectKind.slide` existe.
- `GameplayMovementEffectKind.movementCost` existe.
- `GameplayMovementEffect.slide(...)` exige une direction.
- `GameplayMovementEffect.movementCost(...)` exige `movementCost > 0`.
- `zoneId` et `zoneName` vides sont rejetés.
- equality et `hashCode` sont manuels.

## 11. Modification Moved.movementEffect

`Moved` porte maintenant :

```dart
final GameplayMovementEffect? movementEffect;
```

Constructeur :

```dart
const Moved(
  super.world, {
  this.hazardEffect,
  this.movementEffect,
  super.pathAnimationSignals,
});
```

Garanties :

- `movementEffect` vaut `null` par défaut.
- `hazardEffect` reste inchangé.
- `pathAnimationSignals` reste inchangé.
- `Moved` peut porter `hazardEffect` et `movementEffect` simultanément.
- `stepGameplayWorld` ne produit pas encore de `movementEffect`.

## 12. Tests lancés

TDD rouge initial :

```bash
cd packages/map_gameplay && dart test test/gameplay_movement_effect_test.dart --reporter expanded
```

Sortie attendue initiale :

- `GameplayMovementEffect` non défini ;
- named parameter `movementEffect` absent sur `Moved`.

Tests finaux :

```bash
cd packages/map_gameplay && dart test test/gameplay_movement_effect_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_runtime && flutter test test/surface --reporter expanded
```

## 13. Résultats

Lignes finales exactes relevées :

```text
cd packages/map_gameplay && dart test test/gameplay_movement_effect_test.dart --reporter expanded
00:00 +12: All tests passed!

cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
00:00 +8: All tests passed!

cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
00:00 +6: All tests passed!

cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
00:00 +6: All tests passed!

cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
00:00 +12: All tests passed!

cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
00:01 +29: All tests passed!

cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
00:00 +16: All tests passed!

cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
00:00 +12: All tests passed!

cd packages/map_runtime && flutter test test/surface --reporter expanded
00:01 +29: All tests passed!
```

## 14. Analyse lancée

Commande :

```bash
cd packages/map_gameplay && dart analyze lib/src/gameplay_movement_effect.dart lib/src/gameplay_step_result.dart lib/map_gameplay.dart test/gameplay_movement_effect_test.dart
```

## 15. Résultats analyze

Sortie exacte :

```text
Analyzing gameplay_movement_effect.dart, gameplay_step_result.dart, map_gameplay.dart, gameplay_movement_effect_test.dart...
No issues found!
```

## 16. Fichiers créés

Créés par le Lot 114 :

- `packages/map_gameplay/lib/src/gameplay_movement_effect.dart`
- `packages/map_gameplay/test/gameplay_movement_effect_test.dart`
- `reports/surface/surface_engine_lot_114_surface_movement_effect_runtime_prep.md`

Déjà signalé au Gate 0, hors changements Lot 114 :

- `reports/surface/surface_engine_lot_113_surface_movement_effects_model_decision.md`

## 17. Fichiers modifiés

Modifiés par le Lot 114 :

- `packages/map_gameplay/lib/src/gameplay_step_result.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`

## 18. Fichiers supprimés

Aucun fichier supprimé.

## 19. Contenu complet des fichiers créés

### `packages/map_gameplay/lib/src/gameplay_movement_effect.dart`

```dart
import 'package:map_core/map_core.dart';

import 'direction.dart';

enum GameplayMovementEffectKind {
  slide,
  movementCost,
}

final class GameplayMovementEffect {
  factory GameplayMovementEffect.slide({
    required String zoneId,
    required String zoneName,
    required GridPos position,
    required int priority,
    required Direction direction,
  }) {
    _validateZoneIdentity(zoneId: zoneId, zoneName: zoneName);
    return GameplayMovementEffect._(
      kind: GameplayMovementEffectKind.slide,
      zoneId: zoneId,
      zoneName: zoneName,
      position: position,
      priority: priority,
      direction: direction,
    );
  }

  factory GameplayMovementEffect.movementCost({
    required String zoneId,
    required String zoneName,
    required GridPos position,
    required int priority,
    required int movementCost,
  }) {
    _validateZoneIdentity(zoneId: zoneId, zoneName: zoneName);
    if (movementCost <= 0) {
      throw ArgumentError.value(
        movementCost,
        'movementCost',
        'must be positive',
      );
    }
    return GameplayMovementEffect._(
      kind: GameplayMovementEffectKind.movementCost,
      zoneId: zoneId,
      zoneName: zoneName,
      position: position,
      priority: priority,
      movementCost: movementCost,
    );
  }

  const GameplayMovementEffect._({
    required this.kind,
    required this.zoneId,
    required this.zoneName,
    required this.position,
    required this.priority,
    this.direction,
    this.movementCost,
  });

  final GameplayMovementEffectKind kind;
  final String zoneId;
  final String zoneName;
  final GridPos position;
  final int priority;
  final Direction? direction;
  final int? movementCost;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GameplayMovementEffect &&
            other.kind == kind &&
            other.zoneId == zoneId &&
            other.zoneName == zoneName &&
            other.position == position &&
            other.priority == priority &&
            other.direction == direction &&
            other.movementCost == movementCost;
  }

  @override
  int get hashCode {
    return Object.hash(
      kind,
      zoneId,
      zoneName,
      position,
      priority,
      direction,
      movementCost,
    );
  }
}

void _validateZoneIdentity({
  required String zoneId,
  required String zoneName,
}) {
  if (zoneId.trim().isEmpty) {
    throw ArgumentError.value(zoneId, 'zoneId', 'must not be empty');
  }
  if (zoneName.trim().isEmpty) {
    throw ArgumentError.value(zoneName, 'zoneName', 'must not be empty');
  }
}
```

### `packages/map_gameplay/test/gameplay_movement_effect_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('GameplayMovementEffect', () {
    test('slide creates a slide effect with direction', () {
      final effect = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 2, y: 1),
        priority: 4,
        direction: Direction.east,
      );

      expect(effect.kind, GameplayMovementEffectKind.slide);
      expect(effect.zoneId, 'ice-zone');
      expect(effect.zoneName, 'Ice Zone');
      expect(effect.position, const GridPos(x: 2, y: 1));
      expect(effect.priority, 4);
      expect(effect.direction, Direction.east);
      expect(effect.movementCost, isNull);
    });

    test('movementCost creates an effect with a positive cost', () {
      final effect = GameplayMovementEffect.movementCost(
        zoneId: 'mud-zone',
        zoneName: 'Mud Zone',
        position: const GridPos(x: 3, y: 1),
        priority: 2,
        movementCost: 2,
      );

      expect(effect.kind, GameplayMovementEffectKind.movementCost);
      expect(effect.zoneId, 'mud-zone');
      expect(effect.zoneName, 'Mud Zone');
      expect(effect.position, const GridPos(x: 3, y: 1));
      expect(effect.priority, 2);
      expect(effect.direction, isNull);
      expect(effect.movementCost, 2);
    });

    test('movementCost rejects non-positive costs', () {
      expect(
        () => GameplayMovementEffect.movementCost(
          zoneId: 'mud-zone',
          zoneName: 'Mud Zone',
          position: const GridPos(x: 3, y: 1),
          priority: 2,
          movementCost: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty zone identity', () {
      expect(
        () => GameplayMovementEffect.slide(
          zoneId: '',
          zoneName: 'Ice Zone',
          position: const GridPos(x: 2, y: 1),
          priority: 4,
          direction: Direction.east,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => GameplayMovementEffect.slide(
          zoneId: 'ice-zone',
          zoneName: ' ',
          position: const GridPos(x: 2, y: 1),
          priority: 4,
          direction: Direction.east,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('uses value equality and stable hashCode', () {
      final first = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 2, y: 1),
        priority: 4,
        direction: Direction.east,
      );
      final second = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 2, y: 1),
        priority: 4,
        direction: Direction.east,
      );
      final different = GameplayMovementEffect.movementCost(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 2, y: 1),
        priority: 4,
        movementCost: 2,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });
  });

  group('Moved movementEffect', () {
    test('defaults movementEffect to null', () {
      final moved = Moved(_world());

      expect(moved.movementEffect, isNull);
      expect(moved.hazardEffect, isNull);
    });

    test('can carry a slide movement effect', () {
      final effect = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 1, y: 0),
        priority: 1,
        direction: Direction.east,
      );

      final moved = Moved(_world(), movementEffect: effect);

      expect(moved.movementEffect, effect);
      expect(moved.hazardEffect, isNull);
    });

    test('can carry a movement cost effect', () {
      final effect = GameplayMovementEffect.movementCost(
        zoneId: 'mud-zone',
        zoneName: 'Mud Zone',
        position: const GridPos(x: 1, y: 0),
        priority: 1,
        movementCost: 2,
      );

      final moved = Moved(_world(), movementEffect: effect);

      expect(moved.movementEffect, effect);
      expect(moved.hazardEffect, isNull);
    });

    test('can carry hazardEffect and movementEffect together', () {
      const hazard = GameplayHazardEffect(
        zoneId: 'lava-zone',
        zoneName: 'Lava Zone',
        hazardKind: HazardKind.lava,
        damagePerStep: 5,
        position: GridPos(x: 1, y: 0),
        priority: 3,
      );
      final movement = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 1, y: 0),
        priority: 2,
        direction: Direction.east,
      );

      final moved = Moved(
        _world(),
        hazardEffect: hazard,
        movementEffect: movement,
      );

      expect(moved.hazardEffect, hazard);
      expect(moved.movementEffect, movement);
    });

    test('keeps path animation signals intact', () {
      const signal = PathAnimationSignal(
        kind: PathAnimationSignalKind.trigger,
        layerId: 'path-layer',
        presetId: 'ice',
        ruleId: 'step-rule',
        trigger: PathAnimationTriggerType.onStep,
        mode: PathAnimationPlaybackMode.restartOnTrigger,
        sourcePos: GridPos(x: 1, y: 0),
      );
      final movement = GameplayMovementEffect.slide(
        zoneId: 'ice-zone',
        zoneName: 'Ice Zone',
        position: const GridPos(x: 1, y: 0),
        priority: 2,
        direction: Direction.east,
      );

      final moved = Moved(
        _world(),
        movementEffect: movement,
        pathAnimationSignals: const [signal],
      );

      expect(moved.movementEffect, movement);
      expect(moved.pathAnimationSignals, const [signal]);
    });

    test('stepGameplayWorld does not produce a movementEffect yet', () {
      final result = stepGameplayWorld(
        _world(),
        const MoveIntent(Direction.east),
      );

      expect(result, isA<Moved>());
      final moved = result as Moved;
      expect(moved.world.player.pos, const GridPos(x: 1, y: 0));
      expect(moved.movementEffect, isNull);
    });

    test('stepGameplayWorld keeps lava hazard separate from movementEffect',
        () {
      final result = stepGameplayWorld(
        _world(
          gameplayZones: const [
            MapGameplayZone(
              id: 'lava-zone',
              name: 'Lava Zone',
              kind: GameplayZoneKind.hazard,
              area: MapRect(
                pos: GridPos(x: 1, y: 0),
                size: GridSize(width: 1, height: 1),
              ),
              priority: 3,
              hazard: HazardZonePayload(
                hazardKind: HazardKind.lava,
                damagePerStep: 5,
              ),
            ),
          ],
        ),
        const MoveIntent(Direction.east),
      );

      expect(result, isA<Moved>());
      final moved = result as Moved;
      expect(moved.hazardEffect, isNotNull);
      expect(moved.hazardEffect!.hazardKind, HazardKind.lava);
      expect(moved.movementEffect, isNull);
    });
  });
}

GameplayWorldState _world({
  List<MapGameplayZone> gameplayZones = const [],
}) {
  return GameplayWorldState.initial(
    map: MapData(
      id: 'movement_effect_map',
      name: 'Movement Effect Map',
      size: const GridSize(width: 3, height: 1),
      layers: const [
        MapLayer.tile(
          id: 'tile',
          name: 'Tile',
          tiles: [0, 0, 0],
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: [false, false, false],
        ),
      ],
      gameplayZones: gameplayZones,
    ),
    playerPos: const GridPos(x: 0, y: 0),
  );
}
```

### `reports/surface/surface_engine_lot_114_surface_movement_effect_runtime_prep.md`

Le rapport actuel n'est pas recopié dans lui-même, conformément à l'exception explicite du prompt.

## 20. Contenu complet des fichiers modifiés

### `packages/map_gameplay/lib/src/gameplay_step_result.dart`

```dart
import 'package:map_core/map_core.dart';

import 'gameplay_hazard.dart';
import 'gameplay_movement_effect.dart';
import 'movement_block_reason.dart';
import 'gameplay_world_state.dart';

class TriggeredWarp {
  const TriggeredWarp({
    required this.warpId,
    required this.targetMapId,
    required this.targetPos,
    required this.triggerMode,
  });

  final String warpId;
  final String targetMapId;
  final GridPos targetPos;
  final MapWarpTriggerMode triggerMode;
}

class TriggeredConnection {
  const TriggeredConnection({
    required this.direction,
    required this.targetMapId,
    required this.offset,
    required this.sourcePos,
  });

  final MapConnectionDirection direction;
  final String targetMapId;
  final int offset;
  final GridPos sourcePos;
}

enum PathAnimationSignalKind {
  trigger,
  setActive,
}

class PathAnimationSignal {
  const PathAnimationSignal({
    required this.kind,
    required this.layerId,
    required this.presetId,
    required this.ruleId,
    required this.trigger,
    required this.mode,
    required this.sourcePos,
    this.scope = PathAnimationActivationScope.wholeLayer,
    this.active,
  });

  final PathAnimationSignalKind kind;
  final String layerId;
  final String presetId;
  final String ruleId;
  final PathAnimationTriggerType trigger;
  final PathAnimationPlaybackMode mode;
  final GridPos sourcePos;
  final PathAnimationActivationScope scope;
  final bool? active;
}

sealed class GameplayStepResult {
  const GameplayStepResult(
    this.world, {
    this.pathAnimationSignals = const <PathAnimationSignal>[],
  });
  final GameplayWorldState world;
  final List<PathAnimationSignal> pathAnimationSignals;
}

final class Moved extends GameplayStepResult {
  const Moved(
    super.world, {
    this.hazardEffect,
    this.movementEffect,
    super.pathAnimationSignals,
  });

  final GameplayHazardEffect? hazardEffect;
  final GameplayMovementEffect? movementEffect;
}

final class Blocked extends GameplayStepResult {
  const Blocked(
    super.world, {
    this.reason = GameplayMovementBlockReason.solid,
    super.pathAnimationSignals,
  });

  final GameplayMovementBlockReason reason;
}

final class WarpTriggered extends GameplayStepResult {
  const WarpTriggered(
    super.world,
    this.warp, {
    super.pathAnimationSignals,
  });
  final TriggeredWarp warp;
}

final class ConnectionTriggered extends GameplayStepResult {
  const ConnectionTriggered(
    super.world,
    this.connection, {
    super.pathAnimationSignals,
  });
  final TriggeredConnection connection;
}

final class NothingToInteract extends GameplayStepResult {
  const NothingToInteract(
    super.world, {
    super.pathAnimationSignals,
  });
}

final class NpcInteracted extends GameplayStepResult {
  const NpcInteracted(
    super.world,
    this.entity, {
    super.pathAnimationSignals,
  });
  final MapEntity entity;
}

final class SignInteracted extends GameplayStepResult {
  const SignInteracted(
    super.world,
    this.entity, {
    super.pathAnimationSignals,
  });
  final MapEntity entity;
}

final class ItemInteracted extends GameplayStepResult {
  const ItemInteracted(
    super.world,
    this.entity, {
    super.pathAnimationSignals,
  });
  final MapEntity entity;
}

final class EntityInteracted extends GameplayStepResult {
  const EntityInteracted(
    super.world,
    this.entity, {
    super.pathAnimationSignals,
  });
  final MapEntity entity;
}

final class PlacedElementInteracted extends GameplayStepResult {
  const PlacedElementInteracted(
    super.world,
    this.element,
    this.behavior,
    this.trigger, {
    super.pathAnimationSignals,
  });
  final MapPlacedElement element;
  final MapPlacedElementBehavior behavior;
  final MapPlacedElementTriggerType trigger;
}

final class MapEventInteracted extends GameplayStepResult {
  const MapEventInteracted(
    super.world,
    this.event,
    this.page, {
    super.pathAnimationSignals,
  });
  final MapEventDefinition event;
  final ActiveEventPage page;
}
```

### `packages/map_gameplay/lib/map_gameplay.dart`

```dart
library map_gameplay;

export 'src/direction.dart' show Direction, DirectionX, EntityFacingX;
export 'src/gameplay_exceptions.dart' show GameplaySpawnResolutionException;
export 'src/player_spawn_resolver.dart' show resolveInitialPlayerSpawn;
export 'src/gameplay_intent.dart'
    show GameplayIntent, MoveIntent, InteractIntent;
export 'src/movement_block_reason.dart' show GameplayMovementBlockReason;
export 'src/gameplay_player_state.dart' show GameplayPlayerState;
export 'src/gameplay_encounter.dart'
    show
        defaultEncounterChancePerStep,
        GameplayEncounterPolicy,
        GameplayEncounterCheckStatus,
        GameplayEncounter,
        GameplayEncounterCheckResult,
        checkEncounterAtPlayerPosition;
export 'src/gameplay_connection.dart' show resolveConnectedMapTargetPos;
export 'src/gameplay_hazard.dart' show GameplayHazardEffect;
export 'src/gameplay_movement_effect.dart'
    show GameplayMovementEffect, GameplayMovementEffectKind;
export 'src/grid_pathfinder.dart'
    show GridCellPassability, GridPathfindingResult, GridPathfinder;
export 'src/gameplay_step.dart' show stepGameplayWorld;
export 'src/gameplay_step_result.dart'
    show
        GameplayStepResult,
        Moved,
        Blocked,
        WarpTriggered,
        ConnectionTriggered,
        TriggeredWarp,
        TriggeredConnection,
        PathAnimationSignalKind,
        PathAnimationSignal,
        NothingToInteract,
        NpcInteracted,
        SignInteracted,
        ItemInteracted,
        EntityInteracted,
        PlacedElementInteracted,
        MapEventInteracted;
export 'src/gameplay_world_state.dart'
    show GameplayWorldState, NpcMapPresencePredicate;
export 'src/surf_evaluation.dart'
    show
        SurfAttemptEvaluation,
        NotWater,
        AlreadySurfing,
        MissingSurfCapablePokemon,
        SurfNotUnlocked,
        CanPromptSurf,
        evaluateSurfAttempt,
        partyHasUsableFieldMove;

// Line of Sight detection
export 'src/los_detection.dart' show checkLineOfSight;

// Script system exports
export 'src/script_condition_evaluator.dart'
    show ScriptConditionEvaluator, ScriptEvaluationContext;
export 'src/event_page_resolver.dart' show EventPageResolver;
export 'src/game_state_mutations.dart' show GameStateMutations;
```

## 21. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Statut final complet :

```text
 M packages/map_gameplay/lib/map_gameplay.dart
 M packages/map_gameplay/lib/src/gameplay_step_result.dart
?? packages/map_gameplay/lib/src/gameplay_movement_effect.dart
?? packages/map_gameplay/test/gameplay_movement_effect_test.dart
?? reports/surface/surface_engine_lot_114_surface_movement_effect_runtime_prep.md
```

Commande :

```bash
git diff --stat
```

Diff stat final complet pour les fichiers suivis :

```text
 packages/map_gameplay/lib/map_gameplay.dart             | 2 ++
 packages/map_gameplay/lib/src/gameplay_step_result.dart | 3 +++
 2 files changed, 5 insertions(+)
```

Note : les fichiers non suivis ne sont pas inclus dans `git diff --stat`.

Contrôle additionnel :

```bash
git diff --check
```

Sortie : aucune ligne.

## 22. Périmètre explicitement non touché

Confirmations :

- map_core production non modifié ;
- map_editor production non modifié ;
- map_runtime production non modifié ;
- map_battle non modifié ;
- examples non modifié ;
- MapData modèle non modifié ;
- MapGameplayZone modèle non modifié ;
- MovementZonePayload non modifié ;
- MovementMode non modifié ;
- HazardZonePayload non modifié ;
- HazardKind non modifié ;
- SpecialZonePayload non modifié ;
- SurfaceLayer non modifié ;
- SurfaceCellPlacement non modifié ;
- ProjectManifest non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucune action editor nouvelle ;
- aucun dialog editor nouveau ;
- aucune glissade codée ;
- aucun ralentissement codé ;
- aucun movement cost appliqué ;
- aucune modification PlayableMapGame ;
- aucune migration legacy ;
- aucun filtre surfacePresetId dans MapGameplayZone.

## 23. ctx stats

Commande exécutée :

```bash
ctx stats
```

Résultat :

```text
Exit code: 127

stdout:


stderr:
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-nOONfs/script.sh: line 1: ctx: command not found
```

Résumé compact :

- Context Mode utilisé pour les audits et sorties longues.
- Volumes explicitement relevés : 47.1 KB + 5.6 KB + 6.4 KB indexés sur les plus gros blocs mesurés.
- La commande statistique shell finale n'était pas disponible dans l'environnement.

## 24. Limites restantes

- `GameplayMovementEffect` n'est pas encore produit par `stepGameplayWorld`.
- Aucun modèle persistant `map_core` ne représente encore honnêtement ice ou mud.
- `ice` n'a pas encore de résolution de glissade.
- `mud` n'a pas encore de movement cost appliqué.
- `PlayableMapGame` ne consomme pas encore `movementEffect`.
- La priorité réelle des futurs movement effects reste à implémenter.
- Les interactions futures avec warp, connection, collision, input et animation restent à décider dans les lots suivants.

## 25. Auto-critique

- Est-ce que GameplayMovementEffect existe ? Oui.
- Est-ce que GameplayMovementEffectKind existe ? Oui.
- Est-ce que Moved.movementEffect existe ? Oui.
- Est-ce que movementEffect est null par défaut ? Oui.
- Est-ce que hazardEffect reste intact ? Oui.
- Est-ce que Moved peut porter hazardEffect et movementEffect ensemble ? Oui.
- Est-ce que stepGameplayWorld ne produit pas encore de movementEffect ? Oui.
- Est-ce qu'aucun ice n'est codé ? Oui.
- Est-ce qu'aucun mud n'est codé ? Oui.
- Est-ce qu'aucun map_core n'est modifié ? Oui.
- Est-ce qu'aucun editor/runtime Flutter n'est modifié ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les régressions passent ? Oui.
- Est-ce que l'analyse ciblée passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec échec shell documenté.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui, sauf le rapport lui-même par exception explicite.
- Est-ce qu'un Lot 114-bis est nécessaire ? Non. Le contrat porteur est en place, testé, et le scope interdit ice/mud reste respecté.

## 26. Regard critique sur le prompt

Le prompt était bien borné : il autorisait exactement `map_gameplay` et interdisait explicitement la résolution `ice/mud`, ce qui évite de transformer un lot de contrat en début de moteur de glissade.

Le point le plus délicat était la validation du modèle. La validation minimale retenue (`zoneId`, `zoneName`, `movementCost > 0`) est utile sans surcharger le contrat. Une validation plus riche devra attendre le moment où les zones réelles seront résolues.

La prochaine étape logique reste un lot de préparation runtime ciblé sur la production réelle de `movementEffect`, probablement d'abord pour `ice`, mais seulement après décision précise du modèle persistant ou de la source gameplay utilisée.

# Lot 108 — Hazard Runtime Consumption Prep V0

## 1. Résumé exécutif honnête

Lot 108 ajoute la consommation gameplay minimale des zones `MapGameplayZone(kind: hazard)` côté `map_gameplay`.

Le choix retenu est l'option A : étendre `Moved` avec un champ optionnel `hazardEffect`. Après un mouvement réussi vers une cellule couverte par une zone hazard dommageable, `stepGameplayWorld(...)` expose un `GameplayHazardEffect` contenant l'id de zone, le nom, le `HazardKind`, `damagePerStep`, la position finale et la priorité. Aucun dégât n'est appliqué aux PV, à la party ou au `GameState`.

Le lot reste volontairement borné : aucun editor lava, aucun runtime Flutter, aucun modèle `map_core`, aucun JSON, aucun generated/build_runner.

## 2. Périmètre

Inclus :

- contrat pur `GameplayHazardEffect` dans `map_gameplay` ;
- champ optionnel `Moved.hazardEffect` ;
- résolution de la zone hazard sur la position finale d'un mouvement réussi ;
- tests ciblés hazard, priorité, water-before-hazard et génération depuis Surface plan ;
- rapport Lot 108.

Exclus :

- action editor `Lave dangereuse` ;
- `SurfaceBehaviorActionMenu` ;
- `map_runtime` / `PlayableMapGame` ;
- application réelle de dégâts aux HP / party / `GameState` ;
- modifications des modèles `map_core`.

## 3. Gate 0 — status initial

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
(no output)

git diff --stat
(no output)

git log --oneline -n 10
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
888f1339 fix: resolve RenderFlex overflow errors in layers and surface panels
58ab7070 lot 100/95: Editor Generate Gameplay Zone from Surface
15fa925c lot 99/95: Surface Gameplay - Surface to Gameplay Zone Coverage Diagnostics
70b0f90d lot 98/95: Surface Gameplay - Surface to Gameplay Zone Generation Plan

find . -name AGENTS.md -print
./AGENTS.md
```

Changements préexistants : aucun. Le worktree était propre avant Lot 108.

## 4. Context Mode usage

Context Mode a été utilisé agressivement pour :

- Gate 0 ;
- audit Lot 107 ;
- audit `GameplayStepResult` / `stepGameplayWorld` ;
- audit `GameplayWorldState` / zones / priorité ;
- audit `GameState` / HP / party ;
- audit tests hazard existants ;
- test rouge ;
- tests et analyse post-format ;
- diff / scope review.

Commandes d'audit lancées :

```text
rg -n "Lot 107|HazardZonePayload|HazardKind.lava|damagePerStep|hazard runtime|GameplayZoneKind.hazard|Lave dangereuse" reports/surface packages/map_core/lib packages/map_gameplay/lib packages/map_runtime/lib
rg -n "sealed|class .*Step|GameplayStepResult|Moved|Blocked|WarpTriggered|ConnectionTriggered|PlacedElementInteracted|MapEventInteracted|stepGameplayWorld|_resolveMove|MoveIntent|InteractIntent" packages/map_gameplay/lib packages/map_gameplay/test
rg -n "GameplayWorldState|findGameplayZoneAtPos|findAllGameplayZonesAtPos|gameplayZones|priority|GameplayZoneKind|waterCell|isWaterCell|movementZone|hazard" packages/map_gameplay/lib packages/map_core/lib packages/map_gameplay/test packages/map_core/test
rg -n "GameState|party|hp|currentHp|maxHp|damage|apply.*damage|Pokemon|Player|progression|save" packages/map_core/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_core/test packages/map_gameplay/test
rg -n "hazard|HazardKind|damagePerStep|lava|swamp|pitfall|GameplayZoneKind.hazard|stepGameplayWorld|surface_generated_gameplay_zone_bridge" packages/map_core/test packages/map_gameplay/test packages/map_editor/test packages/map_runtime/test
```

## 5. Audit Lot 107

Findings importants :

- Lot 107 a décidé le payload lava V0 : `HazardZonePayload(hazardKind: HazardKind.lava, damagePerStep: 5)`.
- `HazardZonePayload`, `HazardKind.lava` et `damagePerStep` existent déjà côté `map_core`.
- `createSurfaceGameplayZoneGenerationPlan(...)` sait déjà produire des zones `GameplayZoneKind.hazard` via `SurfaceGameplayZoneBehaviorDraft.hazard(...)`.
- L'action editor lava est bloquée tant que `map_gameplay` ne consomme pas les hazards overworld.
- Lot 108 doit débloquer cette consommation minimale, pas coder l'éditeur.

## 6. Audit GameplayStepResult / stepGameplayWorld

`GameplayStepResult` contient déjà `Moved`, `Blocked`, `WarpTriggered`, `ConnectionTriggered`, les interactions et les signaux d'animation path.

`Moved` était une classe manuelle simple :

```text
final class Moved extends GameplayStepResult {
  const Moved(super.world, { super.pathAnimationSignals });
}
```

`stepGameplayWorld(...)` résout `MoveIntent` dans `_resolveMove(...)`. Les blocs existants se produisent avant le retour `Moved` : out-of-bounds, waterRequiresSurf, collisions pixel, bump warp, comportements de placed elements, warp-on-enter. La position finale est disponible via `movedWorld.player.pos`.

Conclusion : ajouter `hazardEffect` optionnel à `Moved` est propre et borné. Cela expose l'effet au moment exact du mouvement réussi sans créer un nouveau type de résultat ni casser les appels existants.

## 7. Audit GameplayWorldState / zones

`GameplayWorldState` construit déjà un cache water depuis :

- legacy `PathLayer` water ;
- `MapGameplayZone(kind: movement)` avec `MovementMode.surf`.

Aucun cache hazard n'existait. Les opérations `map_core` contiennent `findGameplayZoneAtPos(...)` et `findAllGameplayZonesAtPos(...)`. La règle de priorité existante prend la priorité la plus haute, avec la dernière zone gagnante en cas d'égalité dans `findGameplayZoneAtPos`.

Lot 108 s'aligne sur cette règle : il scanne `world.map.gameplayZones`, filtre `GameplayZoneKind.hazard`, ignore les payloads absents ou `damagePerStep <= 0`, puis garde la zone de plus haute priorité avec égalité résolue par la dernière zone rencontrée.

## 8. Audit GameState / HP / party

L'audit montre que `GameplayWorldState` ne transporte pas un `GameState` complet de combat/progression. `evaluateSurfAttempt(...)` reçoit un `GameState` séparé. Les PV / party vivent hors du contrat minimal de `stepGameplayWorld`.

Décision : V0 ne mute pas les HP, la party ni `GameState`. Il expose seulement un effet observable que le runtime ou un lot futur pourra brancher proprement.

## 9. Décision de design hazard V0

Décision : option A, `Moved.hazardEffect` optionnel.

Raisons :

- `Moved` est simple à étendre sans rendre les appels existants invalides ;
- le hazard est attaché au résultat du mouvement qui l'a déclenché ;
- le futur runtime peut lire l'effet sans refaire une résolution parallèle ;
- la décision reste bornée à `map_gameplay`.

Option B, helper pur seul, a été rejetée pour V0 parce qu'elle aurait laissé `stepGameplayWorld(...)` ignorant du hazard, alors que le lot demande une consommation gameplay minimale.

## 10. Contrat GameplayHazardEffect

Nouveau type pur : `GameplayHazardEffect`.

Champs :

- `zoneId` ;
- `zoneName` ;
- `hazardKind` ;
- `damagePerStep` ;
- `position` ;
- `priority`.

Contraintes respectées :

- immutable ;
- égalité de valeur manuelle ;
- dépend uniquement de `map_core` ;
- pas de Flutter ;
- pas de JSON ;
- pas de mutation de `GameState`.

## 11. Déclenchement hazard

Le hazard est résolu uniquement au moment du retour `Moved`, donc après un mouvement réussi vers la position finale.

Ne déclenche pas :

- mouvement bloqué ;
- collision solide ;
- waterRequiresSurf en walking ;
- interaction sans mouvement ;
- warp/connection qui retourne un résultat autre que `Moved`.

Limite volontaire : si un mouvement aboutit à `PlacedElementInteracted`, aucun `hazardEffect` n'est exposé dans ce résultat V0. Le lot reste centré sur le contrat minimal `Moved`.

## 12. Priorité / résolution des zones

La zone hazard retenue est celle qui couvre la position finale et qui a la priorité la plus élevée. En cas d'égalité, le scan garde la dernière zone rencontrée, comme `findGameplayZoneAtPos(...)` côté `map_core`.

Test ajouté : deux hazards chevauchants, poison priorité basse et lava priorité haute ; l'effet vient bien de la zone lava haute priorité.

## 13. damagePerStep V0

`damagePerStep` est exposé tel quel dans `GameplayHazardEffect`.

Si `damagePerStep <= 0`, aucun effet dommageable n'est produit. Cela évite un hazard lava vide qui aurait l'air actif sans effet exploitable. Aucun dégât n'est appliqué à la party en V0.

## 14. Tests lancés

Test rouge TDD :

```text
cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded

00:00 +0: loading test/hazard_runtime_consumption_test.dart
00:00 +0 -1: loading test/hazard_runtime_consumption_test.dart [E]
  Failed to load "test/hazard_runtime_consumption_test.dart":
  test/hazard_runtime_consumption_test.dart:15:20: Error: The getter 'hazardEffect' isn't defined for the type 'Moved'.
   - 'Moved' is from 'package:map_gameplay/src/gameplay_step_result.dart' ('lib/src/gameplay_step_result.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'hazardEffect'.
        expect(moved.hazardEffect, isNull);
                     ^^^^^^^^^^^^
  test/hazard_runtime_consumption_test.dart:41:40: Error: The getter 'hazardEffect' isn't defined for the type 'Moved'.
   - 'Moved' is from 'package:map_gameplay/src/gameplay_step_result.dart' ('lib/src/gameplay_step_result.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'hazardEffect'.
        final effect = (result as Moved).hazardEffect;
                                         ^^^^^^^^^^^^
  test/hazard_runtime_consumption_test.dart:146:40: Error: The getter 'hazardEffect' isn't defined for the type 'Moved'.
   - 'Moved' is from 'package:map_gameplay/src/gameplay_step_result.dart' ('lib/src/gameplay_step_result.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'hazardEffect'.
        final effect = (result as Moved).hazardEffect;
                                         ^^^^^^^^^^^^
  test/hazard_runtime_consumption_test.dart:188:40: Error: The getter 'hazardEffect' isn't defined for the type 'Moved'.
   - 'Moved' is from 'package:map_gameplay/src/gameplay_step_result.dart' ('lib/src/gameplay_step_result.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'hazardEffect'.
        final effect = (result as Moved).hazardEffect;
                                         ^^^^^^^^^^^^
  test/hazard_runtime_consumption_test.dart:234:40: Error: The getter 'hazardEffect' isn't defined for the type 'Moved'.
   - 'Moved' is from 'package:map_gameplay/src/gameplay_step_result.dart' ('lib/src/gameplay_step_result.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'hazardEffect'.
        final effect = (result as Moved).hazardEffect;
                                         ^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.

Failing tests:
  test/hazard_runtime_consumption_test.dart: loading test/hazard_runtime_consumption_test.dart
```

Tests post-format lancés :

```text
cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
00:00 +7: All tests passed!

cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
00:00 +3: All tests passed!

cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
00:00 +6: All tests passed!

cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
00:00 +12: All tests passed!

cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
00:00 +17: All tests passed!

cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
00:00 +16: All tests passed!

cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
00:00 +12: All tests passed!
```

Commande de format :

```text
dart format packages/map_gameplay/lib/src/gameplay_step.dart packages/map_gameplay/lib/src/gameplay_step_result.dart packages/map_gameplay/lib/src/gameplay_hazard.dart packages/map_gameplay/lib/map_gameplay.dart packages/map_gameplay/test/hazard_runtime_consumption_test.dart
Formatted packages/map_gameplay/lib/src/gameplay_step.dart
Formatted packages/map_gameplay/test/hazard_runtime_consumption_test.dart
Formatted 5 files (2 changed) in 0.01 seconds.
```

## 15. Résultats

Tous les tests demandés passent après format :

- hazard runtime consumption : 7 tests ;
- surface generated gameplay zone bridge : 3 tests ;
- movement mode water : 6 tests ;
- surf evaluation : 12 tests ;
- surface painter action/menu/editor bridge : 17 tests ;
- map_core generation plan : 16 tests ;
- map_core generation assessment : 12 tests.

## 16. Analyse lancée

```text
cd packages/map_gameplay && dart analyze lib/src/gameplay_step.dart lib/src/gameplay_step_result.dart lib/src/gameplay_hazard.dart lib/map_gameplay.dart test/hazard_runtime_consumption_test.dart
Analyzing gameplay_step.dart, gameplay_step_result.dart, gameplay_hazard.dart, map_gameplay.dart, hazard_runtime_consumption_test.dart...
No issues found!
```

## 17. Résultats analyze

Analyse ciblée clean : `No issues found!`.

Aucune analyse globale inutile lancée ; seuls les fichiers Dart `map_gameplay` créés/modifiés ont été analysés.

## 18. Fichiers créés

- `packages/map_gameplay/lib/src/gameplay_hazard.dart`
- `packages/map_gameplay/test/hazard_runtime_consumption_test.dart`
- `reports/surface/surface_engine_lot_108_hazard_runtime_consumption_prep.md`

## 19. Fichiers modifiés

- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_gameplay/lib/src/gameplay_step_result.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`

## 20. Fichiers supprimés

Aucun fichier supprimé.

## 21. Contenu complet des fichiers créés

Le rapport `reports/surface/surface_engine_lot_108_hazard_runtime_consumption_prep.md` est le présent fichier ; son contenu n'est pas recopié récursivement conformément à l'exception demandée.

### `packages/map_gameplay/lib/src/gameplay_hazard.dart`

```dart
import 'package:map_core/map_core.dart';

final class GameplayHazardEffect {
  const GameplayHazardEffect({
    required this.zoneId,
    required this.zoneName,
    required this.hazardKind,
    required this.damagePerStep,
    required this.position,
    required this.priority,
  });

  final String zoneId;
  final String zoneName;
  final HazardKind hazardKind;
  final int damagePerStep;
  final GridPos position;
  final int priority;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GameplayHazardEffect &&
            other.zoneId == zoneId &&
            other.zoneName == zoneName &&
            other.hazardKind == hazardKind &&
            other.damagePerStep == damagePerStep &&
            other.position == position &&
            other.priority == priority;
  }

  @override
  int get hashCode {
    return Object.hash(
      zoneId,
      zoneName,
      hazardKind,
      damagePerStep,
      position,
      priority,
    );
  }
}

```
### `packages/map_gameplay/test/hazard_runtime_consumption_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('hazard runtime consumption', () {
    test('normal movement has no hazard effect', () {
      final world = _world();

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Moved>());
      final moved = result as Moved;
      expect(moved.world.player.pos, const GridPos(x: 1, y: 0));
      expect(moved.hazardEffect, isNull);
    });

    test('lava hazard produces an observable effect after movement', () {
      final world = _world(
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
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Moved>());
      final effect = (result as Moved).hazardEffect;
      expect(effect, isNotNull);
      expect(effect!.zoneId, 'lava-zone');
      expect(effect.zoneName, 'Lava Zone');
      expect(effect.hazardKind, HazardKind.lava);
      expect(effect.damagePerStep, 5);
      expect(effect.position, const GridPos(x: 1, y: 0));
      expect(effect.priority, 3);
    });

    test('blocked movement does not trigger hazard effect', () {
      final world = _world(
        includeCollisionAtTarget: true,
        gameplayZones: const [
          MapGameplayZone(
            id: 'solid-lava',
            kind: GameplayZoneKind.hazard,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            hazard: HazardZonePayload(
              hazardKind: HazardKind.lava,
              damagePerStep: 5,
            ),
          ),
        ],
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      expect((result as Blocked).reason, GameplayMovementBlockReason.solid);
      expect(result.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('waterRequiresSurf blocks before hazard in walking mode', () {
      final world = _world(
        gameplayZones: const [
          MapGameplayZone(
            id: 'surf-zone',
            kind: GameplayZoneKind.movement,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            movement: MovementZonePayload(requiredMode: MovementMode.surf),
          ),
          MapGameplayZone(
            id: 'lava-under-water',
            kind: GameplayZoneKind.hazard,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            hazard: HazardZonePayload(
              hazardKind: HazardKind.lava,
              damagePerStep: 5,
            ),
          ),
        ],
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      expect(
        (result as Blocked).reason,
        GameplayMovementBlockReason.waterRequiresSurf,
      );
      expect(result.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('surfing into water hazard produces a hazard effect', () {
      final world = _world(
        playerMovementMode: MovementMode.surf,
        gameplayZones: const [
          MapGameplayZone(
            id: 'surf-zone',
            kind: GameplayZoneKind.movement,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            movement: MovementZonePayload(requiredMode: MovementMode.surf),
          ),
          MapGameplayZone(
            id: 'lava-under-water',
            kind: GameplayZoneKind.hazard,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            priority: 2,
            hazard: HazardZonePayload(
              hazardKind: HazardKind.lava,
              damagePerStep: 7,
            ),
          ),
        ],
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Moved>());
      final effect = (result as Moved).hazardEffect;
      expect(effect, isNotNull);
      expect(effect!.zoneId, 'lava-under-water');
      expect(effect.hazardKind, HazardKind.lava);
      expect(effect.damagePerStep, 7);
    });

    test('highest priority hazard wins for overlapping zones', () {
      final world = _world(
        gameplayZones: const [
          MapGameplayZone(
            id: 'low-poison',
            kind: GameplayZoneKind.hazard,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            priority: 1,
            hazard: HazardZonePayload(
              hazardKind: HazardKind.poison,
              damagePerStep: 3,
            ),
          ),
          MapGameplayZone(
            id: 'high-lava',
            kind: GameplayZoneKind.hazard,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            priority: 5,
            hazard: HazardZonePayload(
              hazardKind: HazardKind.lava,
              damagePerStep: 10,
            ),
          ),
        ],
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Moved>());
      final effect = (result as Moved).hazardEffect;
      expect(effect, isNotNull);
      expect(effect!.zoneId, 'high-lava');
      expect(effect.hazardKind, HazardKind.lava);
      expect(effect.damagePerStep, 10);
      expect(effect.priority, 5);
    });

    test('generated lava zones from surface plan produce hazard effect', () {
      final map = _surfaceMap();
      final surfaceLayer = map.layers.whereType<SurfaceLayer>().single;
      final originalPlacements = surfaceLayer.placements;
      final plan = createSurfaceGameplayZoneGenerationPlan(
        source: SurfaceGameplayZoneGenerationSource(
          surfaceLayerId: surfaceLayer.id,
          surfaceLayerName: surfaceLayer.name,
          surfacePresetId: 'lava',
          cells: surfaceLayer.placements
              .where((placement) => placement.surfacePresetId == 'lava')
              .map((placement) => GridPos(x: placement.x, y: placement.y))
              .toList(growable: false),
          mapSize: map.size,
        ),
        behavior: const SurfaceGameplayZoneBehaviorDraft.hazard(
          HazardZonePayload(
            hazardKind: HazardKind.lava,
            damagePerStep: 5,
          ),
        ),
        strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
        zoneIdPrefix: 'lava-hazard',
        zoneNamePrefix: 'Lava - Hazard',
        existingZones: map.gameplayZones,
      );

      final mapWithGeneratedZones = map.copyWith(
        gameplayZones: plan.generatedZones,
      );
      final world = _world(map: mapWithGeneratedZones);

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(plan.generatedZones, hasLength(1));
      expect(plan.generatedZones.single.kind, GameplayZoneKind.hazard);
      expect(plan.generatedZones.single.hazard?.hazardKind, HazardKind.lava);
      expect(result, isA<Moved>());
      final effect = (result as Moved).hazardEffect;
      expect(effect, isNotNull);
      expect(effect!.hazardKind, HazardKind.lava);
      expect(effect.damagePerStep, 5);
      expect(
        mapWithGeneratedZones.layers
            .whereType<SurfaceLayer>()
            .single
            .placements,
        originalPlacements,
      );
    });
  });
}

GameplayWorldState _world({
  MapData? map,
  bool includeCollisionAtTarget = false,
  MovementMode playerMovementMode = MovementMode.walk,
  List<MapGameplayZone> gameplayZones = const [],
}) {
  return GameplayWorldState.initial(
    map: map ??
        _baseMap(
          includeCollisionAtTarget: includeCollisionAtTarget,
          gameplayZones: gameplayZones,
        ),
    playerPos: const GridPos(x: 0, y: 0),
    playerMovementMode: playerMovementMode,
    project: _project(),
  );
}

MapData _baseMap({
  required bool includeCollisionAtTarget,
  required List<MapGameplayZone> gameplayZones,
}) {
  return MapData(
    id: 'hazard_map',
    name: 'Hazard Map',
    size: const GridSize(width: 3, height: 1),
    layers: [
      const MapLayer.tile(
        id: 'tile',
        name: 'Tile',
        tiles: [0, 0, 0],
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: includeCollisionAtTarget
            ? const [false, true, false]
            : const [false, false, false],
      ),
    ],
    gameplayZones: gameplayZones,
  );
}

MapData _surfaceMap() {
  return const MapData(
    id: 'surface_lava_map',
    name: 'Surface Lava Map',
    size: GridSize(width: 3, height: 1),
    layers: [
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
      SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(
            x: 1,
            y: 0,
            surfacePresetId: 'lava',
          ),
        ],
      ),
    ],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Hazard Project',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(
      presets: [
        ProjectSurfacePreset(
          id: 'lava',
          name: 'Lava',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: [
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: 'lava-idle',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

```


## 22. Contenu complet des fichiers modifiés

### `packages/map_gameplay/lib/src/gameplay_step.dart`

```dart
import 'package:map_core/map_core.dart';

import 'collision/pixel_movement_resolver.dart';
import 'direction.dart';
import 'gameplay_hazard.dart';
import 'gameplay_intent.dart';
import 'movement_block_reason.dart';
import 'gameplay_step_result.dart';
import 'gameplay_world_state.dart';

GameplayStepResult stepGameplayWorld(
  GameplayWorldState world,
  GameplayIntent intent,
) {
  return switch (intent) {
    MoveIntent move => _resolveMove(world, move),
    InteractIntent() => _resolveInteract(world),
  };
}

/// Déplacement **réellement pixel-level** : [playerPositionPx] + résolveur séparé H/V.
GameplayStepResult _resolveMove(GameplayWorldState world, MoveIntent intent) {
  final direction = intent.direction;
  final step = intent.pixelsPerStep;
  final facingWorld = world.withPlayer(
    world.player.copyWith(facing: direction),
  );

  final feet = facingWorld.player.pos;
  final nextCellX = feet.x + direction.dx;
  final nextCellY = feet.y + direction.dy;
  final isOutOfBounds = nextCellX < 0 ||
      nextCellY < 0 ||
      nextCellX >= facingWorld.map.size.width ||
      nextCellY >= facingWorld.map.size.height;

  if (isOutOfBounds) {
    final connectionDirection = _connectionDirectionForMove(direction);
    final connection = findMapConnection(facingWorld.map, connectionDirection);
    if (connection == null) {
      return Blocked(
        facingWorld,
        reason: GameplayMovementBlockReason.outOfBounds,
      );
    }
    return ConnectionTriggered(
      facingWorld,
      TriggeredConnection(
        direction: connection.direction,
        targetMapId: connection.targetMapId,
        offset: connection.offset,
        sourcePos: facingWorld.player.pos,
      ),
    );
  }

  if (facingWorld.isWaterCell(nextCellX, nextCellY) &&
      facingWorld.player.movementMode != MovementMode.surf) {
    return Blocked(
      facingWorld,
      reason: GameplayMovementBlockReason.waterRequiresSurf,
    );
  }

  final dx = direction.dx * step;
  final dy = direction.dy * step;

  final resolvedTopLeft = PixelMovementResolverV1.resolveSeparateAxis(
    spriteTopLeftPx: facingWorld.player.playerPositionPx,
    deltaXPx: dx,
    deltaYPx: dy,
    spriteWidthPx: facingWorld.player.playerSpriteWidthPx,
    spriteHeightPx: facingWorld.player.playerSpriteHeightPx,
    worldStaticObstaclesCollidePixelRect:
        facingWorld.worldStaticObstaclesCollidePixelRect,
  );

  final unchanged =
      resolvedTopLeft.leftPx == facingWorld.player.playerPositionPx.leftPx &&
          resolvedTopLeft.topPx == facingWorld.player.playerPositionPx.topPx;

  if (unchanged) {
    final bumpWarp = facingWorld.warpOnBumpAt(nextCellX, nextCellY, direction);
    if (bumpWarp != null) {
      return WarpTriggered(
        facingWorld,
        TriggeredWarp(
          warpId: bumpWarp.id,
          targetMapId: bumpWarp.targetMapId,
          targetPos: bumpWarp.targetPos,
          triggerMode: bumpWarp.triggerMode,
        ),
      );
    }
    final bumpBehavior =
        facingWorld.placedElementBehaviorOnBumpAt(nextCellX, nextCellY);
    if (bumpBehavior != null) {
      return PlacedElementInteracted(
        facingWorld,
        bumpBehavior.element,
        bumpBehavior.behavior,
        MapPlacedElementTriggerType.onBump,
      );
    }
    final pathBumpSignal = _buildPathTriggerSignal(
      activation: facingWorld.pathAnimationRuleOnBumpAt(nextCellX, nextCellY),
      sourcePos: GridPos(x: nextCellX, y: nextCellY),
    );
    return Blocked(
      facingWorld,
      reason: GameplayMovementBlockReason.solid,
      pathAnimationSignals: pathBumpSignal == null
          ? const <PathAnimationSignal>[]
          : <PathAnimationSignal>[pathBumpSignal],
    );
  }

  final newGridPos = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
    playerCollisionRectPx:
        PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
      spriteTopLeftPx: resolvedTopLeft,
      spriteWidthPx: facingWorld.player.playerSpriteWidthPx,
      spriteHeightPx: facingWorld.player.playerSpriteHeightPx,
    ),
    tileWidthPx: facingWorld.tileWidthPx,
    tileHeightPx: facingWorld.tileHeightPx,
    mapWidthCells: facingWorld.map.size.width,
    mapHeightCells: facingWorld.map.size.height,
  );

  final movedWorld = facingWorld.withPlayer(
    facingWorld.player.copyWith(
      playerPositionPx: resolvedTopLeft,
      pos: newGridPos,
    ),
  );
  final previousPos = facingWorld.player.pos;
  final targetPos = movedWorld.player.pos;

  final warp = movedWorld.warpOnEnterAt(
    movedWorld.player.pos.x,
    movedWorld.player.pos.y,
    direction,
  );
  if (warp != null) {
    return WarpTriggered(
      movedWorld,
      TriggeredWarp(
        warpId: warp.id,
        targetMapId: warp.targetMapId,
        targetPos: warp.targetPos,
        triggerMode: warp.triggerMode,
      ),
    );
  }

  final pathSignals = _collectPathAnimationSignalsOnMove(
    world: movedWorld,
    previousPos: previousPos,
    targetPos: targetPos,
  );

  final movementBehavior = _resolveMovementTriggeredBehavior(
    world: movedWorld,
    targetX: movedWorld.player.pos.x,
    targetY: movedWorld.player.pos.y,
    previousPos: previousPos,
  );
  if (movementBehavior != null && movementBehavior is PlacedElementInteracted) {
    return PlacedElementInteracted(
      movementBehavior.world,
      movementBehavior.element,
      movementBehavior.behavior,
      movementBehavior.trigger,
      pathAnimationSignals: pathSignals,
    );
  }

  return Moved(
    movedWorld,
    hazardEffect: _resolveHazardEffectAt(movedWorld, targetPos),
    pathAnimationSignals: pathSignals,
  );
}

GameplayHazardEffect? _resolveHazardEffectAt(
  GameplayWorldState world,
  GridPos position,
) {
  MapGameplayZone? bestZone;
  for (final zone in world.map.gameplayZones) {
    if (zone.kind != GameplayZoneKind.hazard) continue;
    final hazard = zone.hazard;
    if (hazard == null || hazard.damagePerStep <= 0) continue;
    if (!_containsPos(zone.area, position)) continue;
    if (bestZone == null || zone.priority >= bestZone.priority) {
      bestZone = zone;
    }
  }

  if (bestZone == null) return null;
  final hazard = bestZone.hazard!;
  return GameplayHazardEffect(
    zoneId: bestZone.id,
    zoneName: bestZone.name,
    hazardKind: hazard.hazardKind,
    damagePerStep: hazard.damagePerStep,
    position: position,
    priority: bestZone.priority,
  );
}

bool _containsPos(MapRect rect, GridPos pos) {
  return pos.x >= rect.pos.x &&
      pos.y >= rect.pos.y &&
      pos.x < rect.pos.x + rect.size.width &&
      pos.y < rect.pos.y + rect.size.height;
}

GameplayStepResult? _resolveMovementTriggeredBehavior({
  required GameplayWorldState world,
  required int targetX,
  required int targetY,
  required GridPos previousPos,
}) {
  for (final trigger in _movementTriggerPriority) {
    final activation = switch (trigger) {
      MapPlacedElementTriggerType.onEnter =>
        world.placedElementBehaviorOnEnterAt(targetX, targetY),
      MapPlacedElementTriggerType.onExit =>
        world.placedElementBehaviorOnExitTransition(
          from: previousPos,
          to: world.player.pos,
        ),
      MapPlacedElementTriggerType.onNear =>
        world.placedElementBehaviorOnNearTransition(
          from: previousPos,
          to: world.player.pos,
        ),
      _ => null,
    };
    if (activation == null) {
      continue;
    }
    if (!_passesBehaviorScopeForMovement(
      world: world,
      activation: activation,
      trigger: trigger,
      previousPos: previousPos,
    )) {
      continue;
    }
    return PlacedElementInteracted(
      world,
      activation.element,
      activation.behavior,
      trigger,
    );
  }
  return null;
}

const List<MapPlacedElementTriggerType> _movementTriggerPriority =
    <MapPlacedElementTriggerType>[
  MapPlacedElementTriggerType.onEnter,
  MapPlacedElementTriggerType.onExit,
  MapPlacedElementTriggerType.onNear,
];

MapConnectionDirection _connectionDirectionForMove(Direction direction) {
  return switch (direction) {
    Direction.north => MapConnectionDirection.north,
    Direction.south => MapConnectionDirection.south,
    Direction.east => MapConnectionDirection.east,
    Direction.west => MapConnectionDirection.west,
  };
}

GameplayStepResult _resolveInteract(GameplayWorldState world) {
  final facing = world.player.facing;
  final tx = world.player.pos.x + facing.dx;
  final ty = world.player.pos.y + facing.dy;
  final entity = world.entityAt(tx, ty);

  if (entity != null) {
    return switch (entity.kind) {
      MapEntityKind.npc => NpcInteracted(world, entity),
      MapEntityKind.sign => SignInteracted(world, entity),
      MapEntityKind.item => ItemInteracted(world, entity),
      _ => EntityInteracted(world, entity),
    };
  }

  final actionBehavior = world.placedElementBehaviorOnActionAt(tx, ty);
  if (actionBehavior != null &&
      _passesBehaviorScopeForAction(
        world: world,
        activation: actionBehavior,
      )) {
    return PlacedElementInteracted(
      world,
      actionBehavior.element,
      actionBehavior.behavior,
      MapPlacedElementTriggerType.onAction,
    );
  }

  final pathActionSignal = _buildPathTriggerSignal(
    activation: world.pathAnimationRuleOnActionAt(tx, ty),
    sourcePos: GridPos(x: tx, y: ty),
  );
  return NothingToInteract(
    world,
    pathAnimationSignals: pathActionSignal == null
        ? const <PathAnimationSignal>[]
        : <PathAnimationSignal>[pathActionSignal],
  );
}

List<PathAnimationSignal> _collectPathAnimationSignalsOnMove({
  required GameplayWorldState world,
  required GridPos previousPos,
  required GridPos targetPos,
}) {
  final signals = <PathAnimationSignal>[];

  final enterActivation = world.pathAnimationRuleOnEnterAt(
    targetPos.x,
    targetPos.y,
  );
  final previousEnterActivation = world.pathAnimationRuleOnEnterAt(
    previousPos.x,
    previousPos.y,
  );
  if (!_isSamePathAnimationRuleActivation(
    previousEnterActivation,
    enterActivation,
  )) {
    final signal = _buildPathTriggerSignal(
      activation: enterActivation,
      sourcePos: targetPos,
    );
    if (signal != null) {
      signals.add(signal);
    }
  }

  final stepSignal = _buildPathTriggerSignal(
    activation: world.pathAnimationRuleOnStepAt(targetPos.x, targetPos.y),
    sourcePos: targetPos,
  );
  if (stepSignal != null) {
    signals.add(stepSignal);
  }

  final nearActivation = world.pathAnimationRuleOnNearTransition(
    from: previousPos,
    to: targetPos,
  );
  final nearSignal = _buildPathTriggerSignal(
    activation: nearActivation,
    sourcePos: targetPos,
  );
  if (nearSignal != null) {
    signals.add(nearSignal);
  }

  final previousInsideActivation = world.pathAnimationRuleWhileInsideAt(
    previousPos.x,
    previousPos.y,
  );
  final currentInsideActivation = world.pathAnimationRuleWhileInsideAt(
    targetPos.x,
    targetPos.y,
  );
  if (!_isSamePathAnimationRuleActivation(
    previousInsideActivation,
    currentInsideActivation,
  )) {
    if (previousInsideActivation != null) {
      signals.add(
        _buildPathSetActiveSignal(
          activation: previousInsideActivation,
          sourcePos: previousPos,
          active: false,
        ),
      );
    }
    if (currentInsideActivation != null) {
      signals.add(
        _buildPathSetActiveSignal(
          activation: currentInsideActivation,
          sourcePos: targetPos,
          active: true,
        ),
      );
    }
  }

  return signals;
}

PathAnimationSignal? _buildPathTriggerSignal({
  required PathAnimationRuleActivation? activation,
  required GridPos sourcePos,
}) {
  if (activation == null) {
    return null;
  }
  return PathAnimationSignal(
    kind: PathAnimationSignalKind.trigger,
    layerId: activation.layerId,
    presetId: activation.presetId,
    ruleId: activation.ruleId,
    trigger: activation.rule.trigger,
    mode: activation.rule.mode,
    sourcePos: sourcePos,
    scope: activation.rule.scope,
  );
}

PathAnimationSignal _buildPathSetActiveSignal({
  required PathAnimationRuleActivation activation,
  required GridPos sourcePos,
  required bool active,
}) {
  return PathAnimationSignal(
    kind: PathAnimationSignalKind.setActive,
    layerId: activation.layerId,
    presetId: activation.presetId,
    ruleId: activation.ruleId,
    trigger: activation.rule.trigger,
    mode: activation.rule.mode,
    sourcePos: sourcePos,
    scope: activation.rule.scope,
    active: active,
  );
}

bool _passesBehaviorScopeForMovement({
  required GameplayWorldState world,
  required PlacedElementBehaviorActivation activation,
  required MapPlacedElementTriggerType trigger,
  required GridPos previousPos,
}) {
  final scope = activation.behavior.triggerScope;
  switch (scope) {
    case MapPlacedElementTriggerScope.defaultScope:
      return true;
    case MapPlacedElementTriggerScope.oncePerEnter:
      if (trigger != MapPlacedElementTriggerType.onEnter) {
        return true;
      }
      final previousActivation = world.placedElementBehaviorOnEnterAt(
        previousPos.x,
        previousPos.y,
      );
      return !_isSameBehaviorActivation(previousActivation, activation);
    case MapPlacedElementTriggerScope.whileInsideSingleShot:
      if (trigger == MapPlacedElementTriggerType.onEnter) {
        final previousActivation = world.placedElementBehaviorOnEnterAt(
          previousPos.x,
          previousPos.y,
        );
        return !_isSameBehaviorActivation(previousActivation, activation);
      }
      if (trigger == MapPlacedElementTriggerType.onNear) {
        final previousActivation = world.placedElementBehaviorOnNearAt(
          previousPos.x,
          previousPos.y,
        );
        return !_isSameBehaviorActivation(previousActivation, activation);
      }
      return true;
    case MapPlacedElementTriggerScope.facingOnly:
      if (trigger != MapPlacedElementTriggerType.onNear) {
        return true;
      }
      return world.isFacingPlacedElement(
        playerPos: world.player.pos,
        facing: world.player.facing,
        element: activation.element,
      );
    case MapPlacedElementTriggerScope.nearCardinalOnly:
      return true;
  }
}

bool _passesBehaviorScopeForAction({
  required GameplayWorldState world,
  required PlacedElementBehaviorActivation activation,
}) {
  final scope = activation.behavior.triggerScope;
  switch (scope) {
    case MapPlacedElementTriggerScope.defaultScope:
    case MapPlacedElementTriggerScope.oncePerEnter:
    case MapPlacedElementTriggerScope.whileInsideSingleShot:
    case MapPlacedElementTriggerScope.nearCardinalOnly:
      return true;
    case MapPlacedElementTriggerScope.facingOnly:
      return world.isFacingPlacedElement(
        playerPos: world.player.pos,
        facing: world.player.facing,
        element: activation.element,
      );
  }
}

bool _isSameBehaviorActivation(
  PlacedElementBehaviorActivation? a,
  PlacedElementBehaviorActivation? b,
) {
  if (a == null || b == null) {
    return false;
  }
  return a.element.id == b.element.id &&
      _behaviorIdentity(a.behavior) == _behaviorIdentity(b.behavior);
}

bool _isSamePathAnimationRuleActivation(
  PathAnimationRuleActivation? a,
  PathAnimationRuleActivation? b,
) {
  if (a == null || b == null) {
    return false;
  }
  return a.layerId == b.layerId && a.ruleId == b.ruleId;
}

String _behaviorIdentity(MapPlacedElementBehavior behavior) {
  final behaviorId = behavior.id.trim();
  if (behaviorId.isNotEmpty) {
    return behaviorId;
  }
  return '${behavior.trigger.name}:${behavior.effect.type.name}';
}

```
### `packages/map_gameplay/lib/src/gameplay_step_result.dart`

```dart
import 'package:map_core/map_core.dart';

import 'gameplay_hazard.dart';
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
    super.pathAnimationSignals,
  });

  final GameplayHazardEffect? hazardEffect;
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


## 23. Git status final

```text
git status --short --untracked-files=all
 M packages/map_gameplay/lib/map_gameplay.dart
 M packages/map_gameplay/lib/src/gameplay_step.dart
 M packages/map_gameplay/lib/src/gameplay_step_result.dart
?? packages/map_gameplay/lib/src/gameplay_hazard.dart
?? packages/map_gameplay/test/hazard_runtime_consumption_test.dart
?? reports/surface/surface_engine_lot_108_hazard_runtime_consumption_prep.md

git diff --stat
 packages/map_gameplay/lib/map_gameplay.dart        |  1 +
 packages/map_gameplay/lib/src/gameplay_step.dart   | 42 ++++++++++++++++++++--
 .../map_gameplay/lib/src/gameplay_step_result.dart |  4 +++
 3 files changed, 44 insertions(+), 3 deletions(-)
```

## 24. Périmètre explicitement non touché

Confirmations :

- map_editor production non modifié ;
- map_runtime production non modifié ;
- map_core production non modifié ;
- map_battle non modifié ;
- MapData modèle non modifié ;
- MapGameplayZone modèle non modifié ;
- HazardZonePayload non modifié ;
- HazardKind non modifié ;
- MovementZonePayload non modifié ;
- EncounterZonePayload non modifié ;
- SurfaceLayer non modifié ;
- SurfaceCellPlacement non modifié ;
- ProjectManifest non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucune action editor lava codée ;
- aucun dialog lava codé ;
- aucun runtime PlayableMapGame modifié ;
- aucune mutation GameState / party / HP ;
- aucun ice / mud codé ;
- aucune migration legacy ;
- aucun filtre surfacePresetId dans MapGameplayZone.

## 25. ctx stats

```text
ctx stats
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-QcAPWv/script.sh: line 1: ctx: command not found

context-mode doctor
- [x] Runtimes: 7/11 (64%) — javascript, shell, python, ruby, rust, php, perl
- [-] Performance: NORMAL — install Bun for 3-5x speed boost
- [x] Server test: PASS
- [x] FTS5 / SQLite: PASS — native module works
- [x] Hook script: PASS — /opt/homebrew/lib/node_modules/context-mode/hooks/pretooluse.mjs
- [x] Version: v1.0.100
```

Context Mode MCP a bien été utilisé pour Gate 0, les audits, le test rouge, les tests/régressions/analyze et les diffs. La commande CLI `ctx stats` demandée a été exécutée, mais le binaire `ctx` n'est pas disponible dans le shell ; les outils MCP Context Mode sont disponibles et opérationnels. Sorties indexées dans les appels principaux : Gate 0 37 lignes / 0,9 KB, audit 8554 lignes / 932,0 KB, vérifications post-format 121 lignes / 8,7 KB, diff/scope 132 lignes / 4,6 KB.

## 26. Limites restantes

- `GameplayHazardEffect` est observable côté `map_gameplay`, mais aucun runtime Flutter ne le lit encore.
- Les dégâts ne sont pas appliqués aux HP / party / `GameState`.
- Pas de feedback visuel ou texte runtime.
- Pas d'action editor lava.
- Pas de dialog `Lave dangereuse`.
- Pas de test PlayableMapGame hazard.
- Les résultats autres que `Moved`, par exemple `PlacedElementInteracted`, ne transportent pas encore d'effet hazard.

## 27. Auto-critique

- Est-ce que la consommation gameplay des hazards existe maintenant ? Oui.
- Est-ce que lava hazard est détecté côté map_gameplay ? Oui.
- Est-ce que damagePerStep est exposé dans un effet observable ? Oui.
- Est-ce que les dégâts sont appliqués à GameState / party ? Non, volontairement : le lot expose l'effet sans muter HP / party.
- Est-ce que l'effet est déclenché uniquement après mouvement réussi ? Oui, uniquement via `Moved`.
- Est-ce que mouvement bloqué ne déclenche pas hazard ? Oui.
- Est-ce que waterRequiresSurf bloque avant hazard en walking ? Oui.
- Est-ce que surfing sur water+hazard déclenche hazard après mouvement ? Oui.
- Est-ce que la priorité des zones hazard est testée ? Oui.
- Est-ce que generated lava zones depuis Surface plan sont testées ? Oui.
- Est-ce qu'aucun modèle map_core n'est modifié ? Oui.
- Est-ce qu'aucun editor n'est modifié ? Oui.
- Est-ce qu'aucun runtime Flutter n'est modifié ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les régressions bridge passent ? Oui.
- Est-ce que l'analyse ciblée passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec la sortie exacte du CLI indisponible et le doctor MCP.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui, sauf le rapport lui-même par exception.
- Est-ce qu'un Lot 108-bis est nécessaire ? Non. Le contrat minimal demandé est en place et testé. Le prochain lot peut décider soit editor lava, soit runtime feedback/application de dégâts.

## 28. Regard critique sur le prompt

Le prompt est utilement strict : il force à ne pas coder l'éditeur lava avant la preuve gameplay. La contrainte la plus importante était de ne pas appliquer des dégâts réels sans seam clair ; elle évite de mélanger overworld, party et runtime dans un lot trop large.

Le seul point délicat est `damagePerStep <= 0` : le prompt recommande de ne pas produire d'effet dommageable, mais ne demande pas explicitement un test dédié. L'implémentation l'applique dans le resolver ; un lot futur pourrait ajouter un test isolé si cette règle devient une surface publique importante.

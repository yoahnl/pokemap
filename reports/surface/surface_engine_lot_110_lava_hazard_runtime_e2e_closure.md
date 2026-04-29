# Lot 110 — Lava Hazard Runtime E2E / Closure V0

## 1. Résumé exécutif honnête

Lot 110 ferme lava V0 par preuve gameplay ciblée. Aucun code de production n'a été modifié.

Les tests prouvent maintenant :

- une `SurfaceLayer` lava seule reste visuelle et ne produit aucun `GameplayHazardEffect` ;
- les zones lava générées par `createSurfaceGameplayZoneGenerationPlan(...)` avec `SurfaceGameplayZoneBehaviorDraft.hazard(...)` produisent un `GameplayHazardEffect` après mouvement réussi ;
- `damagePerStep` est transmis, y compris une valeur custom `8` ;
- `damagePerStep <= 0` ne produit pas d'effet hazard ;
- un mouvement bloqué vers lava ne déclenche pas d'effet ;
- les placements de `SurfaceLayer` restent inchangés après ajout des zones gameplay.

Le comportement lava V0 est donc fermé au niveau gameplay ciblé : authoring editor prouvé par Lot 109, consommation gameplay minimale prouvée par Lot 108, et bridge surface lava -> generated hazard -> effet gameplay prouvé par Lot 110.

## 2. Périmètre

Inclus :

- extension du test bridge gameplay surface -> gameplay zone ;
- test explicite `damagePerStep <= 0` côté hazard runtime ;
- relance des régressions gameplay, editor Surface Painter et briques pures map_core ;
- rapport de clôture.

Exclus :

- UI editor ;
- production `map_editor`, `map_gameplay`, `map_core`, `map_runtime` ;
- application réelle de dégâts aux HP / party / `GameState` ;
- `PlayableMapGame` ;
- feedback runtime Flutter ;
- ice / mud.

## 3. Gate 0 — status initial

Commandes exécutées depuis `/Users/karim/Project/pokemonProject` :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
find . -name AGENTS.md -print
```

Sortie complète :

```text
/Users/karim/Project/pokemonProject

--- branch ---
main

--- status ---

--- diff stat ---

--- log ---
af24a783 lot 109: Editor Generate Lava Hazard Zone from Surface
3ef5fc92 lot 108: Hazard Runtime Consumption Prep
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
8b5c3728 lot 103: Editor Generate Surfable Water Gameplay Zone from Surface
6a3db8e3 lot 101: Tall Grass Surface Workflow Hardening - Batch Apply
b224b0f6 fix: resolve RenderFlex overflow errors in layers and surface panels
888f1339 fix: resolve RenderFlex overflow errors in layers and surface panels
58ab7070 lot 100/95: Editor Generate Gameplay Zone from Surface

--- agents ---
./AGENTS.md
```

Changements préexistants : aucun. Le worktree était propre avant Lot 110.

Changements du Lot 110 :

- `packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart`
- `packages/map_gameplay/test/hazard_runtime_consumption_test.dart`
- `reports/surface/surface_engine_lot_110_lava_hazard_runtime_e2e_closure.md`

## 4. Context Mode usage

Context Mode a été utilisé pour indexer et rechercher les rapports et fichiers prioritaires :

- `reports/surface/surface_engine_lot_108_hazard_runtime_consumption_prep.md`
- `reports/surface/surface_engine_lot_109_editor_generate_lava_hazard_zone_from_surface.md`
- `packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart`
- `packages/map_gameplay/test/hazard_runtime_consumption_test.dart`
- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_gameplay/lib/src/gameplay_step_result.dart`

Commandes d'audit lancées :

```text
rg -n "Lot 108|Lot 109|GameplayHazardEffect|Moved\.hazardEffect|HazardZonePayload|HazardKind\.lava|damagePerStep|Lave dangereuse|applyLavaHazardGameplayZonePlan|buildLavaHazardSurfaceGameplayZonePreview" reports/surface packages/map_gameplay/lib packages/map_gameplay/test packages/map_editor/lib packages/map_editor/test
rg -n "surface generated gameplay zone bridge|generated water|generated tall grass|SurfaceLayer alone|createSurfaceGameplayZoneGenerationPlan|SurfaceGameplayZoneBehaviorDraft" packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart packages/map_gameplay/test/hazard_runtime_consumption_test.dart
rg -n "Lave dangereuse|LavaHazardSurfaceGameplayZoneDialog|buildLavaHazardSurfaceGameplayZonePreview|applyLavaHazardGameplayZonePlan|damagePerStep|HazardKind\.lava" packages/map_editor/test packages/map_editor/lib
rg -n "hazard runtime consumption|generated lava zones|Moved\.hazardEffect|waterRequiresSurf|highest priority hazard|damagePerStep" packages/map_gameplay/test packages/map_gameplay/lib
```

Findings importants :

- Lot 108 a ajouté `GameplayHazardEffect`, exporté par `map_gameplay.dart`, et `Moved.hazardEffect`.
- `stepGameplayWorld(...)` résout l'effet hazard uniquement après un mouvement réussi.
- `_resolveHazardEffectAt(...)` ignore les hazards dont `damagePerStep <= 0`.
- Lot 109 a ajouté `Lave dangereuse` côté editor, avec validation stricte `damagePerStep > 0`, plan `greedyRectangles`, assessment et batch apply.
- `surface_generated_gameplay_zone_bridge_test.dart` prouvait déjà water/surf et tall_grass/encounter ; c'est le meilleur fichier pour fermer lava dans le même style E2E.

## 5. Audit Lots 108 / 109

Lot 108 prouve côté gameplay :

- `MapGameplayZone(kind: hazard)` est consommée par `stepGameplayWorld(...)` ;
- `Moved.hazardEffect` expose `zoneId`, `zoneName`, `hazardKind`, `damagePerStep`, `position`, `priority` ;
- mouvement bloqué ne déclenche pas d'effet ;
- `waterRequiresSurf` bloque avant hazard en walking ;
- surfing sur water + hazard déclenche hazard après mouvement ;
- priorité haute gagne entre hazards chevauchants ;
- une zone lava générée depuis un plan Surface peut produire un effet.

Lot 109 prouve côté editor :

- le menu comportement Surface propose `Lave dangereuse` ;
- le dialog `Créer une zone de lave dangereuse` valide `damagePerStep > 0` ;
- `buildLavaHazardSurfaceGameplayZonePreview(...)` produit un plan hazard/lava ;
- `applyLavaHazardGameplayZonePlan(...)` refuse les plans invalides et applique via batch apply ;
- aucune production runtime n'est modifiée.

Ce qui manquait pour clôturer lava V0 :

- une preuve dans le test bridge principal que `SurfaceLayer` lava seule reste visuelle ;
- une preuve que le plan généré depuis la surface lava dans le bridge produit bien l'effet hazard ;
- une preuve dédiée que `damagePerStep <= 0` ne produit aucun effet.

## 6. Audit tests bridge / hazard existants

Tests existants avant Lot 110 :

- `surface_generated_gameplay_zone_bridge_test.dart` : water visual-only, water generated movement/surf, tall_grass generated encounter.
- `hazard_runtime_consumption_test.dart` : normal movement no hazard, lava effect, blocked movement, waterRequiresSurf, surfing into water hazard, priority, generated lava from simple surface plan.
- `surface_to_gameplay_zone_action_test.dart` : authoring editor lava, tall grass, water, menu routing, batch apply.

Décision : ajouter lava dans `surface_generated_gameplay_zone_bridge_test.dart`, parce que ce fichier porte déjà la preuve transverse Surface -> generated gameplay zone -> consommation gameplay pour tall grass et water. Ajouter aussi le test `damagePerStep == 0` dans `hazard_runtime_consumption_test.dart`, car c'est une règle du resolver hazard plutôt qu'une règle du bridge surface.

## 7. Décision d'organisation des tests

Organisation retenue :

- bridge E2E surface lava dans `surface_generated_gameplay_zone_bridge_test.dart` ;
- règle `damagePerStep <= 0` dans `hazard_runtime_consumption_test.dart` ;
- aucun nouveau fichier test ;
- aucun test editor modifié, car Lot 109 couvre déjà l'authoring lava ;
- aucun test runtime Flutter ajouté, car le contrat V0 reste map_gameplay et `PlayableMapGame` est hors périmètre.

## 8. Surface lava visual-only behavior

Le test `SurfaceLayer alone stays visual for water, grass, and lava` ajoute une surface lava peinte dans la fixture partagée sans zone gameplay hazard.

Résultat vérifié :

- walking vers la cellule visuellement lava produit `Moved` ;
- la position devient `GridPos(x: 2, y: 1)` ;
- `Moved.hazardEffect == null`.

Cela verrouille la séparation V0 : `SurfaceLayer` reste visuelle.

## 9. Generated lava hazard behavior

Le test `generated lava hazard zones are consumed by hazard effects` utilise :

```dart
createSurfaceGameplayZoneGenerationPlan(
  source: _sourceForPreset(map, 'lava'),
  behavior: SurfaceGameplayZoneBehaviorDraft.hazard(
    HazardZonePayload(
      hazardKind: HazardKind.lava,
      damagePerStep: damagePerStep,
    ),
  ),
  strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
  zoneIdPrefix: 'lava-hazard',
  zoneNamePrefix: 'Lava - Hazard',
  existingZones: map.gameplayZones,
)
```

Résultat vérifié :

- toutes les zones générées sont `GameplayZoneKind.hazard` ;
- chaque payload est `HazardKind.lava` ;
- `damagePerStep == 5` ;
- `stepGameplayWorld(...)` produit `Moved` ;
- `Moved.hazardEffect` est non nul ;
- l'effet est `HazardKind.lava`, `damagePerStep == 5`, position finale `GridPos(x: 2, y: 1)` ;
- `zoneId` correspond à une zone générée.

## 10. Damage custom / zero damage behavior

Damage custom :

- le test `generated lava hazard preserves custom damagePerStep` génère un plan avec `damagePerStep: 8` ;
- l'effet gameplay expose `damagePerStep == 8`.

Damage zéro :

- le test `non-positive lava damage does not produce a hazard effect` crée une zone lava avec `damagePerStep: 0` ;
- le mouvement réussit ;
- `Moved.hazardEffect == null`.

## 11. SurfaceLayer non-mutation

Le test bridge conserve :

```dart
final originalSurfacePlacements = _surfaceLayer(map).placements;
final mapWithZones = map.copyWith(gameplayZones: plan.generatedZones);
expect(_surfaceLayer(mapWithZones).placements, originalSurfacePlacements);
```

Cela prouve que l'ajout des `MapGameplayZone` générées ne modifie pas les placements `SurfaceLayer`.

## 12. Tests lancés

```text
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/movement_mode_water_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart --reporter expanded
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
```

## 13. Résultats

Lignes finales exactes :

```text
surface_generated_gameplay_zone_bridge_test.dart:
00:00 +6: All tests passed!

hazard_runtime_consumption_test.dart:
00:00 +8: All tests passed!

movement_mode_water_test.dart:
00:00 +6: All tests passed!

surf_evaluation_test.dart:
00:00 +12: All tests passed!

surface_to_gameplay_zone_action_test.dart:
00:01 +29: All tests passed!

test/surface_painter:
00:02 +71: All tests passed!

surface_to_gameplay_zone_generation_plan_test.dart:
00:00 +16: All tests passed!

surface_to_gameplay_zone_generation_assessment_test.dart:
00:00 +12: All tests passed!
```

## 14. Analyse lancée

```text
cd packages/map_gameplay && dart analyze test/surface_generated_gameplay_zone_bridge_test.dart test/hazard_runtime_consumption_test.dart
```

## 15. Résultats analyze

Sortie complète :

```text
Analyzing surface_generated_gameplay_zone_bridge_test.dart, hazard_runtime_consumption_test.dart...
No issues found!
```

## 16. Fichiers créés

```text
reports/surface/surface_engine_lot_110_lava_hazard_runtime_e2e_closure.md
```

## 17. Fichiers modifiés

```text
packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart
packages/map_gameplay/test/hazard_runtime_consumption_test.dart
```

## 18. Fichiers supprimés

```text
Aucun.
```

## 19. Contenu complet des fichiers créés

```text
reports/surface/surface_engine_lot_110_lava_hazard_runtime_e2e_closure.md
```

Le rapport n'est pas recopié dans lui-même afin d'éviter une récursion infinie, conformément à l'exception demandée pour les rapports.

## 20. Contenu complet des fichiers modifiés

### `packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart`

```dart
import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('surface generated gameplay zone bridge', () {
    test('SurfaceLayer alone stays visual for water, grass, and lava', () {
      final map = _baseSurfaceMap();
      final project = _project();

      final walkWorld = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
        project: project,
      );
      final walkResult =
          stepGameplayWorld(walkWorld, const MoveIntent(Direction.east));

      expect(walkResult, isA<Moved>());
      expect(walkResult.world.player.pos, const GridPos(x: 1, y: 0));

      final grassWorld = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 1),
        project: project,
      );
      final encounterResult = checkEncounterAtPlayerPosition(
        world: grassWorld,
        project: project,
        encounterKind: EncounterKind.walk,
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
        random: Random(1),
      );

      expect(encounterResult.status, GameplayEncounterCheckStatus.noZone);
      expect(encounterResult.triggered, isFalse);

      final lavaWorld = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 1, y: 1),
        project: project,
      );
      final lavaResult =
          stepGameplayWorld(lavaWorld, const MoveIntent(Direction.east));

      expect(lavaResult, isA<Moved>());
      final lavaMoved = lavaResult as Moved;
      expect(lavaMoved.world.player.pos, const GridPos(x: 2, y: 1));
      expect(lavaMoved.hazardEffect, isNull);
    });

    test('generated water movement surf zones are consumed by movement', () {
      final map = _baseSurfaceMap();
      final project = _project();
      final plan = _waterGenerationPlan(map);
      final originalSurfacePlacements = _surfaceLayer(map).placements;

      expect(
        plan.generatedZones,
        everyElement(
          isA<MapGameplayZone>()
              .having((zone) => zone.kind, 'kind', GameplayZoneKind.movement)
              .having(
                (zone) => zone.movement?.requiredMode,
                'requiredMode',
                MovementMode.surf,
              ),
        ),
      );

      final mapWithZones = map.copyWith(gameplayZones: plan.generatedZones);
      expect(_surfaceLayer(mapWithZones).placements, originalSurfacePlacements);

      final walkingWorld = GameplayWorldState.initial(
        map: mapWithZones,
        playerPos: const GridPos(x: 0, y: 0),
        project: project,
      );
      final blocked =
          stepGameplayWorld(walkingWorld, const MoveIntent(Direction.east));

      expect(blocked, isA<Blocked>());
      expect(
        (blocked as Blocked).reason,
        GameplayMovementBlockReason.waterRequiresSurf,
      );
      expect(blocked.world.player.pos, const GridPos(x: 0, y: 0));

      final surfingWorld = GameplayWorldState.initial(
        map: mapWithZones,
        playerPos: const GridPos(x: 0, y: 0),
        playerMovementMode: MovementMode.surf,
        project: project,
      );
      final moved =
          stepGameplayWorld(surfingWorld, const MoveIntent(Direction.east));

      expect(moved, isA<Moved>());
      expect(moved.world.player.pos, const GridPos(x: 1, y: 0));
    });

    test('generated tall grass encounter zones are consumed by encounters', () {
      final map = _baseSurfaceMap();
      final project = _project();
      final plan = _tallGrassGenerationPlan(map);
      final originalSurfacePlacements = _surfaceLayer(map).placements;

      expect(
        plan.generatedZones,
        everyElement(
          isA<MapGameplayZone>()
              .having((zone) => zone.kind, 'kind', GameplayZoneKind.encounter)
              .having(
                (zone) => zone.encounter?.encounterTableId,
                'encounterTableId',
                'route_1_grass',
              )
              .having(
                (zone) => zone.encounter?.encounterKind,
                'encounterKind',
                EncounterKind.walk,
              ),
        ),
      );

      final mapWithZones = map.copyWith(gameplayZones: plan.generatedZones);
      expect(_surfaceLayer(mapWithZones).placements, originalSurfacePlacements);

      final world = GameplayWorldState.initial(
        map: mapWithZones,
        playerPos: const GridPos(x: 0, y: 1),
        project: project,
      );
      final result = checkEncounterAtPlayerPosition(
        world: world,
        project: project,
        encounterKind: EncounterKind.walk,
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
        random: Random(1),
      );

      expect(result.status, GameplayEncounterCheckStatus.triggered);
      expect(result.triggered, isTrue);
      expect(result.tableId, 'route_1_grass');
      expect(result.zoneId, plan.generatedZones.first.id);
      expect(result.encounter?.speciesId, 'pidgey');
      expect(result.encounter?.level, 3);
      expect(result.encounter?.playerPos, const GridPos(x: 0, y: 1));
    });

    test('generated lava hazard zones are consumed by hazard effects', () {
      final map = _baseSurfaceMap();
      final project = _project();
      final plan = _lavaGenerationPlan(map);
      final originalSurfacePlacements = _surfaceLayer(map).placements;

      expect(
        plan.generatedZones,
        everyElement(
          isA<MapGameplayZone>()
              .having((zone) => zone.kind, 'kind', GameplayZoneKind.hazard)
              .having(
                (zone) => zone.hazard?.hazardKind,
                'hazardKind',
                HazardKind.lava,
              )
              .having(
                (zone) => zone.hazard?.damagePerStep,
                'damagePerStep',
                5,
              ),
        ),
      );

      final mapWithZones = map.copyWith(gameplayZones: plan.generatedZones);
      expect(_surfaceLayer(mapWithZones).placements, originalSurfacePlacements);

      final world = GameplayWorldState.initial(
        map: mapWithZones,
        playerPos: const GridPos(x: 1, y: 1),
        project: project,
      );
      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Moved>());
      final effect = (result as Moved).hazardEffect;
      expect(effect, isNotNull);
      expect(effect!.hazardKind, HazardKind.lava);
      expect(effect.damagePerStep, 5);
      expect(effect.position, const GridPos(x: 2, y: 1));
      expect(
        plan.generatedZones.any((zone) => zone.id == effect.zoneId),
        isTrue,
      );
    });

    test('generated lava hazard preserves custom damagePerStep', () {
      final map = _baseSurfaceMap();
      final project = _project();
      final plan = _lavaGenerationPlan(map, damagePerStep: 8);
      final mapWithZones = map.copyWith(gameplayZones: plan.generatedZones);

      final world = GameplayWorldState.initial(
        map: mapWithZones,
        playerPos: const GridPos(x: 1, y: 1),
        project: project,
      );
      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Moved>());
      expect((result as Moved).hazardEffect?.damagePerStep, 8);
    });

    test('blocked movement into generated lava does not trigger hazard', () {
      final map = _baseSurfaceMap(blockLavaTarget: true);
      final project = _project();
      final plan = _lavaGenerationPlan(map);
      final mapWithZones = map.copyWith(gameplayZones: plan.generatedZones);

      final world = GameplayWorldState.initial(
        map: mapWithZones,
        playerPos: const GridPos(x: 1, y: 1),
        project: project,
      );
      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      final blocked = result as Blocked;
      expect(blocked.reason, GameplayMovementBlockReason.solid);
      expect(blocked.world.player.pos, const GridPos(x: 1, y: 1));
    });
  });
}

SurfaceGameplayZoneGenerationPlan _waterGenerationPlan(MapData map) {
  return createSurfaceGameplayZoneGenerationPlan(
    source: _sourceForPreset(map, 'water'),
    behavior: const SurfaceGameplayZoneBehaviorDraft.movement(
      MovementZonePayload(requiredMode: MovementMode.surf),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'water-surf',
    zoneNamePrefix: 'Water - Surf',
    existingZones: map.gameplayZones,
  );
}

SurfaceGameplayZoneGenerationPlan _tallGrassGenerationPlan(MapData map) {
  return createSurfaceGameplayZoneGenerationPlan(
    source: _sourceForPreset(map, 'tall_grass'),
    behavior: const SurfaceGameplayZoneBehaviorDraft.encounter(
      EncounterZonePayload(
        encounterTableId: 'route_1_grass',
        encounterKind: EncounterKind.walk,
      ),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'tall-grass-encounter',
    zoneNamePrefix: 'Tall Grass - Rencontre',
    existingZones: map.gameplayZones,
  );
}

SurfaceGameplayZoneGenerationPlan _lavaGenerationPlan(
  MapData map, {
  int damagePerStep = 5,
}) {
  return createSurfaceGameplayZoneGenerationPlan(
    source: _sourceForPreset(map, 'lava'),
    behavior: SurfaceGameplayZoneBehaviorDraft.hazard(
      HazardZonePayload(
        hazardKind: HazardKind.lava,
        damagePerStep: damagePerStep,
      ),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'lava-hazard',
    zoneNamePrefix: 'Lava - Hazard',
    existingZones: map.gameplayZones,
  );
}

SurfaceGameplayZoneGenerationSource _sourceForPreset(
  MapData map,
  String surfacePresetId,
) {
  final surfaceLayer = _surfaceLayer(map);
  final cells = surfaceLayer.placements
      .where((placement) => placement.surfacePresetId == surfacePresetId)
      .map((placement) => GridPos(x: placement.x, y: placement.y))
      .toList(growable: false);

  return SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: surfaceLayer.id,
    surfaceLayerName: surfaceLayer.name,
    surfacePresetId: surfacePresetId,
    cells: cells,
    mapSize: map.size,
  );
}

SurfaceLayer _surfaceLayer(MapData map) {
  return map.layers.whereType<SurfaceLayer>().single;
}

MapData _baseSurfaceMap({bool blockLavaTarget = false}) {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 4, height: 3),
    layers: [
      const MapLayer.tile(
        id: 'tile',
        name: 'Tile',
        tiles: [
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: blockLavaTarget
            ? const [
                false,
                false,
                false,
                false,
                false,
                false,
                true,
                false,
                false,
                false,
                false,
                false,
              ]
            : const [
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
              ],
      ),
      const SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(
            x: 1,
            y: 0,
            surfacePresetId: 'water',
          ),
          SurfaceCellPlacement(
            x: 2,
            y: 0,
            surfacePresetId: 'water',
          ),
          SurfaceCellPlacement(
            x: 0,
            y: 1,
            surfacePresetId: 'tall_grass',
          ),
          SurfaceCellPlacement(
            x: 1,
            y: 1,
            surfacePresetId: 'tall_grass',
          ),
          SurfaceCellPlacement(
            x: 2,
            y: 1,
            surfacePresetId: 'lava',
          ),
          SurfaceCellPlacement(
            x: 3,
            y: 1,
            surfacePresetId: 'lava',
          ),
          SurfaceCellPlacement(
            x: 2,
            y: 2,
            surfacePresetId: 'lava',
          ),
        ],
      ),
    ],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Surface Bridge Project',
    maps: const [],
    tilesets: const [],
    encounterTables: const [
      ProjectEncounterTable(
        id: 'route_1_grass',
        name: 'Route 1 Grass',
        encounterKind: EncounterKind.walk,
        entries: [
          ProjectEncounterEntry(
            speciesId: 'pidgey',
            minLevel: 3,
            maxLevel: 3,
          ),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(
      presets: [
        ProjectSurfacePreset(
          id: 'water',
          name: 'Water',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: [
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: 'water-idle',
              ),
            ],
          ),
        ),
        ProjectSurfacePreset(
          id: 'tall_grass',
          name: 'Tall Grass',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: [
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: 'tall-grass-idle',
              ),
            ],
          ),
        ),
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

    test('non-positive lava damage does not produce a hazard effect', () {
      final world = _world(
        gameplayZones: const [
          MapGameplayZone(
            id: 'empty-lava-zone',
            kind: GameplayZoneKind.hazard,
            area: MapRect(
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
            hazard: HazardZonePayload(
              hazardKind: HazardKind.lava,
              damagePerStep: 0,
            ),
          ),
        ],
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Moved>());
      final moved = result as Moved;
      expect(moved.world.player.pos, const GridPos(x: 1, y: 0));
      expect(moved.hazardEffect, isNull);
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

## 21. Git status final

Status final complet après création de ce rapport :

```text
 M packages/map_gameplay/test/hazard_runtime_consumption_test.dart
 M packages/map_gameplay/test/surface_generated_gameplay_zone_bridge_test.dart
?? reports/surface/surface_engine_lot_110_lava_hazard_runtime_e2e_closure.md
```

Diff stat final :

```text
 .../test/hazard_runtime_consumption_test.dart      |  26 +++
 ...urface_generated_gameplay_zone_bridge_test.dart | 196 ++++++++++++++++++---
 2 files changed, 202 insertions(+), 20 deletions(-)
```

## 22. Périmètre explicitement non touché

Confirmé :

- map_editor production non modifié ;
- map_runtime production non modifié ;
- map_core production non modifié ;
- map_battle non modifié ;
- map_gameplay production non modifié ;
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
- aucune action editor nouvelle ;
- aucun dialog editor nouveau ;
- aucun runtime PlayableMapGame modifié ;
- aucun feedback runtime Flutter ;
- aucune mutation GameState / party / HP ;
- aucun ice / mud codé ;
- aucune migration legacy ;
- aucun filtre surfacePresetId dans MapGameplayZone.

## 23. ctx stats

Commande demandée :

```text
ctx stats
```

Résultat shell :

```text
zsh:1: command not found: ctx
```

Context Mode MCP était disponible et utilisé. Résumé `ctx_stats` MCP :

```text
2.5M tokens saved · 88.4% reduction · 15h 5m
Without context-mode: 10.9 MB
With context-mode: 1.3 MB
9.7 MB kept out of the conversation
200 calls
v1.0.100
```

`ctx_doctor` MCP :

```text
Runtimes: 7/11
Server test: PASS
FTS5 / SQLite: PASS
Hook script: PASS
Version: v1.0.100
```

## 24. Limites restantes

- `PlayableMapGame` ne lit pas encore `Moved.hazardEffect`.
- Aucun feedback visuel runtime lava n'est affiché.
- Aucun dégât réel n'est appliqué à la party / HP / `GameState`.
- Aucun workflow ice / mud n'est codé.
- Aucune migration legacy n'est traitée.
- Pas de validation automatique que le preset visuel sélectionné est réellement lava.

Ces limites sont hors périmètre du Lot 110.

## 25. Auto-critique

- Est-ce que Surface lava seule reste visuelle ? Oui.
- Est-ce que generated lava hazard produit GameplayHazardEffect ? Oui.
- Est-ce que damagePerStep est transmis ? Oui.
- Est-ce que damagePerStep custom est testé ? Oui.
- Est-ce que damagePerStep <= 0 ne produit pas d'effet ? Oui.
- Est-ce que mouvement bloqué ne déclenche pas hazard ? Oui.
- Est-ce que SurfaceLayer reste inchangé ? Oui.
- Est-ce que les generated zones viennent de createSurfaceGameplayZoneGenerationPlan ? Oui.
- Est-ce qu'aucun code de production n'a été modifié ? Oui.
- Est-ce que les tests lava closure passent ? Oui.
- Est-ce que hazard_runtime_consumption_test.dart passe ? Oui.
- Est-ce que les régressions editor lava/tall grass/water passent ? Oui.
- Est-ce que les régressions map_core passent ? Oui.
- Est-ce que l'analyse ciblée passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui, avec l'échec CLI et les stats MCP.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui pour les fichiers modifiés ; le rapport créé est exclu de sa propre recopie par exception de récursion.
- Est-ce qu'un Lot 110-bis est nécessaire ? Non. Lava V0 est fermé côté preuve gameplay ciblée.

Review critique séparée :

- Risque principal : `surface_generated_gameplay_zone_bridge_test.dart` devient plus dense. Accepté pour ce lot car il concentre déjà la preuve bridge Surface -> GameplayZone pour water et tall grass.
- Le test `generated lava hazard zones are consumed by hazard effects` vérifie que `effect.zoneId` appartient aux zones générées plutôt que d'imposer une position de rectangle exacte. C'est volontaire : le test valide le contrat gameplay sans figer l'algorithme interne de découpe au-delà de `greedyRectangles`.
- Aucun helper de production n'a été créé pour factoriser les fixtures, afin de garder la clôture en test-only.

## 26. Regard critique sur le prompt

Le prompt est bien borné : il empêche d'étendre lava vers le runtime Flutter ou les dégâts réels, et force la preuve manquante entre authoring et gameplay. La contrainte la plus utile est la distinction entre `SurfaceLayer` visuelle et `MapGameplayZone` gameplay : elle évite de transformer les surfaces en seconde source gameplay implicite.

Le seul point à surveiller pour les lots suivants : après trois comportements, les tests bridge gagnent en taille. Si ice/mud suivent, il faudra peut-être extraire des helpers de test, sans déplacer de logique métier.

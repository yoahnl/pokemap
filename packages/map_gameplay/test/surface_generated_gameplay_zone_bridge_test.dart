import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('surface generated gameplay zone bridge', () {
    test('SurfaceLayer alone stays visual for water and tall grass', () {
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

MapData _baseSurfaceMap() {
  return const MapData(
    id: 'route_1',
    name: 'Route 1',
    size: GridSize(width: 4, height: 3),
    layers: [
      MapLayer.tile(
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
        collisions: [
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
      SurfaceLayer(
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
      ],
    ),
  );
}

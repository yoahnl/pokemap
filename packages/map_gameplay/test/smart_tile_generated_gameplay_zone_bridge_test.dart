import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile generated gameplay zone bridge', () {
    test('SmartTileLayer alone stays visual for water, grass, and lava', () {
      final map = _baseSmartTileMap();
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
      final map = _baseSmartTileMap();
      final project = _project();
      final plan = _waterGenerationPlan(map);
      final originalSmartTileCells = _smartTileLayer(map).field.semanticCells;

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
      expect(
        _smartTileLayer(mapWithZones).field.semanticCells,
        originalSmartTileCells,
      );

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
      final map = _baseSmartTileMap();
      final project = _project();
      final plan = _tallGrassGenerationPlan(map);
      final originalSmartTileCells = _smartTileLayer(map).field.semanticCells;

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
      expect(
        _smartTileLayer(mapWithZones).field.semanticCells,
        originalSmartTileCells,
      );

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

    test('authored encounter rate is used when no test override is provided',
        () {
      final map = _baseSmartTileMap();
      final plan = _tallGrassGenerationPlan(map);
      final project = _project().copyWith(
        encounterTables: <ProjectEncounterTable>[
          _project().encounterTables.single.copyWith(chancePerStep: 0),
        ],
      );
      final world = GameplayWorldState.initial(
        map: map.copyWith(gameplayZones: plan.generatedZones),
        playerPos: const GridPos(x: 0, y: 1),
        project: project,
      );

      final result = checkEncounterAtPlayerPosition(
        world: world,
        project: project,
        encounterKind: EncounterKind.walk,
        random: Random(1),
      );

      expect(result.status, GameplayEncounterCheckStatus.rollFailed);
    });

    test('authored conditions fail closed and unlock from real game state', () {
      final map = _baseSmartTileMap();
      final plan = _tallGrassGenerationPlan(map);
      final project = _project().copyWith(
        encounterTables: <ProjectEncounterTable>[
          _project().encounterTables.single.copyWith(
            chancePerStep: 1,
            conditions: <ScriptCondition>[
              ScriptConditionFactory.flagIsSet('route_1_open'),
            ],
          ),
        ],
      );
      final world = GameplayWorldState.initial(
        map: map.copyWith(gameplayZones: plan.generatedZones),
        playerPos: const GridPos(x: 0, y: 1),
        project: project,
      );

      final withoutContext = checkEncounterAtPlayerPosition(
        world: world,
        project: project,
        encounterKind: EncounterKind.walk,
        random: Random(1),
      );
      final locked = checkEncounterAtPlayerPosition(
        world: world,
        project: project,
        encounterKind: EncounterKind.walk,
        gameState: const GameState(saveId: 'save'),
        random: Random(1),
      );
      final unlocked = checkEncounterAtPlayerPosition(
        world: world,
        project: project,
        encounterKind: EncounterKind.walk,
        gameState: const GameState(
          saveId: 'save',
          storyFlags: StoryFlags(activeFlags: <String>{'route_1_open'}),
        ),
        random: Random(1),
      );

      expect(
        withoutContext.status,
        GameplayEncounterCheckStatus.conditionContextUnavailable,
      );
      expect(locked.status, GameplayEncounterCheckStatus.conditionsNotMet);
      expect(unlocked.status, GameplayEncounterCheckStatus.triggered);
    });

    test('surf checks do not reuse walk zones outside authored water', () {
      final map = _baseSmartTileMap();
      final plan = _tallGrassGenerationPlan(map);
      final project = _project();
      final world = GameplayWorldState.initial(
        map: map.copyWith(gameplayZones: plan.generatedZones),
        playerPos: const GridPos(x: 0, y: 1),
        playerMovementMode: MovementMode.surf,
        project: project,
      );

      final result = checkEncounterAtPlayerPosition(
        world: world,
        project: project,
        encounterKind: EncounterKind.surf,
        gameState: const GameState(
          saveId: 'save',
          playerMovementMode: MovementMode.surf,
        ),
        random: Random(1),
      );

      expect(result.status, GameplayEncounterCheckStatus.noZone);
    });

    test('generated lava hazard zones are consumed by hazard effects', () {
      final map = _baseSmartTileMap();
      final project = _project();
      final plan = _lavaGenerationPlan(map);
      final originalSmartTileCells = _smartTileLayer(map).field.semanticCells;

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
      expect(
        _smartTileLayer(mapWithZones).field.semanticCells,
        originalSmartTileCells,
      );

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
      final map = _baseSmartTileMap();
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
      final map = _baseSmartTileMap(blockLavaTarget: true);
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

SmartTileGameplayZoneGenerationPlan _waterGenerationPlan(MapData map) {
  return createSmartTileGameplayZoneGenerationPlan(
    source: _sourceForMaterial(map, 'water'),
    behavior: const SmartTileGameplayZoneBehaviorDraft.movement(
      MovementZonePayload(requiredMode: MovementMode.surf),
    ),
    strategy: SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'water-surf',
    zoneNamePrefix: 'Water - Surf',
    existingZones: map.gameplayZones,
  );
}

SmartTileGameplayZoneGenerationPlan _tallGrassGenerationPlan(MapData map) {
  return createSmartTileGameplayZoneGenerationPlan(
    source: _sourceForMaterial(map, 'tall_grass'),
    behavior: const SmartTileGameplayZoneBehaviorDraft.encounter(
      EncounterZonePayload(
        encounterTableId: 'route_1_grass',
        encounterKind: EncounterKind.walk,
      ),
    ),
    strategy: SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'tall-grass-encounter',
    zoneNamePrefix: 'Tall Grass - Rencontre',
    existingZones: map.gameplayZones,
  );
}

SmartTileGameplayZoneGenerationPlan _lavaGenerationPlan(
  MapData map, {
  int damagePerStep = 5,
}) {
  return createSmartTileGameplayZoneGenerationPlan(
    source: _sourceForMaterial(map, 'lava'),
    behavior: SmartTileGameplayZoneBehaviorDraft.hazard(
      HazardZonePayload(
        hazardKind: HazardKind.lava,
        damagePerStep: damagePerStep,
      ),
    ),
    strategy: SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'lava-hazard',
    zoneNamePrefix: 'Lava - Hazard',
    existingZones: map.gameplayZones,
  );
}

SmartTileGameplayZoneGenerationSource _sourceForMaterial(
  MapData map,
  String materialId,
) {
  final layer = _smartTileLayer(map);
  final materialValue = layer.materialPalette.indexOf(materialId);
  final cells = layer.field.semanticCells.indexed
      .where((entry) => entry.$2 == materialValue)
      .map(
        (entry) => GridPos(
          x: entry.$1 % map.size.width,
          y: entry.$1 ~/ map.size.width,
        ),
      )
      .toList(growable: false);

  return SmartTileGameplayZoneGenerationSource(
    smartTileLayerId: layer.id,
    smartTileLayerName: layer.name,
    smartTilePresetId: layer.presetId,
    materialId: materialId,
    cells: cells,
    mapSize: map.size,
  );
}

SmartTileLayer _smartTileLayer(MapData map) {
  return map.layers.whereType<SmartTileLayer>().single;
}

MapData _baseSmartTileMap({bool blockLavaTarget = false}) {
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
      const SmartTileLayer(
        id: 'smart-terrain-main',
        name: 'Smart terrain',
        presetId: 'terrain-materials',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'water', 'tall_grass', 'lava'],
        field: SmartTileField.cell(
          semanticCells: <int>[
            0,
            1,
            1,
            0,
            2,
            2,
            3,
            3,
            0,
            0,
            3,
            0,
          ],
        ),
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
  );
}

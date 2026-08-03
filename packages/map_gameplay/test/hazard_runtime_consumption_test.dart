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

    test('generated lava zones from Smart Tile plan produce hazard effect', () {
      final map = _smartTileMap();
      final smartTileLayer = map.layers.whereType<SmartTileLayer>().single;
      final originalCells = smartTileLayer.field.semanticCells;
      final plan = createSmartTileGameplayZoneGenerationPlan(
        source: SmartTileGameplayZoneGenerationSource(
          smartTileLayerId: smartTileLayer.id,
          smartTileLayerName: smartTileLayer.name,
          smartTilePresetId: smartTileLayer.presetId,
          materialId: 'lava',
          cells: smartTileLayer.field.semanticCells.indexed
              .where((entry) => entry.$2 == 1)
              .map((entry) => GridPos(x: entry.$1, y: 0))
              .toList(growable: false),
          mapSize: map.size,
        ),
        behavior: const SmartTileGameplayZoneBehaviorDraft.hazard(
          HazardZonePayload(
            hazardKind: HazardKind.lava,
            damagePerStep: 5,
          ),
        ),
        strategy: SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
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
            .whereType<SmartTileLayer>()
            .single
            .field
            .semanticCells,
        originalCells,
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

MapData _smartTileMap() {
  return const MapData(
    id: 'smart_tile_lava_map',
    name: 'Smart Tile Lava Map',
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
      SmartTileLayer(
        id: 'smart-terrain-main',
        name: 'Smart terrain',
        presetId: 'terrain-materials',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'lava'],
        field: SmartTileField.cell(semanticCells: <int>[0, 1, 0]),
      ),
    ],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Hazard Project',
    maps: const [],
    tilesets: const [],
  );
}

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('path animation triggers', () {
    test('onStep emits trigger signal on successful movement', () {
      final world = GameplayWorldState.initial(
        map: _map(
          pathCells: const [false, true, false, false, false, false],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithTrigger(
          const PathAnimationTriggerRule(
            id: 'step_rule',
            trigger: PathAnimationTriggerType.onStep,
            mode: PathAnimationPlaybackMode.restartOnTrigger,
          ),
        ),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Moved>());
      expect(result.pathAnimationSignals.length, 1);
      final signal = result.pathAnimationSignals.first;
      expect(signal.kind, PathAnimationSignalKind.trigger);
      expect(signal.ruleId, 'step_rule');
      expect(signal.trigger, PathAnimationTriggerType.onStep);
      expect(signal.mode, PathAnimationPlaybackMode.restartOnTrigger);
    });

    test('onEnter triggers only when entering path area', () {
      final world = GameplayWorldState.initial(
        map: _map(
          pathCells: const [false, true, true, false, false, false],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithTrigger(
          const PathAnimationTriggerRule(
            id: 'enter_rule',
            trigger: PathAnimationTriggerType.onEnter,
            mode: PathAnimationPlaybackMode.playOnce,
          ),
        ),
      );

      final first = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(first.pathAnimationSignals.length, 1);
      expect(first.pathAnimationSignals.first.ruleId, 'enter_rule');

      final second = stepGameplayWorld(
        first.world,
        const MoveIntent(Direction.east),
      );
      expect(second, isA<Moved>());
      expect(second.pathAnimationSignals, isEmpty);
    });

    test('onNear triggers only on outside to near transition', () {
      final world = GameplayWorldState.initial(
        map: _map(
          size: const GridSize(width: 5, height: 3),
          pathCells: const [
            false,
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
            false,
            false,
          ],
        ),
        playerPos: const GridPos(x: 0, y: 1),
        project: _projectWithTrigger(
          const PathAnimationTriggerRule(
            id: 'near_rule',
            trigger: PathAnimationTriggerType.onNear,
            mode: PathAnimationPlaybackMode.playOnce,
          ),
        ),
      );

      final first = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(first.pathAnimationSignals, isEmpty);

      final second =
          stepGameplayWorld(first.world, const MoveIntent(Direction.east));
      expect(second.pathAnimationSignals.length, 1);
      expect(second.pathAnimationSignals.first.trigger,
          PathAnimationTriggerType.onNear);

      final third =
          stepGameplayWorld(second.world, const MoveIntent(Direction.south));
      expect(third.pathAnimationSignals, isEmpty);
    });

    test('onAction emits trigger signal on interact', () {
      final world = GameplayWorldState.initial(
        map: _map(
          pathCells: const [false, true, false, false, false, false],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        playerFacing: Direction.east,
        project: _projectWithTrigger(
          const PathAnimationTriggerRule(
            id: 'action_rule',
            trigger: PathAnimationTriggerType.onAction,
            mode: PathAnimationPlaybackMode.playOnce,
          ),
        ),
      );

      final result = stepGameplayWorld(world, const InteractIntent());
      expect(result, isA<NothingToInteract>());
      expect(result.pathAnimationSignals.length, 1);
      expect(result.pathAnimationSignals.first.ruleId, 'action_rule');
    });

    test('whileInside emits setActive true/false transitions', () {
      final world = GameplayWorldState.initial(
        map: _map(
          pathCells: const [false, true, false, false, false, false],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithTrigger(
          const PathAnimationTriggerRule(
            id: 'inside_rule',
            trigger: PathAnimationTriggerType.whileInside,
            mode: PathAnimationPlaybackMode.loopWhileActive,
          ),
        ),
      );

      final enter = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(enter.pathAnimationSignals.length, 1);
      expect(enter.pathAnimationSignals.first.kind,
          PathAnimationSignalKind.setActive);
      expect(enter.pathAnimationSignals.first.active, isTrue);

      final exit = stepGameplayWorld(
        enter.world,
        const MoveIntent(Direction.west),
      );
      expect(exit.pathAnimationSignals.length, 1);
      expect(exit.pathAnimationSignals.first.kind,
          PathAnimationSignalKind.setActive);
      expect(exit.pathAnimationSignals.first.active, isFalse);
    });

    test('onBump emits trigger signal when movement is blocked', () {
      final world = GameplayWorldState.initial(
        map: _map(
          pathCells: const [false, true, false, false, false, false],
          collisionCells: const [false, true, false, false, false, false],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: _projectWithTrigger(
          const PathAnimationTriggerRule(
            id: 'bump_rule',
            trigger: PathAnimationTriggerType.onBump,
            mode: PathAnimationPlaybackMode.playOnce,
          ),
        ),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));
      expect(result, isA<Blocked>());
      expect(result.pathAnimationSignals.length, 1);
      expect(result.pathAnimationSignals.first.ruleId, 'bump_rule');
    });
  });
}

MapData _map({
  GridSize size = const GridSize(width: 3, height: 2),
  required List<bool> pathCells,
  List<bool>? collisionCells,
}) {
  final cellCount = size.width * size.height;
  final paddedPaths = List<bool>.filled(cellCount, false, growable: false);
  for (var i = 0; i < pathCells.length && i < cellCount; i++) {
    paddedPaths[i] = pathCells[i];
  }
  final paddedCollisions = List<bool>.filled(cellCount, false, growable: false);
  final sourceCollisions = collisionCells ?? const <bool>[];
  for (var i = 0; i < sourceCollisions.length && i < cellCount; i++) {
    paddedCollisions[i] = sourceCollisions[i];
  }
  return MapData(
    id: 'map',
    name: 'Map',
    size: size,
    layers: [
      MapLayer.tile(
        id: 'tile',
        name: 'Tile',
        tiles: List<int>.filled(cellCount, 0, growable: false),
      ),
      MapLayer.path(
        id: 'path_layer',
        name: 'Path',
        presetId: 'water_path',
        cells: paddedPaths,
      ),
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: paddedCollisions,
      ),
    ],
  );
}

ProjectManifest _projectWithTrigger(PathAnimationTriggerRule trigger) {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'outdoor',
        name: 'Outdoor',
        relativePath: 'tilesets/outdoor.png',
      ),
    ],
    pathPresets: [
      ProjectPathPreset(
        id: 'water_path',
        name: 'Water',
        tilesetId: 'outdoor',
        variants: const [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.horizontal,
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
                durationMs: 100,
              ),
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 1, y: 0),
                durationMs: 100,
              ),
            ],
          ),
        ],
        animationTriggers: [trigger],
      ),
    ],
  );
}

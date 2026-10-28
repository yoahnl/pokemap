import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerComponent visual convention', () {
    test('avatar replacement changes rendering without moving the collision body', () async {
      ProjectCharacterEntry character(String id, bool running, int width) => ProjectCharacterEntry(
        id: id, name: id, tilesetId: 'unused', frameWidth: width,
        animations: [
          for (final direction in EntityFacing.values)
            for (final state in [CharacterAnimationState.idle, CharacterAnimationState.walk, if (running) CharacterAnimationState.run])
              CharacterAnimation(state: state, direction: direction, sourceAssetId: id,
                frames: const [CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32), durationMs: 100)]),
        ],
      );
      final old = character('hero', true, 2);
      final next = character('costume', false, 4);
      final component = PlayerComponent(bundle: _bundle(), state: _stateAt(const GridPos(x: 2, y: 3)),
        characterEntry: old, tileImages: {characterAnimationRuntimeImageId('hero'): _emptyImage()}, mapOrigin: Vector2(9, 11));
      await component.onLoad();
      component.setCinematicFacing(EntityFacing.east);
      component.setCinematicJumpLift(7);
      final position = component.position.clone();
      final size = component.size.clone();
      expect(component.hasRunningAnimation, isTrue);
      component.replaceCharacter(next, {characterAnimationRuntimeImageId('costume'): _emptyImage()});
      expect(component.characterEntry!.id, 'costume');
      expect(component.debugAnimationSource!.imageId, characterAnimationRuntimeImageId('costume'));
      expect(component.position, position);
      expect(component.size, size);
      expect(component.cinematicFacing, EntityFacing.east);
      expect(component.cinematicJumpLift, 7);
      expect(component.hasRunningAnimation, isFalse);
    });
    test('bicycle uses dedicated clips in eight slots and keeps phase through adjacent steps', () async {
      final character = ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'hero',
        animations: [for (final state in [CharacterAnimationState.bicycleIdle, CharacterAnimationState.bicycle])
          for (final direction in EntityFacing.values) CharacterAnimation(state: state,
            direction: direction, sourceAssetId: 'cycle', frames: [
              for (var i = 0; i < 4; i++) CharacterAnimationFrame(
                source: TilesetSourceRect(x: i * 32, y: 0, width: 32, height: 32), durationMs: 100)])]);
      final initial = _stateAt(const GridPos(x: 0, y: 0)).copyWith(movementMode: MovementMode.bicycle);
      final component = PlayerComponent(bundle: _bundle(), state: initial, characterEntry: character,
        tileImages: {characterAnimationRuntimeImageId('cycle'): _emptyImage()}, mapOrigin: Vector2.zero());
      await component.onLoad();
      expect(component.hasBicycleAnimations, isTrue);
      for (var step = 1; step <= 2; step++) {
        component.startStep(_stateAt(GridPos(x: step, y: 0)).copyWith(movementMode: MovementMode.bicycle),
          durationSeconds: PlayerComponent.kBicycleStepSeconds, animationState: CharacterAnimationState.bicycle);
        component.update(PlayerComponent.kBicycleStepSeconds);
      }
      expect(component.debugAnimationSource?.imageId, characterAnimationRuntimeImageId('cycle'));
      final actor = OverworldActorComponent(character: character,
        tileImages: {characterAnimationRuntimeImageId('cycle'): _emptyImage()},
        tileWidth: 16, tileHeight: 16, cellWidth: 16, cellHeight: 16,
        facing: EntityFacing.south);
      for (var step = 0; step < 2; step++) {
        actor.setMotion(EntityFacing.south, CharacterAnimationState.bicycle);
        actor.update(PlayerComponent.kBicycleStepSeconds);
        actor.setMotion(EntityFacing.south, CharacterAnimationState.bicycleIdle);
      }
      expect(actor.debugAnimationSource?.sourceRect.left, 32);
      final incomplete = PlayerComponent(bundle: _bundle(), state: initial,
        characterEntry: character.copyWith(animations: character.animations.skip(1).toList()),
        tileImages: {characterAnimationRuntimeImageId('cycle'): _emptyImage()}, mapOrigin: Vector2.zero());
      expect(incomplete.hasBicycleAnimations, isFalse);
      final noSources = PlayerComponent(bundle: _bundle(), state: initial,
        characterEntry: character, tileImages: {}, mapOrigin: Vector2.zero());
      expect(noSources.hasBicycleAnimations, isFalse);
    });
    test('player actor offset is not applied twice', () async {
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        characterEntry: const ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'hero',
          frameWidth: 2,
          frameHeight: 2,
        ),
        tileImages: const {},
        mapOrigin: Vector2.zero(),
      );

      await component.onLoad();

      expect(component.debugActorLocalPosition, isNotNull);
      expect(component.debugActorLocalPosition!.x, 0);
      expect(component.debugActorLocalPosition!.y, 0);
    });

    test('default walk and run match the Kanto reference cadence', () async {
      expect(PlayerComponent.kDefaultStepSeconds, .25);
      expect(PlayerComponent.kRunStepSeconds, .125);
      for (final duration in [PlayerComponent.kDefaultStepSeconds, PlayerComponent.kRunStepSeconds]) {
        final component = PlayerComponent(bundle: _bundle(),
          state: _stateAt(const GridPos(x: 0, y: 0)),
          tileImages: const {}, mapOrigin: Vector2.zero());
        await component.onLoad();
        final start = component.position.x;
        component.startStep(_stateAt(const GridPos(x: 1, y: 0)), durationSeconds: duration);
        component.update(duration / 2);
        final halfway = component.position.x;
        expect(component.isStepping, isTrue);
        component.update(duration / 2);
        expect(component.isStepping, isFalse);
        expect(halfway - start, closeTo((component.position.x - start) / 2, .000001));
      }
    });

    test('subdivided quarter-second step completes exactly at its endpoint', () async {
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        tileImages: const {},
        mapOrigin: Vector2.zero(),
      );
      await component.onLoad();
      final initialY = component.position.y;
      component.startStep(_stateAt(const GridPos(x: 1, y: 0)), durationSeconds: .25);
      for (var index = 0; index < 14; index++) {
        component.update(1 / 60);
      }
      expect(component.isStepping, isTrue);
      component.update(1 / 60);
      expect(component.isStepping, isFalse);
      expect(component.position.x, 16);
      expect(component.position.y, initialY);
    });

    test('cardinal step has stable frame deltas', () async {
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        tileImages: const {},
        mapOrigin: Vector2.zero(),
      );

      await component.onLoad();

      final nextState = _stateAt(const GridPos(x: 1, y: 0));
      final positions = <double>[component.position.x];

      component.startStep(nextState, durationSeconds: 0.12);
      for (var i = 0; i < 6; i++) {
        component.update(0.02);
        positions.add(component.position.x);
      }

      final deltas = <double>[
        for (var i = 1; i < positions.length; i++)
          positions[i] - positions[i - 1],
      ];
      final nonZeroDeltas =
          deltas.where((delta) => delta.abs() > 0.0001).toList();

      expect(nonZeroDeltas, isNotEmpty);
      final minDelta = nonZeroDeltas.reduce((a, b) => a < b ? a : b);
      final maxDelta = nonZeroDeltas.reduce((a, b) => a > b ? a : b);
      expect(maxDelta - minDelta, lessThan(0.0001));
      expect(component.position.x, closeTo(16, 0.0001));
    });

    test('connection entry preserves the current running animation', () async {
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        tileImages: const {},
        mapOrigin: Vector2.zero(),
      );
      await component.onLoad();
      component.startStep(_stateAt(const GridPos(x: 1, y: 0)),
        durationSeconds: PlayerComponent.kRunStepSeconds,
        animationState: CharacterAnimationState.run);
      component.startVisualStepFromWorldTopLeft(
        _stateAt(const GridPos(x: 2, y: 0)),
        fromWorldTopLeft: Vector2(16, 0),
        durationSeconds: PlayerComponent.kRunStepSeconds,
      );
      expect(component.debugStepAnimationState, CharacterAnimationState.run);
      component.update(.016);
      expect(component.position.x, greaterThan(16));
    });

    test('normal overworld walk step progresses on the first update', () async {
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        tileImages: const {},
        mapOrigin: Vector2.zero(),
      );

      await component.onLoad();

      final initialX = component.position.x;
      component.startStep(
        _stateAt(const GridPos(x: 1, y: 0)),
        durationSeconds: 0.12,
      );
      component.update(0.02);

      expect(component.position.x, greaterThan(initialX));
      expect(component.position.x, lessThan(16));
    });

    test('consecutive legacy walk steps keep the same cadence', () async {
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        characterEntry: _legacyCharacter(),
        tileImages: const {},
        mapOrigin: Vector2.zero(),
      );

      await component.onLoad();

      final firstStepStartX = component.position.x;
      component.startStep(
        _stateAt(const GridPos(x: 1, y: 0)),
        durationSeconds: 0.12,
      );
      component.update(0.02);
      final firstStepDelta = component.position.x - firstStepStartX;
      for (var i = 1; i < 6; i++) {
        component.update(0.02);
      }
      expect(component.position.x, closeTo(16, 0.0001));

      final secondStepStartX = component.position.x;
      component.startStep(
        _stateAt(const GridPos(x: 2, y: 0)),
        durationSeconds: 0.12,
      );
      component.update(0.02);

      final secondStepDelta = component.position.x - secondStepStartX;
      expect(secondStepDelta, closeTo(firstStepDelta, 0.0001));
    });

    test('dedicated source wins and keeps pixel geometry', () async {
      const character = ProjectCharacterEntry(
        id: 'player',
        name: 'Player',
        tilesetId: 'hero',
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            sourceAssetId: 'hero_idle',
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(
                source: TilesetSourceRect(
                  x: 17,
                  y: 9,
                  width: 23,
                  height: 31,
                ),
              ),
            ],
          ),
        ],
      );
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        characterEntry: character,
        tileImages: <String, RuntimeTilesetImage>{
          'hero': _emptyImage(),
          characterAnimationRuntimeImageId('hero_idle'): _emptyImage(),
        },
        mapOrigin: Vector2.zero(),
      );

      await component.onLoad();

      expect(
        component.debugAnimationSource?.imageId,
        characterAnimationRuntimeImageId('hero_idle'),
      );
      expect(component.debugAnimationSource?.sourceRect.left, 17);
      expect(component.debugAnimationSource?.sourceRect.top, 9);
      expect(component.debugAnimationSource?.sourceRect.width, 23);
      expect(component.debugAnimationSource?.sourceRect.height, 31);
    });

    test('missing dedicated walk source falls back to legacy base', () async {
      const character = ProjectCharacterEntry(
        id: 'player',
        name: 'Player',
        tilesetId: 'hero',
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.east,
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
              ),
            ],
          ),
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: EntityFacing.east,
            sourceAssetId: 'hero_walk',
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(
                source: TilesetSourceRect(
                  x: 24,
                  y: 0,
                  width: 24,
                  height: 32,
                ),
              ),
            ],
          ),
        ],
      );
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        characterEntry: character,
        tileImages: <String, RuntimeTilesetImage>{'hero': _emptyImage()},
        mapOrigin: Vector2.zero(),
      );

      await component.onLoad();
      component.startStep(_stateAt(const GridPos(x: 1, y: 0)));

      expect(component.debugAnimationSource?.imageId, 'hero');
      expect(component.debugAnimationSource?.usesLegacyGrid, isTrue);
    });

    test('run step selects the dedicated run source and faster cadence',
        () async {
      const character = ProjectCharacterEntry(
        id: 'player',
        name: 'Player',
        tilesetId: 'hero',
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.run,
            direction: EntityFacing.east,
            sourceAssetId: 'hero_run',
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 64, y: 0, width: 64, height: 64),
              ),
            ],
          ),
        ],
      );
      final component = PlayerComponent(
        bundle: _bundle(),
        state: _stateAt(const GridPos(x: 0, y: 0)),
        characterEntry: character,
        tileImages: <String, RuntimeTilesetImage>{
          'hero': _emptyImage(),
          characterAnimationRuntimeImageId('hero_run'): _emptyImage(),
        },
        mapOrigin: Vector2.zero(),
      );

      await component.onLoad();
      component.startStep(
        _stateAt(const GridPos(x: 1, y: 0)),
        durationSeconds: PlayerComponent.kRunStepSeconds,
        animationState: CharacterAnimationState.run,
      );

      expect(component.debugStepAnimationState, CharacterAnimationState.run);
      expect(
        component.debugAnimationSource?.imageId,
        characterAnimationRuntimeImageId('hero_run'),
      );
      expect(
        PlayerComponent.kRunStepSeconds,
        lessThan(PlayerComponent.kDefaultStepSeconds),
      );
    });
  });
}

RuntimeTilesetImage _emptyImage() {
  return RuntimeTilesetImage(
    images: const [],
    chunks: const [],
    width: 128,
    height: 128,
  );
}

ProjectCharacterEntry _legacyCharacter() {
  return const ProjectCharacterEntry(
    id: 'player',
    name: 'Player',
    tilesetId: 'hero',
    animations: <CharacterAnimation>[
      CharacterAnimation(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.east,
        frames: <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
          ),
        ],
      ),
      CharacterAnimation(
        state: CharacterAnimationState.walk,
        direction: EntityFacing.east,
        frames: <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 2),
          ),
        ],
      ),
    ],
  );
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Player Component Test Project',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'test_map',
          name: 'Test Map',
          relativePath: 'maps/test_map.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
      settings: ProjectSettings(tileWidth: 16, tileHeight: 16, displayScale: 2),
    ),
    map: const MapData(
      id: 'test_map',
      name: 'Test Map',
      size: GridSize(width: 3, height: 2),
    ),
    projectRootDirectory: '/tmp',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

GameplayPlayerState _stateAt(GridPos cell) {
  return GameplayPlayerState.fromGridSpawn(
    cell: cell,
    facing: Direction.south,
    tileWidthPx: 16,
    tileHeightPx: 16,
    mapWidthCells: 3,
    mapHeightCells: 2,
  );
}

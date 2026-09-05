import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerComponent visual convention', () {
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

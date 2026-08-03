import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show RuntimeMapBundleLoader;

const _sourceMapId = 'transaction_source';
const _targetMapId = 'transaction_target';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame transactional load', () {
    test('commits a fully prepared valid save', () async {
      final repository = _MemoryGameSaveRepository(_targetState());
      final game = _game(
        repository: repository,
        runtimeMapBundleLoader: _targetLoader,
      );
      await _load(game);

      expect(await game.loadGame(), isTrue);

      expect(game.gameStateSnapshot.saveId, 'target-save');
      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 2, y: 2));
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugNotificationText, isNull);
    });

    test('corrupt save failure preserves the running world and save', () async {
      final repository = _CorruptGameSaveRepository();
      final game = _game(repository: repository);
      await _load(game);
      final before = game.gameStateSnapshot;

      expect(await game.loadGame(), isFalse);

      _expectSourceRuntimePreserved(game, before);
      expect(repository.loadCount, 1);
      expect(repository.deleteCount, 0);
      expect(repository.saveCount, 0);
      expect(
        game.debugNotificationText,
        contains('sauvegarde'),
        reason: 'The player needs an actionable load error.',
      );
    });

    test('missing target map preserves state, world and gameplay input',
        () async {
      final repository = _MemoryGameSaveRepository(_targetState());
      final game = _game(
        repository: repository,
        runtimeMapBundleLoader: ({
          required String projectFilePath,
          required String mapId,
        }) async {
          throw StateError('Map $mapId is absent');
        },
      );
      await _load(game);
      final before = game.gameStateSnapshot;

      expect(await game.loadGame(), isFalse);

      _expectSourceRuntimePreserved(game, before);
      expect(repository.storedState, _targetState());
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );
    });

    test('invalid target layer is rejected before destructive mutation',
        () async {
      final repository = _MemoryGameSaveRepository(_targetState());
      final game = _game(
        repository: repository,
        runtimeMapBundleLoader: ({
          required String projectFilePath,
          required String mapId,
        }) async {
          throw const FormatException(
            'Layer ground has an invalid cell count.',
          );
        },
      );
      await _load(game);
      final before = game.gameStateSnapshot;

      expect(await game.loadGame(), isFalse);

      _expectSourceRuntimePreserved(game, before);
      expect(repository.storedState, _targetState());
      expect(repository.saveCount, 0);
    });

    test('reconstruction failure rolls back, then a retry commits', () async {
      final repository = _MemoryGameSaveRepository(_targetState());
      var attempts = 0;
      final game = _game(
        repository: repository,
        runtimeMapBundleLoader: _targetLoader,
        beforeLoadCommitCompletion: () async {
          attempts++;
          if (attempts == 1) {
            throw StateError('Injected reconstruction failure');
          }
        },
      );
      await _load(game);
      final before = game.gameStateSnapshot;

      expect(await game.loadGame(), isFalse);
      _expectSourceRuntimePreserved(game, before);
      expect(repository.storedState, _targetState());
      expect(repository.saveCount, 0);

      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
      expect(repository.storedState?.currentMapId, _sourceMapId);
      repository.storedState = _targetState();

      expect(await game.loadGame(), isTrue);
      expect(attempts, 2);
      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 2, y: 2));
      expect(game.debugFlowPhaseName, 'overworld');
    });
  });
}

void _expectSourceRuntimePreserved(PlayableMapGame game, GameState before) {
  expect(game.gameStateSnapshot, before);
  expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
  expect(game.debugPlayerGridPosition, before.playerPosition);
  expect(game.debugFlowPhaseName, 'overworld');
  expect(game.debugIsGameplayInputLocked, isFalse);
}

_TestPlayableMapGame _game({
  required GameSaveRepository repository,
  RuntimeMapBundleLoader? runtimeMapBundleLoader,
  Future<void> Function()? beforeLoadCommitCompletion,
}) {
  return _TestPlayableMapGame(
    bundle: _bundle(_sourceMapId),
    projectFilePath: '/tmp/load_transaction/project.json',
    saveData: saveDataFromGameState(_sourceState()),
    saveRepository: repository,
    runtimeMapBundleLoader: runtimeMapBundleLoader,
    beforeLoadCommitCompletion: beforeLoadCommitCompletion,
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.runtimeMapBundleLoader,
    super.beforeLoadCommitCompletion,
  });

  @override
  bool get isLoaded => true;
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for initial map activation.');
}

Future<RuntimeMapBundle> _targetLoader({
  required String projectFilePath,
  required String mapId,
}) async {
  expect(mapId, _targetMapId);
  return _bundle(_targetMapId);
}

RuntimeMapBundle _bundle(String mapId) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Load transaction fixture',
      tilesets: const <ProjectTilesetEntry>[],
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: mapId,
          name: mapId,
          relativePath: 'maps/$mapId.json',
        ),
      ],
    ),
    map: MapData(
      id: mapId,
      name: mapId,
      size: const GridSize(width: 5, height: 5),
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_$mapId',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: const GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: const MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_$mapId'),
    ),
    projectRootDirectory: '/tmp/load_transaction',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

GameState _sourceState() => const GameState(
      saveId: 'source-save',
      currentMapId: _sourceMapId,
      playerPosition: GridPos(x: 1, y: 1),
      playerFacing: EntityFacing.east,
      trainerProfile: TrainerProfile(name: 'Before load', money: 120),
    );

GameState _targetState() => const GameState(
      saveId: 'target-save',
      currentMapId: _targetMapId,
      playerPosition: GridPos(x: 2, y: 2),
      playerFacing: EntityFacing.south,
      trainerProfile: TrainerProfile(name: 'After load', money: 999),
    );

final class _MemoryGameSaveRepository implements GameSaveRepository {
  _MemoryGameSaveRepository(this.storedState);

  GameState? storedState;
  int saveCount = 0;

  @override
  Future<void> save(GameState state) async {
    saveCount++;
    storedState = state;
  }

  @override
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}

final class _CorruptGameSaveRepository implements GameSaveRepository {
  int loadCount = 0;
  int saveCount = 0;
  int deleteCount = 0;

  @override
  Future<void> save(GameState state) async {
    saveCount++;
  }

  @override
  Future<GameState?> load() async {
    loadCount++;
    throw const GameSaveException('Malformed JSON');
  }

  @override
  Future<bool> exists() async => true;

  @override
  Future<void> delete() async {
    deleteCount++;
  }
}

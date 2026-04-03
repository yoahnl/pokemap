import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame public getters before onLoad', () {
    test('playerMovementMode and isSurfing are safe without world init', () {
      final game = PlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      expect(() => game.playerMovementMode, returnsNormally);
      expect(game.playerMovementMode, MovementMode.walk);
      expect(() => game.isSurfing, returnsNormally);
      expect(game.isSurfing, isFalse);
      expect(() => game.saveLoadInfo, returnsNormally);
      expect(game.saveLoadInfo.movementMode, MovementMode.walk.name);
    });

    test('getters use normalized saveData movement mode before onLoad', () {
      const state = GameState(
        saveId: 'save-1',
        currentMapId: 'map_a',
        playerMovementMode: MovementMode.surf,
      );
      final game = PlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
        saveData: saveDataFromGameState(state),
      );

      expect(game.playerMovementMode, MovementMode.walk);
      expect(game.isSurfing, isFalse);
      expect(game.saveLoadInfo.movementMode, MovementMode.walk.name);
    });

    test('cutscene public API is safe before onLoad', () {
      final game = PlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
        runtimeCutscenes: const <RuntimeCutsceneAsset>[
          RuntimeCutsceneAsset(
            id: 'intro',
            name: 'Intro',
            steps: <RuntimeCutsceneStep>[
              CutsceneDialogueStep(dialogueId: 'intro_dialogue'),
            ],
          ),
        ],
      );

      expect(game.isCutsceneRunning, isFalse);
      expect(game.activeCutsceneId, isNull);
      expect(game.cutsceneStatus.state, CutsceneRunnerState.idle);

      // Tant que onLoad n'a pas initialisé le runtime world, on refuse le start.
      expect(game.startCutsceneById('intro'), isFalse);
      expect(game.isCutsceneRunning, isFalse);
    });
  });
}

RuntimeMapBundle _baseBundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Test Project',
      maps: [
        ProjectMapEntry(
          id: 'test_map',
          name: 'Test Map',
          relativePath: 'maps/test_map.json',
        ),
      ],
      tilesets: [],
    ),
    map: const MapData(
      id: 'test_map',
      name: 'Test Map',
      size: GridSize(width: 8, height: 8),
      layers: [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: '/tmp/project',
    tilesetAbsolutePathsById: const {},
  );
}

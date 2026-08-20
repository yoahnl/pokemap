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
      expect(game.isBattleUiActive, isFalse);
    });

    test('getters keep the saved movement mode before onLoad', () {
      // CHANGEMENT DE COMPORTEMENT ASSUMÉ, BETA-SYS-002, critère « save/reload ».
      //
      // Ce cas exigeait l'inverse : une sauvegarde faite en surfant se
      // rechargeait en mode MARCHE. Ce n'était pas un oubli — `SaveData` n'avait
      // pas de champ pour le mode, et `gameStateFromSaveData` écrivait
      // `MovementMode.walk` en dur.
      //
      // Conséquence côté joueur : sauvegarder au milieu d'un lac et recharger
      // faisait marcher le joueur sur l'eau. Ce n'était pas non plus une
      // protection utile, puisque la règle de mouvement n'interdit que d'ENTRER
      // dans l'eau : le joueur ressortait à pied.
      //
      // Le mode traverse désormais l'enveloppe de sauvegarde. Ce qui rend le
      // basculement sûr, c'est la sortie livrée par le même lot : recharger en
      // surf sur une case qui n'est plus de l'eau se corrige au premier pas.
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

      expect(game.playerMovementMode, MovementMode.surf);
      expect(game.isSurfing, isTrue);
      expect(game.saveLoadInfo.movementMode, MovementMode.surf.name);
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

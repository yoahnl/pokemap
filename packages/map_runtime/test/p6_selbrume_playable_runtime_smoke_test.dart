import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _routeMapId = 'route 1';
const _saveId = 'p6_08_selbrume_playable_runtime_smoke';
const _initialSpeciesId = 'pidgeotto';
const _initialAbilityId = 'keen_eye';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';
const _p603FlagId = 'p6.selbrume.first_interaction.seen';
const _p603StepId = 'p6.selbrume.first_interaction';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-08 boots repo-local Selbrume in PlayableMapGame without crashing',
    () async {
      final repoRoot = _findRepoRoot();
      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
      final projectFilePath = p.join(projectRoot.path, 'project.json');

      expect(await File(projectFilePath).exists(), isTrue);

      final selbrumeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _startMapId,
      );
      final routeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _routeMapId,
      );

      expect(
          selbrumeBundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(routeBundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(selbrumeBundle.map.id, _startMapId);
      expect(routeBundle.map.id, _routeMapId);
      expect(selbrumeBundle.tilesetAbsolutePathsById, isNotEmpty);
      expect(
        selbrumeBundle.tilesetAbsolutePathsById.values.every(
          (path) => File(path).existsSync(),
        ),
        isTrue,
      );

      final state = _buildSeededNewGameState(selbrumeBundle);
      final game = PlayableMapGame(
        bundle: selbrumeBundle,
        projectFilePath: projectFilePath,
        saveData: saveDataFromGameState(state),
      );

      expect(game.saveLoadInfo.mapId, _startMapId);
      expect(game.saveLoadInfo.playerX, 17);
      expect(game.saveLoadInfo.playerY, 24);
      expect(game.saveLoadInfo.facing, EntityFacing.south.name);
      expect(game.gameStateSnapshot.party.members.single.speciesId,
          _initialSpeciesId);
      expect(
          game.gameStateSnapshot.storyFlags.activeFlags, contains(_p603FlagId));

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      game.update(0);

      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsMapLoaded(_startMapId), isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 17, y: 24));

      final runtimeState = game.gameStateSnapshot;
      expect(runtimeState.saveId, _saveId);
      expect(runtimeState.currentMapId, _startMapId);
      expect(runtimeState.playerPosition, const GridPos(x: 17, y: 24));
      expect(runtimeState.playerFacing, EntityFacing.south);
      expect(runtimeState.party.members, hasLength(1));
      expect(runtimeState.party.members.single.speciesId, _initialSpeciesId);
      expect(runtimeState.party.members.single.level, 8);
      expect(runtimeState.party.members.single.currentHp, 24);
      expect(runtimeState.party.members.single.knownMoveIds, _initialMoves);
      expect(_bagQuantity(runtimeState, _captureItemId), 5);
      expect(_bagQuantity(runtimeState, _medicineItemId), 2);
      expect(runtimeState.storyFlags.activeFlags, contains(_p603FlagId));
      expect(
        runtimeState.progression.completedStepIds,
        contains(_p603StepId),
      );
      expect(runtimeState.trainerProfile.money, 0);
    },
  );
}

GameState _buildSeededNewGameState(RuntimeMapBundle bundle) {
  const mutations = GameStateMutations();
  var state = createNewGameStateFromMap(
    startMap: bundle.map,
    saveId: _saveId,
    playerName: 'P6 Tester',
    tileWidthPx: bundle.manifest.settings.tileWidth,
    tileHeightPx: bundle.manifest.settings.tileHeight,
  );
  state = mutations.givePokemon(
    state,
    pokemon: const PlayerPokemon(
      speciesId: _initialSpeciesId,
      natureId: 'hardy',
      abilityId: _initialAbilityId,
      level: 8,
      currentHp: 24,
      knownMoveIds: _initialMoves,
    ),
  );
  state = mutations.giveItem(state, _captureItemId, 5);
  state = mutations.giveItem(state, _medicineItemId, 2);
  state = mutations.setFlag(state, _p603FlagId);
  state = mutations.completeStep(state, _p603StepId);
  return state;
}

int _bagQuantity(GameState state, String itemId) {
  final entry = state.bag.normalized().entries.firstWhere(
        (candidate) => candidate.itemId == itemId,
        orElse: () =>
            BagEntry(itemId: itemId, categoryId: 'items', quantity: 0),
      );
  return entry.quantity;
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;

  while (true) {
    final candidate = File(
      p.join(current.path, 'selbrume', 'project.json'),
    );
    if (candidate.existsSync()) {
      return current;
    }

    final parent = current.parent.absolute;
    if (parent.path == current.path) {
      throw StateError('Could not find repo-local selbrume/project.json');
    }
    current = parent;
  }
}

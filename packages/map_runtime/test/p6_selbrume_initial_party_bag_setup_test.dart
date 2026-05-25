import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _spawnId = 'spawn';
const _saveId = 'p6_02_selbrume_initial_party_bag';
const _initialSpeciesId = 'pidgeotto';
const _initialAbilityId = 'keen_eye';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-02 builds repo-local Selbrume initial party and bag and roundtrips SaveData',
    () async {
      final repoRoot = _findRepoRoot();
      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
      final projectFilePath = p.join(projectRoot.path, 'project.json');

      expect(await File(projectFilePath).exists(), isTrue);

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _startMapId,
      );

      expect(bundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(bundle.map.id, _startMapId);

      final spawn = bundle.map.entities.singleWhere(
        (entity) => entity.id == _spawnId,
      );
      expect(spawn.kind, MapEntityKind.spawn);
      expect(spawn.pos, const GridPos(x: 17, y: 24));
      expect(spawn.spawn?.role, EntitySpawnRole.playerStart);
      expect(spawn.spawn?.facing, EntityFacing.south);

      final speciesJson = await _readSpeciesJsonById(
        projectRoot: projectRoot,
        speciesDir: bundle.manifest.pokemon.speciesDir,
        speciesId: _initialSpeciesId,
      );
      expect(speciesJson['id'], _initialSpeciesId);
      expect(
        (speciesJson['abilities'] as Map<String, dynamic>)['primary'],
        _initialAbilityId,
      );

      final learnsetJson = await _readProjectJson(
        projectRoot,
        p.join(
          bundle.manifest.pokemon.learnsetsDir,
          '$_initialSpeciesId.json',
        ),
      );
      expect(
        (learnsetJson['startingMoves'] as List<dynamic>).cast<String>(),
        containsAll(_initialMoves),
      );

      final moveIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: bundle.manifest.pokemon.catalogFiles['moves']!,
        expectedCatalog: 'moves',
      );
      expect(moveIds, containsAll(_initialMoves));

      final itemIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: bundle.manifest.pokemon.catalogFiles['items']!,
        expectedCatalog: 'items',
      );
      expect(itemIds, containsAll(<String>[_captureItemId, _medicineItemId]));

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

      expect(state.saveId, _saveId);
      expect(state.currentMapId, _startMapId);
      expect(state.playerPosition, const GridPos(x: 17, y: 24));
      expect(state.playerFacing, EntityFacing.south);
      expect(state.trainerProfile.money, 0);
      expect(state.party.members, hasLength(1));
      expect(state.party.members.single.speciesId, _initialSpeciesId);
      expect(state.party.members.single.level, 8);
      expect(state.party.members.single.currentHp, 24);
      expect(state.party.members.single.abilityId, _initialAbilityId);
      expect(state.party.members.single.knownMoveIds, _initialMoves);
      expect(state.bag.entries, hasLength(2));
      expect(
        state.bag.entries,
        contains(
          const BagEntry(
            itemId: _captureItemId,
            categoryId: 'items',
            quantity: 5,
          ),
        ),
      );
      expect(
        state.bag.entries,
        contains(
          const BagEntry(
            itemId: _medicineItemId,
            categoryId: 'medicine',
            quantity: 2,
          ),
        ),
      );

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, _saveId);
      expect(reloaded.currentMapId, _startMapId);
      expect(reloaded.playerPosition, const GridPos(x: 17, y: 24));
      expect(reloaded.playerFacing, EntityFacing.south);
      expect(reloaded.trainerProfile.money, 0);
      expect(reloaded.party.members, hasLength(1));
      expect(reloaded.party.members.single.speciesId, _initialSpeciesId);
      expect(reloaded.party.members.single.level, 8);
      expect(reloaded.party.members.single.currentHp, 24);
      expect(reloaded.party.members.single.knownMoveIds, _initialMoves);
      expect(
        reloaded.bag.entries,
        equals(<BagEntry>[
          const BagEntry(
            itemId: _captureItemId,
            categoryId: 'items',
            quantity: 5,
          ),
          const BagEntry(
            itemId: _medicineItemId,
            categoryId: 'medicine',
            quantity: 2,
          ),
        ]),
      );
      expect(
          reloaded.progression.caughtSpeciesIds, contains(_initialSpeciesId));
      expect(reloaded.progression.seenSpeciesIds, contains(_initialSpeciesId));
    },
  );
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

Future<Map<String, dynamic>> _readSpeciesJsonById({
  required Directory projectRoot,
  required String speciesDir,
  required String speciesId,
}) async {
  final directory = Directory(p.join(projectRoot.path, speciesDir));
  await for (final entity in directory.list(recursive: false)) {
    if (entity is! File || p.extension(entity.path) != '.json') {
      continue;
    }
    final json = await _readJsonFile(entity);
    if (json['id'] == speciesId) {
      return json;
    }
  }
  throw StateError('Species id not found in Selbrume data: $speciesId');
}

Future<Set<String>> _readCatalogIds({
  required Directory projectRoot,
  required String relativePath,
  required String expectedCatalog,
}) async {
  final json = await _readProjectJson(projectRoot, relativePath);
  expect(json['catalog'], expectedCatalog);
  return (json['entries'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((entry) => entry['id'] as String)
      .toSet();
}

Future<Map<String, dynamic>> _readProjectJson(
  Directory projectRoot,
  String relativePath,
) {
  return _readJsonFile(File(p.join(projectRoot.path, relativePath)));
}

Future<Map<String, dynamic>> _readJsonFile(File file) async {
  final decoded = jsonDecode(await file.readAsString());
  return (decoded as Map<String, dynamic>);
}

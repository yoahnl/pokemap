import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _routeMapId = 'route 1';
const _saveId = 'p6_04_selbrume_route_1_encounter_capture';
const _encounterTableId = 'grass_path_route_1';
const _capturedSpeciesId = 'pidgeotto';
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
    'P6-04 triggers repo-local Route 1 encounter and persists a minimal capture',
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
      expect(selbrumeBundle.map.id, _startMapId);
      expect(routeBundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(routeBundle.map.id, _routeMapId);
      expect(
        selbrumeBundle.manifest.maps.map((entry) => entry.id),
        containsAll(<String>[_startMapId, _routeMapId]),
      );

      final connectsBackToSelbrume = routeBundle.map.connections.any(
        (connection) => connection.targetMapId == _startMapId,
      );
      expect(connectsBackToSelbrume, isTrue);

      final table = routeBundle.manifest.encounterTables.singleWhere(
        (candidate) => candidate.id == _encounterTableId,
      );
      expect(table.name, 'grass path route 1');
      expect(table.encounterKind, EncounterKind.walk);
      expect(table.entries, hasLength(1));
      final entry = table.entries.single;
      expect(entry.speciesId, _capturedSpeciesId);
      expect(entry.minLevel, 1);
      expect(entry.maxLevel, 5);
      expect(entry.weight, 1);

      final encounterZones = routeBundle.map.gameplayZones
          .where(
            (zone) =>
                zone.kind == GameplayZoneKind.encounter &&
                zone.encounter?.encounterTableId == _encounterTableId &&
                zone.encounter?.encounterKind == EncounterKind.walk,
          )
          .toList(growable: false);
      expect(encounterZones, hasLength(5));

      final firstEncounterZone = encounterZones.first;
      final encounterPos = firstEncounterZone.area.pos;
      expect(encounterPos, const GridPos(x: 1, y: 27));

      final speciesJson = await _readSpeciesJsonById(
        projectRoot: projectRoot,
        speciesDir: routeBundle.manifest.pokemon.speciesDir,
        speciesId: _capturedSpeciesId,
      );
      expect(speciesJson['id'], _capturedSpeciesId);
      expect(
        (speciesJson['abilities'] as Map<String, dynamic>)['primary'],
        _initialAbilityId,
      );

      final learnsetJson = await _readProjectJson(
        projectRoot,
        p.join(
          routeBundle.manifest.pokemon.learnsetsDir,
          '$_capturedSpeciesId.json',
        ),
      );
      expect(
        (learnsetJson['startingMoves'] as List<dynamic>).cast<String>(),
        containsAll(_initialMoves),
      );

      final moveIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: routeBundle.manifest.pokemon.catalogFiles['moves']!,
        expectedCatalog: 'moves',
      );
      expect(moveIds, containsAll(_initialMoves));

      final itemIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: routeBundle.manifest.pokemon.catalogFiles['items']!,
        expectedCatalog: 'items',
      );
      expect(itemIds, containsAll(<String>[_captureItemId, _medicineItemId]));

      const mutations = GameStateMutations();
      var state = createNewGameStateFromMap(
        startMap: selbrumeBundle.map,
        saveId: _saveId,
        playerName: 'P6 Tester',
        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
      );
      state = _seedP6InitialState(state);
      state = mutations.setFlag(state, _p603FlagId);
      state = mutations.completeStep(state, _p603StepId);

      expect(state.currentMapId, _startMapId);
      expect(state.playerPosition, const GridPos(x: 17, y: 24));
      expect(state.playerFacing, EntityFacing.south);
      expect(state.party.members, hasLength(1));
      expect(state.party.members.single.speciesId, _initialSpeciesId);
      expect(_bagQuantity(state, _captureItemId), 5);
      expect(_bagQuantity(state, _medicineItemId), 2);

      state = mutations.warpPlayer(
        state,
        _routeMapId,
        encounterPos.x,
        encounterPos.y,
        facing: EntityFacing.east,
      );

      expect(state.currentMapId, _routeMapId);
      expect(state.playerPosition, encounterPos);
      expect(state.playerFacing, EntityFacing.east);

      final world = GameplayWorldState.initial(
        map: routeBundle.map,
        playerPos: state.playerPosition,
        playerFacing: Direction.east,
        project: routeBundle.manifest,
        tileWidth: routeBundle.manifest.settings.tileWidth,
        tileHeight: routeBundle.manifest.settings.tileHeight,
      );
      final encounterCheck = checkEncounterAtPlayerPosition(
        world: world,
        project: routeBundle.manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 2],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );

      expect(encounterCheck.triggered, isTrue);
      final encounter = encounterCheck.encounter!;
      expect(encounter.mapId, _routeMapId);
      expect(encounter.zoneId, firstEncounterZone.id);
      expect(encounter.tableId, _encounterTableId);
      expect(encounter.encounterKind, EncounterKind.walk);
      expect(encounter.speciesId, _capturedSpeciesId);
      expect(encounter.minLevel, entry.minLevel);
      expect(encounter.maxLevel, entry.maxLevel);
      expect(encounter.level, 3);
      expect(encounter.playerPos, encounterPos);

      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: world,
        createdAtEpochMs: 1,
      );
      expect(request.kind, RuntimeBattleKind.wild);
      expect(request.source, RuntimeBattleSourceKind.encounterZone);
      expect(request.mapId, _routeMapId);
      expect(request.zoneId, firstEncounterZone.id);
      expect(request.tableId, _encounterTableId);
      expect(request.speciesId, _capturedSpeciesId);
      expect(request.level, 3);
      expect(request.returnContext.mapId, _routeMapId);
      expect(request.returnContext.playerPos, encounterPos);

      state = markSpeciesSeenInGameState(state, encounter.speciesId);
      expect(state.progression.seenSpeciesIds, contains(_capturedSpeciesId));

      state = mutations.consumeItem(state, _captureItemId, 1);
      expect(_bagQuantity(state, _captureItemId), 4);
      expect(_bagQuantity(state, _medicineItemId), 2);

      final capturedPokemon = PlayerPokemon(
        speciesId: encounter.speciesId,
        natureId: 'hardy',
        abilityId: _initialAbilityId,
        level: encounter.level,
        currentHp: 18,
        knownMoveIds: _initialMoves,
      );
      final captureResult = mutations.applyCapturedPokemon(
        state,
        pokemon: capturedPokemon,
      );
      expect(captureResult.destination, CaptureDestinationKind.party);
      expect(captureResult.partyIndex, 1);
      expect(captureResult.storageIndex, isNull);
      state = captureResult.state;

      expect(state.currentMapId, _routeMapId);
      expect(state.playerPosition, encounterPos);
      expect(state.party.members, hasLength(2));
      expect(state.party.members.first.speciesId, _initialSpeciesId);
      expect(state.party.members.last.speciesId, _capturedSpeciesId);
      expect(state.party.members.last.level, encounter.level);
      expect(state.party.members.last.knownMoveIds, _initialMoves);
      expect(state.pokemonStorage.storedPokemon, isEmpty);
      expect(_bagQuantity(state, _captureItemId), 4);
      expect(_bagQuantity(state, _medicineItemId), 2);
      expect(state.progression.caughtSpeciesIds, contains(_capturedSpeciesId));
      expect(state.progression.seenSpeciesIds, contains(_capturedSpeciesId));
      expect(state.storyFlags.activeFlags, contains(_p603FlagId));
      expect(state.progression.completedStepIds, contains(_p603StepId));

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, _saveId);
      expect(reloaded.currentMapId, _routeMapId);
      expect(reloaded.playerPosition, encounterPos);
      expect(reloaded.playerFacing, EntityFacing.east);
      expect(reloaded.party.members, hasLength(2));
      expect(reloaded.party.members.first.speciesId, _initialSpeciesId);
      expect(reloaded.party.members.last.speciesId, _capturedSpeciesId);
      expect(reloaded.party.members.last.level, 3);
      expect(reloaded.party.members.last.knownMoveIds, _initialMoves);
      expect(reloaded.pokemonStorage.storedPokemon, isEmpty);
      expect(_bagQuantity(reloaded, _captureItemId), 4);
      expect(_bagQuantity(reloaded, _medicineItemId), 2);
      expect(
        reloaded.progression.caughtSpeciesIds,
        contains(_capturedSpeciesId),
      );
      expect(
        reloaded.progression.seenSpeciesIds,
        contains(_capturedSpeciesId),
      );
      expect(reloaded.storyFlags.activeFlags, contains(_p603FlagId));
      expect(reloaded.progression.completedStepIds, contains(_p603StepId));
    },
  );
}

GameState _seedP6InitialState(GameState state) {
  const mutations = GameStateMutations();
  var next = mutations.givePokemon(
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
  next = mutations.giveItem(next, _captureItemId, 5);
  next = mutations.giveItem(next, _medicineItemId, 2);
  return next;
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
  return decoded as Map<String, dynamic>;
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  var _doubleIndex = 0;
  var _intIndex = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() {
    final value = nextDoubleValues[_doubleIndex % nextDoubleValues.length];
    _doubleIndex++;
    return value;
  }

  @override
  int nextInt(int max) {
    final value = nextIntValues[_intIndex % nextIntValues.length];
    _intIndex++;
    return max == 0 ? 0 : value % max;
  }
}

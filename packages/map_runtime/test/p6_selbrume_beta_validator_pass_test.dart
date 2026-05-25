import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _routeMapId = 'route 1';
const _spawnId = 'spawn';
const _initialSpeciesId = 'pidgeotto';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';
const _encounterTableId = 'grass_path_route_1';
const _trainerId = 'grant';
const _grantNpcId = 'grant';
const _grantSpeciesIds = <String>['bulbasaur', 'metapod', 'ivysaur'];
const _grantMoveIds = <String>[
  'growl',
  'tackle',
  'harden',
  'sweet_scent',
  'growth',
  'leech_seed',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-07 validates repo-local Selbrume golden slice with no beta blocker',
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
      expect(
        selbrumeBundle.manifest.maps.map((entry) => entry.id),
        containsAll(<String>[_startMapId, _routeMapId]),
      );

      final mapsById = await _readAllManifestMaps(
        projectRoot: projectRoot,
        manifest: selbrumeBundle.manifest,
      );
      expect(
        mapsById.keys,
        containsAll(selbrumeBundle.manifest.maps.map((entry) => entry.id)),
      );

      final startMap = mapsById[_startMapId]!;
      final spawn = startMap.entities.singleWhere(
        (entity) => entity.id == _spawnId,
      );
      expect(spawn.kind, MapEntityKind.spawn);
      expect(spawn.pos, const GridPos(x: 17, y: 24));
      expect(spawn.spawn?.role, EntitySpawnRole.playerStart);
      expect(spawn.spawn?.facing, EntityFacing.south);

      final routeMap = mapsById[_routeMapId]!;
      final grantNpc = routeMap.entities.singleWhere(
        (entity) => entity.id == _grantNpcId,
      );
      expect(grantNpc.kind, MapEntityKind.npc);
      expect(grantNpc.npc?.trainerId, _trainerId);

      final encounterTable = selbrumeBundle.manifest.encounterTables
          .singleWhere((table) => table.id == _encounterTableId);
      expect(encounterTable.encounterKind, EncounterKind.walk);
      expect(encounterTable.entries.single.speciesId, _initialSpeciesId);
      expect(encounterTable.entries.single.minLevel, 1);
      expect(encounterTable.entries.single.maxLevel, 5);
      expect(
        routeMap.gameplayZones.where(
          (zone) =>
              zone.kind == GameplayZoneKind.encounter &&
              zone.encounter?.encounterTableId == _encounterTableId &&
              zone.encounter?.encounterKind == EncounterKind.walk,
        ),
        hasLength(5),
      );

      final speciesIds = await _readAllSpeciesIds(
        projectRoot: projectRoot,
        speciesDir: selbrumeBundle.manifest.pokemon.speciesDir,
      );
      expect(
        speciesIds,
        containsAll(<String>[_initialSpeciesId, ..._grantSpeciesIds]),
      );

      final moveIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: selbrumeBundle.manifest.pokemon.catalogFiles['moves']!,
        expectedCatalog: 'moves',
      );
      expect(
        moveIds,
        containsAll(<String>{..._initialMoves, ..._grantMoveIds}),
      );

      final itemIds = await _readCatalogIds(
        projectRoot: projectRoot,
        relativePath: selbrumeBundle.manifest.pokemon.catalogFiles['items']!,
        expectedCatalog: 'items',
      );
      expect(itemIds, containsAll(<String>[_captureItemId, _medicineItemId]));

      final grantTrainer = selbrumeBundle.manifest.trainers.singleWhere(
        (trainer) => trainer.id == _trainerId,
      );
      expect(grantTrainer.team.map((member) => member.speciesId),
          _grantSpeciesIds);
      expect(
        grantTrainer.team.expand((member) => member.moves),
        containsAll(_grantMoveIds),
      );

      final result = validateBetaPlayability(
        selbrumeBundle.manifest,
        context: BetaPlayabilityValidationContext(
          mapsById: mapsById,
          startMapId: _startMapId,
          knownSpeciesIds: speciesIds,
          knownMoveIds: moveIds,
          initialPartySpeciesIds: const <String>{_initialSpeciesId},
          initialPartyMoveIds: _initialMoves.toSet(),
          requiresInitialParty: true,
          requiresTrainerBattle: true,
          requiresCapture: true,
          hasCaptureItemSource: itemIds.contains(_captureItemId),
          requiresSaveLoad: true,
          hasSaveLoadSupport: true,
        ),
      );

      expect(result.hasErrors, isFalse);
      expect(result.isPlayable, isTrue);
      expect(result.diagnostics, isEmpty);
      expect(
        _diagnosticsBySeverity(result),
        equals(<BetaPlayabilityDiagnosticSeverity,
            List<BetaPlayabilityDiagnosticKind>>{
          BetaPlayabilityDiagnosticSeverity.error:
              <BetaPlayabilityDiagnosticKind>[],
          BetaPlayabilityDiagnosticSeverity.warning:
              <BetaPlayabilityDiagnosticKind>[],
          BetaPlayabilityDiagnosticSeverity.info:
              <BetaPlayabilityDiagnosticKind>[],
        }),
      );

      final diagnosticKinds =
          result.diagnostics.map((diagnostic) => diagnostic.kind).toSet();
      expect(
        diagnosticKinds,
        isNot(
          containsAll(<BetaPlayabilityDiagnosticKind>{
            BetaPlayabilityDiagnosticKind.missingMap,
            BetaPlayabilityDiagnosticKind.missingStartMap,
            BetaPlayabilityDiagnosticKind.missingPlayerSpawn,
            BetaPlayabilityDiagnosticKind.invalidDefaultSpawn,
            BetaPlayabilityDiagnosticKind.missingTrainerReference,
            BetaPlayabilityDiagnosticKind.trainerHasEmptyTeam,
            BetaPlayabilityDiagnosticKind.trainerPokemonMissingSpecies,
            BetaPlayabilityDiagnosticKind.trainerPokemonMissingMoves,
            BetaPlayabilityDiagnosticKind.missingPokemonSpecies,
            BetaPlayabilityDiagnosticKind.missingPokemonMove,
            BetaPlayabilityDiagnosticKind.missingStarterOrInitialPartySource,
            BetaPlayabilityDiagnosticKind.missingCapturePrerequisite,
            BetaPlayabilityDiagnosticKind.missingSaveLoadPrerequisite,
          }),
        ),
      );
    },
  );
}

Future<Map<String, MapData>> _readAllManifestMaps({
  required Directory projectRoot,
  required ProjectManifest manifest,
}) async {
  final mapsById = <String, MapData>{};
  for (final entry in manifest.maps) {
    final json = await _readProjectJson(projectRoot, entry.relativePath);
    final map = MapData.fromJson(json);
    mapsById[map.id] = map;
  }
  return mapsById;
}

Future<Set<String>> _readAllSpeciesIds({
  required Directory projectRoot,
  required String speciesDir,
}) async {
  final directory = Directory(p.join(projectRoot.path, speciesDir));
  final ids = <String>{};
  await for (final entity in directory.list(recursive: false)) {
    if (entity is! File || p.extension(entity.path) != '.json') {
      continue;
    }
    final json = await _readJsonFile(entity);
    final id = json['id'];
    if (id is String && id.trim().isNotEmpty) {
      ids.add(id);
    }
  }
  return ids;
}

Future<Set<String>> _readCatalogIds({
  required Directory projectRoot,
  required String relativePath,
  required String expectedCatalog,
}) async {
  final json = await _readProjectJson(projectRoot, relativePath);
  expect(json['catalog'], expectedCatalog);
  return (json['entries'] as List<dynamic>)
      .map((entry) => entry as Map<String, dynamic>)
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

Map<BetaPlayabilityDiagnosticSeverity, List<BetaPlayabilityDiagnosticKind>>
    _diagnosticsBySeverity(BetaPlayabilityValidationResult result) {
  return <BetaPlayabilityDiagnosticSeverity,
      List<BetaPlayabilityDiagnosticKind>>{
    for (final severity in BetaPlayabilityDiagnosticSeverity.values)
      severity: result.diagnostics
          .where((diagnostic) => diagnostic.severity == severity)
          .map((diagnostic) => diagnostic.kind)
          .toList(growable: false),
  };
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

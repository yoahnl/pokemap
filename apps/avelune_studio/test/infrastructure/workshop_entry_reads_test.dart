import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/regional_map/data/local_regional_map_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final unrelated in [0, 900]) {
    test(
      'workshop entry reads no map files with $unrelated unrelated definitions',
      () async {
        final root = await Directory.systemTemp.createTemp('workshop-entry-');
        addTearDown(() => root.delete(recursive: true));
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        final project = ProjectManifest(
          name: 'Scoped workshops',
          maps: const [
            ProjectMapEntry(
              id: 'town',
              name: 'Town',
              relativePath: 'maps/town.json',
            ),
          ],
          tilesets: const [],
          pokemon: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            catalogFiles: {'items': 'data/items.json'},
          ),
          dialogueFolders: [
            for (var index = 0; index < unrelated; index++)
              ProjectDialogueFolder(id: 'folder-$index', name: 'Folder $index'),
          ],
        );
        await WorkingProjectCatalog.create(
          store: store,
          projectId: 'entry',
          project: project,
        );
        final itemFile = File('${root.path}/data/items.json');
        await itemFile.parent.create(recursive: true);
        await itemFile.writeAsString(
          jsonEncode(
            encodeProjectItemCatalog(
              const ProjectItemCatalog(schemaVersion: 1, entries: []),
            ),
          ),
        );
        final session = ProjectSession(
          sessionId: root.path,
          name: project.name,
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        );
        final reader = _CountingReader();
        final maps = LocalMapWorkspaceAdapter(reader: reader);
        for (var attempt = 0; attempt < 2; attempt++) {
          reader.paths.clear();
          final combat = await LocalPokemonCombatAdapter(
            session: session,
            mapAdapter: maps,
            reader: reader,
          ).load();
          final commerce = await LocalPokemonCommerceAdapter(
            session: session,
            mapAdapter: maps,
            reader: reader,
          ).load();
          final regional = await LocalRegionalMapAdapter(
            session: session,
            mapAdapter: maps,
            reader: reader,
          ).load();
          expect(combat.maps, isEmpty);
          expect(combat.referencesComplete, isFalse);
          expect(commerce.referencesComplete, isFalse);
          expect(commerce.catalog, isNotNull);
          expect(regional.maps, isEmpty);
          expect(regional.project.maps.single.id, 'town');
          expect(
            reader.paths.where((path) => path.startsWith('maps/')),
            isEmpty,
          );
          expect(reader.definitionFields, isNot(contains('dialogueFolders')));
        }
        final regionalPort = LocalRegionalMapAdapter(
          session: session,
          mapAdapter: maps,
          reader: reader,
        );
        final source = await regionalPort.load();
        final mapFile = File('${root.path}/maps/town.json');
        await mapFile.parent.create(recursive: true);
        await mapFile.writeAsString(
          jsonEncode(
            const MapData(
              id: 'town',
              name: 'Town',
              size: GridSize(width: 4, height: 4),
            ).toJson(),
          ),
        );
        reader.paths.clear();
        expect(
          (await regionalPort.readMap(source: source, mapId: 'town')).id,
          'town',
        );
        expect(reader.paths.where((path) => path.startsWith('maps/')), [
          'maps/town.json',
        ]);
      },
    );
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final definitionFields = <String>[];
  final _local = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      _local.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => _local.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    paths.add(relativePath);
    return _local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    paths.add(relativePath);
    final bytes = await _local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (relativePath.startsWith('catalog/objects/')) {
      final object = jsonDecode(utf8.decode(bytes)) as Map;
      if (object['type'] == 'unit') {
        final payload = object['payload'] as Map;
        if (payload['section'] == r'$projectDefinition') {
          definitionFields.add((payload['value'] as Map)['field'] as String);
        }
      }
    }
    yield bytes;
  }
}

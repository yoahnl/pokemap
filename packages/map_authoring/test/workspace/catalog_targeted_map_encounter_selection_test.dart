import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/catalog_storage/working_project_catalog.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_authoring/src/transactions/local_transaction_file_gateway.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_targeted_map_edit.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final unrelated in [0, 120]) {
    test(
        'typed SmartTile encounters select only referenced tables with $unrelated unrelated tables',
        () async {
      final root =
          await Directory.systemTemp.createTemp('targeted-encounters-');
      addTearDown(() => root.delete(recursive: true));
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final project = ProjectManifest(
        name: 'Targeted encounters',
        version: ProjectVersion.v8,
        maps: [
          const ProjectMapEntry(
              id: 'route', name: 'Route', relativePath: 'maps/route.json'),
          for (var i = 0; i < unrelated; i++)
            ProjectMapEntry(
                id: 'unused-$i',
                name: 'Unused',
                relativePath: 'maps/unused-$i.json'),
        ],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
        ],
        encounterTables: [
          for (final id in [
            'walk',
            'alternate',
            for (var i = 0; i < unrelated; i++) 'unused-$i'
          ])
            ProjectEncounterTable(
                id: id,
                name: id,
                encounterKind: EncounterKind.walk,
                entries: const [
                  ProjectEncounterEntry(
                      speciesId: 'pidgey', minLevel: 2, maxLevel: 3)
                ]),
        ],
        smartTileCatalog:
            ProjectSmartTileCatalog.fromJson(jsonDecode(jsonEncode({
          'formatVersion': 8,
          'atlases': [
            {
              'id': 'atlas',
              'name': 'Atlas',
              'tilesetId': 'tiles',
              'columns': 1,
              'rows': 1
            }
          ],
          'materials': [
            {'id': 'grass', 'name': 'Grass', 'connectionGroupId': 'grass'}
          ],
          'presets': [
            {
              'id': 'grass',
              'name': 'Grass',
              'usage': 'path',
              'topology': 'uniform',
              'status': 'published',
              'coveragePolicy': 'sparse',
              'coverageProfile': {'mode': 'template'},
              'transformPolicy': {},
              'defaultMaterialId': 'grass',
              'allowedMaterialIds': ['grass'],
              'rules': [
                {
                  'id': 'all',
                  'centerMatch': {'kind': 'material', 'materialId': 'grass'},
                  'candidates': [
                    {
                      'id': 'frame',
                      'parts': [
                        {
                          'source': {
                            'kind': 'frame',
                            'frame': {'atlasId': 'atlas', 'column': 0, 'row': 0}
                          }
                        }
                      ]
                    }
                  ]
                }
              ],
            }
          ],
        })) as Map<String, dynamic>),
      );
      final working = await WorkingProjectCatalog.create(
          store: store, projectId: 'encounters', project: project);
      await store.prepareLocalEditing();
      final map = MapData(
        id: 'route',
        name: 'Route',
        version: ProjectVersion.v8,
        size: const GridSize(width: 1, height: 1),
        tilesetId: 'tiles',
        properties: {'encounterTableId': 'not-a-typed-binding'},
        layers: const [
          MapLayer.smartTile(
              id: 'grass',
              name: 'Grass',
              presetId: 'grass',
              usage: SmartTileUsage.path,
              materialPalette: ['', 'grass'],
              field: SmartTileField.cell(semanticCells: [1]),
              encounterBehavior: SmartTileEncounterBehavior(
                  materialId: 'grass',
                  encounter: EncounterZonePayload(
                      encounterTableId: 'walk',
                      encounterKind: EncounterKind.walk)))
        ],
      );
      final mapFile = File('${root.path}/maps/route.json');
      await mapFile.parent.create(recursive: true);
      final mapBytes = utf8.encode(jsonEncode(map.toJson()));
      await mapFile.writeAsBytes(mapBytes);
      final descriptor = await File('${root.path}/project.json').readAsBytes();
      final poisoned = <String>{};
      for (var i = 0; i < unrelated; i++) {
        final row = await working.catalog.snapshot.lookup(
            CatalogMetadataDocuments.documentKey(
                'encounterTables', 'unused-$i'));
        final unit = (await working.catalog.snapshot.indexEntry(
            CatalogMetadataDocuments.definitionKey(
                'encounterTables', row!.payload['position'] as int)))!;
        final path = 'catalog/objects/${unit.reference.sha256}.json';
        poisoned.add(path);
        await File('${root.path}/$path')
            .writeAsString('unrelated encounter must not be read');
        await File('${root.path}/maps/unused-$i.json')
            .writeAsString('unrelated map must not be read');
      }
      final counter = _CountingReader();
      final countedStore = CatalogStorageStore(
          projectRoot: root.path,
          reader: counter,
          gateway:
              await LocalTransactionFileGateway.open(projectRoot: root.path));
      for (final tableId in ['walk', 'alternate']) {
        final reader = (await CatalogProjectReader.open(
            store: countedStore,
            descriptor: working.descriptor.toJson(),
            metadataFields: {'maps', 'settings'}))!;
        final layer = map.layers.single as SmartTileLayer;
        final projected = map.copyWith(layers: [
          layer.copyWith(
              encounterBehavior: layer.encounterBehavior!.copyWith(
                  encounter: layer.encounterBehavior!.encounter
                      .copyWith(encounterTableId: tableId)))
        ]);
        counter.paths.clear();
        final selected = await CatalogTargetedMapSelection.read(
            reader: reader, mapId: 'route', projectedMap: projected);
        expect(selected.definitions.encounterTables.map((table) => table.id),
            [tableId]);
        expect(counter.paths.where(poisoned.contains), isEmpty);
        expect(
            counter.paths.where((path) =>
                path.startsWith('maps/') && path != 'maps/route.json'),
            isEmpty);
        expect(counter.paths.length, lessThan(90));
        final missing = projected.copyWith(layers: [
          layer.copyWith(
              encounterBehavior: layer.encounterBehavior!.copyWith(
                  encounter: layer.encounterBehavior!.encounter
                      .copyWith(encounterTableId: 'missing')))
        ]);
        await expectLater(
            CatalogTargetedMapSelection.read(
                reader: reader, mapId: 'route', projectedMap: missing),
            throwsA(isA<ValidationException>().having(
                (error) => error.code, 'code', 'encounter.table_unknown')));
      }
      if (unrelated == 0) {
        final completeReader = (await CatalogProjectReader.open(
            store: countedStore,
            descriptor: working.descriptor.toJson(),
            metadataFields: {'maps', 'settings', 'encounterTables'}))!;
        final layer = map.layers.single as SmartTileLayer;
        final mixed = map.copyWith(
          size: const GridSize(width: 2, height: 1),
          layers: [
            layer.copyWith(
                field: const SmartTileField.cell(semanticCells: [1, 0])),
          ],
          gameplayZones: const [
            MapGameplayZone(
                id: 'manual',
                kind: GameplayZoneKind.encounter,
                area: MapRect(
                    pos: GridPos(x: 1, y: 0),
                    size: GridSize(width: 1, height: 1)),
                encounter: EncounterZonePayload(
                    encounterTableId: 'alternate',
                    encounterKind: EncounterKind.walk)),
          ],
        );
        MapValidator.validate(mixed, projectDialogueContext: project);
        final selected = await CatalogTargetedMapSelection.read(
            reader: completeReader, mapId: 'route', projectedMap: mixed);
        expect(selected.definitions.encounterTables.map((table) => table.id),
            ['walk', 'alternate']);
      }
      expect(await mapFile.readAsBytes(), mapBytes);
      expect(await File('${root.path}/project.json').readAsBytes(), descriptor);
    });
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
  final List<String> paths = [];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}

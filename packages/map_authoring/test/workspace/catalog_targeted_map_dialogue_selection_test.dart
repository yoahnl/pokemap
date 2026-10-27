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
        'NPC dialogues and Facts remain targeted with $unrelated unrelated documents',
        () async {
      final root = await Directory.systemTemp.createTemp('targeted-npc-');
      addTearDown(() => root.delete(recursive: true));
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final project = ProjectManifest(
        name: 'Route 30',
        version: ProjectVersion.v8,
        maps: const [
          ProjectMapEntry(
              id: 'route-30',
              name: 'Route 30',
              relativePath: 'maps/route-30.json')
        ],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
        ],
        dialogues: [
          for (final id in [
            'hgss-r30-farouk-defi',
            'hgss-r30-farouk-apres',
            for (var i = 0; i < unrelated; i++) 'unused-$i'
          ])
            ProjectDialogueEntry(
                id: id, name: id, relativePath: 'dialogues/$id.yarn')
        ],
        facts: [
          NarrativeFactDefinition(id: 'farouk-ready', label: 'Ready'),
          for (var i = 0; i < unrelated; i++)
            NarrativeFactDefinition(id: 'unused-$i', label: 'Unused')
        ],
        characters: [
          for (var i = 0; i < unrelated; i++)
            ProjectCharacterEntry(
                id: 'unused-$i', name: 'Unused', tilesetId: 'tiles')
        ],
      );
      final working = await WorkingProjectCatalog.create(
          store: store, projectId: 'route30', project: project);
      await store.prepareLocalEditing();
      final map = MapData(
          id: 'route-30',
          name: 'Route 30',
          version: ProjectVersion.v8,
          size: const GridSize(width: 4, height: 4),
          tilesetId: 'tiles',
          properties: {
            'factId': 'farouk-ready'
          },
          entities: [
            MapEntity.fromJson({
              'id': 'r30-dresseur-farouk',
              'kind': 'npc',
              'pos': {'x': 1, 'y': 1},
              'npc': {
                'displayName': 'Farouk',
                'dialogue': {'dialogueId': 'hgss-r30-farouk-defi'},
                'defeatDialogueRef': {'dialogueId': 'hgss-r30-farouk-apres'}
              }
            })
          ]);
      MapValidator.validate(map, projectDialogueContext: project);
      final mapFile = File('${root.path}/maps/route-30.json');
      await mapFile.parent.create(recursive: true);
      final before = utf8.encode(jsonEncode(map.toJson()));
      await mapFile.writeAsBytes(before);
      final poisoned = <String>{};
      for (var i = 0; i < unrelated; i++) {
        for (final field in ['dialogues', 'facts']) {
          final row = (await working.catalog.snapshot.lookup(
              CatalogMetadataDocuments.documentKey(field, 'unused-$i')))!;
          final unit = (await working.catalog.snapshot.indexEntry(
              CatalogMetadataDocuments.definitionKey(
                  field, row.payload['position'] as int)))!;
          poisoned.add('catalog/objects/${unit.reference.sha256}.json');
        }
        final unit = (await working.catalog.snapshot.indexEntry(
            CatalogDefinitionKey(
                CatalogDefinitionKind.character, 'unused-$i')))!;
        poisoned.add('catalog/objects/${unit.reference.sha256}.json');
      }
      for (final path in poisoned) {
        await File('${root.path}/$path')
            .writeAsString('unrelated document must remain unread');
      }
      final counter = _CountingReader();
      final countedStore = CatalogStorageStore(
          projectRoot: root.path,
          reader: counter,
          gateway:
              await LocalTransactionFileGateway.open(projectRoot: root.path));
      final reader = (await CatalogProjectReader.open(
          store: countedStore,
          descriptor: working.descriptor.toJson(),
          metadataFields: {'maps', 'settings', 'scenes', 'trainers'}))!;
      expect(reader.catalog.projectMetadata.dialogues, isEmpty);
      expect(reader.catalog.projectMetadata.facts, isEmpty);
      counter.paths.clear();
      final selected = await CatalogTargetedMapSelection.read(
          reader: reader, mapId: 'route-30');
      expect(selected.definitions.dialogues.map((entry) => entry.id),
          ['hgss-r30-farouk-defi', 'hgss-r30-farouk-apres']);
      expect(selected.definitions.facts.map((entry) => entry.id),
          ['farouk-ready']);
      expect(selected.definitions.characters, isEmpty);
      expect(counter.paths.where(poisoned.contains), isEmpty);
      expect(counter.paths.length, lessThan(110));
      expect(
          counter.paths.where((path) =>
              path.startsWith('maps/') && path != 'maps/route-30.json'),
          isEmpty);
      print(jsonEncode({
        'unrelatedDocumentsPerKind': unrelated,
        'resourceReads': counter.paths.length,
        'unrelatedReads': counter.paths.where(poisoned.contains).length
      }));
      if (unrelated == 0) {
        final completeReader = (await CatalogProjectReader.open(
            store: countedStore, descriptor: working.descriptor.toJson()))!;
        final complete = await CatalogTargetedMapSelection.read(
            reader: completeReader, mapId: 'route-30');
        expect(complete.definitions.dialogues.map((entry) => entry.id).toSet(),
            selected.definitions.dialogues.map((entry) => entry.id).toSet());
        expect(complete.definitions.facts.map((entry) => entry.id).toSet(),
            selected.definitions.facts.map((entry) => entry.id).toSet());
      }
      final missing = map.copyWith(entities: [
        MapEntity.fromJson({
          'id': 'missing',
          'kind': 'sign',
          'pos': {'x': 1, 'y': 1},
          'sign': {
            'dialogue': {'dialogueId': 'missing'}
          }
        })
      ]);
      await expectLater(
          CatalogTargetedMapSelection.read(
              reader: reader, mapId: 'route-30', projectedMap: missing),
          throwsA(isA<ValidationException>()));
      expect(await mapFile.readAsBytes(), before);
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

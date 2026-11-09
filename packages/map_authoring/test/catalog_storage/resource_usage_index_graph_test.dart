import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_resource_usage_index.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_library_actions_test.dart'
    show librarySceneMap, librarySceneProject, librarySnapshot;
import '../domains/maps/map_catalog_fixture.dart' show catalogMap;

void main() {
  for (final payload in <SceneNodePayload>[
    SceneYarnDialoguePayload(dialogueId: 'talk'),
    SceneCinematicPayload(cinematicId: 'cutscene'),
  ]) {
    test(
        'indexed transitive usages match the canonical walker for ${payload.runtimeType}',
        () async {
      final maps = [catalogMap('a'), librarySceneMap('b')];
      final project = librarySceneProject(maps, payload);
      final snapshot =
          librarySnapshot(maps, project: project, referenceDocuments: {
        'dialogueSource:talk':
            utf8.encode('title: Start\n---\n<<speaker person>>\nBonjour\n===')
      });
      final indexed = await _index(snapshot);
      for (final kind in ['character', 'tileset']) {
        final id = kind == 'character' ? 'person' : 'sheet';
        expect(
            await CatalogResourceUsageIndex.mapUsages(
                indexed.snapshot, kind, id, ['a', 'b']),
            resourceLibraryMapUsages(snapshot, kind, id));
      }
      final oldScene = (await indexed.snapshot
          .lookup(CatalogMetadataDocuments.definitionKey('scenes', 0)))!;
      final emptyScene = SceneAsset(
          id: 'scene',
          name: 'Empty',
          graph: SceneGraph(
              startNodeId: 'start',
              nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
              edges: const []));
      final changed = CatalogDefinitionUnit(
          key: oldScene.key,
          payload: {
            ...oldScene.payload,
            'value': <String, Object?>{
              ...oldScene.payload['value'] as Map,
              'definition': jsonDecode(jsonEncode(emptyScene.toJson()))
            },
          },
          references: oldScene.references);
      final maintained = await CatalogResourceUsageIndex.maintain(
          snapshot: indexed.snapshot,
          upserts: [changed],
          removals: const [],
          additionalChanges: const []);
      final patch =
          await indexed.snapshot.patch(upserts: [changed, ...maintained]);
      indexed.objects.addAll(patch.objects);
      final after = await patch.nextSnapshot(
          readObject: (ref) async => indexed.objects[ref.sha256]!);
      expect(
          await CatalogResourceUsageIndex.mapUsages(
              after, 'character', 'person', ['a', 'b']),
          isEmpty);
    });
  }

  test('project-wide default character retains all map ownership', () async {
    final maps = [catalogMap('a'), catalogMap('b')];
    final project =
        librarySceneProject(maps, SceneYarnDialoguePayload(dialogueId: 'talk'))
            .copyWith(
                settings:
                    const ProjectSettings(defaultPlayerCharacterId: 'person'));
    final snapshot = librarySnapshot(maps,
        project: project,
        referenceDocuments: {
          'dialogueSource:talk': utf8.encode('title: Start\n---\nBonjour\n===')
        });
    final indexed = await _index(snapshot);
    expect(
        await CatalogResourceUsageIndex.mapUsages(
            indexed.snapshot, 'character', 'person', ['a', 'b']),
        {'a', 'b'});
  });
}

Future<({CatalogSnapshot snapshot, Map<String, List<int>> objects})> _index(
    ProjectSnapshot project) async {
  final build = PortableCatalogPublication.encodeProject(project.manifest);
  final objects = {...build.storage.objects};
  final before = await CatalogSnapshot.open(
      root: build.storage.root,
      readObject: (ref) async => objects[ref.sha256]!);
  final units = await CatalogResourceUsageIndex.initialize(
      catalog: before, project: project);
  final patch = await before.patch(upserts: units);
  objects.addAll(patch.objects);
  return (
    snapshot: await patch.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!),
    objects: objects
  );
}

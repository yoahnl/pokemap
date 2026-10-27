import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final count in [0, 80]) {
    test(
      'Studio creates spatial maps with $count foreign maps without snapshots',
      () async {
        final root = Directory(
          '/Users/karim/Library/Caches/AveluneQA/hgss-mauville-maps/api/studio-fixture',
        );
        await root.create(recursive: true);
        addTearDown(() => root.delete(recursive: true));
        final project = ProjectManifest(
          name: 'Studio scoped',
          version: ProjectVersion.v9,
          settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
          ),
          maps: [
            for (var i = 0; i < count; i++)
              ProjectMapEntry(
                id: 'foreign-$i',
                name: 'Foreign $i',
                relativePath: 'maps/foreign-$i.json',
              ),
          ],
          tilesets: [],
        );
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        await WorkingProjectCatalog.create(
          store: store,
          projectId: 'studio-scope',
          project: project,
        );
        final session = ProjectSession(
          sessionId: 'scope',
          name: project.name,
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        );
        final reader = _CountingReader();
        final maps = LocalMapWorkspaceAdapter(reader: reader);
        await maps.loadCatalog(session);
        final history = File('${root.path}/.pokemap/authoring/history.jsonl');
        await history.parent.create(recursive: true);
        await history.writeAsString(
          'foreign history must remain unread\n' * (count == 0 ? 100 : 10000),
        );
        final profiles = <ProjectSnapshotLoadProfile>[];
        final adapter = LocalMapCatalogAdapter(
          maps,
          fileReader: reader,
          profileSink: profiles.add,
        );
        for (var i = 0; i < 2; i++) {
          reader.paths.clear();
          reader.probes.clear();
          final beforeObjects = await Directory('${root.path}/catalog/objects')
              .list()
              .length;
          final before = await maps.resourceBaseline(session);
          final receipt = await adapter.mutate(session, 'map.create', {
            'mapId': 'created-$i',
            'name': 'Created $i',
            'width': 8,
            'height': 6,
          }, expectedManifest: before.manifest);
          expect(receipt.createdMapId, 'created-$i');
          expect(receipt.changedPaths.toSet(), {
            'catalog/HEAD.json',
            'maps/created-$i.json',
          });
          await adapter.reconcile(session, receipt);
          expect(
            (await maps.resourceBaseline(session)).manifest.maps.length,
            count + i + 1,
          );
          expect(profiles, isEmpty);
          expect(
            reader.paths.where((path) => path.contains('foreign-')),
            isEmpty,
          );
          expect(reader.paths.length, lessThan(180));
          expect(reader.probes.length, lessThan(140));
          final afterObjects = await Directory('${root.path}/catalog/objects')
              .list()
              .length;
          expect(afterObjects - beforeObjects, lessThan(30));
          final map = MapData.fromJson(
            jsonDecode(
              await File('${root.path}/maps/created-$i.json').readAsString(),
            ),
          );
          expect(map.spatialScene, isNotNull);
        }
        final reopened = LocalMapWorkspaceAdapter();
        final saved = await reopened.loadCatalog(session);
        expect(saved.metadata.maps.length, count + 2);
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
  final probes = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) {
    probes.add(relativePath);
    return delegate.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

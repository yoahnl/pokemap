import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/spatial_terrain_relief_fixture.dart';

void main() {
  test('a relief paint on the working catalog writes only the edited map',
      () async {
    final root = Directory(
        '${Platform.environment['AVELUNE_QA_ROOT'] ?? '${Platform.environment['HOME']}/Library/Caches/AveluneQA'}/catalog-terrain-relief');
    if (await root.exists()) await root.delete(recursive: true);
    await root.create(recursive: true);
    addTearDown(() => root.delete(recursive: true));
    final map = reliefBaseMap();
    final entry = reliefProject.maps.single;
    final project = reliefProject.copyWith(maps: [
      entry,
      for (var i = 0; i < 20; i++)
        ProjectMapEntry(
            id: 'other-$i',
            name: 'Other $i',
            relativePath: 'maps/other-$i.json'),
    ]);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store, projectId: 'relief', project: project);
    final mapFile = File('${root.path}/${entry.relativePath}');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    for (var i = 0; i < 20; i++) {
      await File('${root.path}/maps/other-$i.json')
          .writeAsString('unrelated map must not be decoded');
    }
    final reader = _CountingReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() async {
      await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    });
    final before = await _tree(root);
    final mapBefore = await mapFile.readAsBytes();
    final parameters = <String, Object?>{
      'mapId': map.id,
      'level': 2,
      'blueprintId': 'fence',
      'region': {'x': 6, 'y': 4, 'width': 10, 'height': 8},
    };
    reader.paths.clear();
    final selected = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: 'map3d.terrain.paint_height', parameters: parameters);
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'relief',
            actionId: 'map3d.terrain.paint_height',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: selected.revision,
            idempotencyKey: 'relief',
            parameters: parameters));
    final applied = await api.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'relief');
    expect(
        reader.paths.where((path) => path.startsWith('maps/other-')), isEmpty);
    final after = await _tree(root);
    final changed = {
      for (final path in {...before.keys, ...after.keys})
        if (before[path] != after[path]) path,
    };
    expect(
        changed.where((path) =>
            !path.startsWith('.pokemap/') &&
            !path.startsWith('catalog/leases/') &&
            !path.startsWith('catalog/lease-locks/') &&
            path != 'catalog/HEAD.json' &&
            !(path.startsWith('catalog/objects/') &&
                !before.containsKey(path))),
        [entry.relativePath]);
    final painted = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
    expect(reliefFeatureIds(painted), ['relief-1']);
    expect(painted.spatialScene!.worldHeightAt(8.5, 6.5), 2);
    await api.undoMutation(opened.projectHandle,
        entryId: applied.receipt.receiptId, idempotencyKey: 'relief-undo');
    expect(await mapFile.readAsBytes(), mapBefore);
  });
}

Future<Map<String, String>> _tree(Directory root) async => {
      await for (final file in root.list(recursive: true))
        if (file is File)
          file.path.substring(root.path.length + 1):
              '${await file.length()}:${(await file.stat()).modified.microsecondsSinceEpoch}',
    };

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final List<String> paths = [];
  final LocalProjectFileReader delegate = const LocalProjectFileReader();
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
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

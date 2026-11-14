import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/spatial_terrain_relief_fixture.dart';
import '../domains/maps/spatial_terrain_slope_actions_test.dart'
    show stairProject;

void main() {
  test('a slope and a stair on the working catalog write only the edited map',
      () async {
    final root = Directory(
        '${Platform.environment['AVELUNE_QA_ROOT'] ?? '${Platform.environment['HOME']}/Library/Caches/AveluneQA'}/catalog-terrain-slope');
    if (await root.exists()) await root.delete(recursive: true);
    await root.create(recursive: true);
    addTearDown(() => root.delete(recursive: true));
    final map = paintRelief(reliefBaseMap(), rect(6, 4, 10, 6),
            level: 2, project: stairProject)
        .map;
    final entry = stairProject.maps.single;
    final project = stairProject.copyWith(maps: [
      entry,
      for (var i = 0; i < 20; i++)
        ProjectMapEntry(
            id: 'other-$i',
            name: 'Other $i',
            relativePath: 'maps/other-$i.json'),
    ]);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store, projectId: 'slope', project: project);
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
    final mapBefore = await mapFile.readAsBytes();
    for (final (action, parameters) in [
      (
        'map3d.terrain.paint_slope',
        <String, Object?>{
          'from': {'x': 9, 'y': 13},
          'to': {'x': 10, 'y': 8},
        }
      ),
      (
        'map3d.terrain.place_stair',
        <String, Object?>{
          'cell': {'x': 10, 'y': 9},
          'modelId': 'stone-stair',
        }
      ),
    ]) {
      final before = await _tree(root);
      reader.paths.clear();
      final request = {'mapId': map.id, ...parameters};
      final selected = await api.readWorkshopSnapshot(opened.projectHandle,
          actionId: action, parameters: request);
      final plan = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
              requestId: action,
              actionId: action,
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              expectedRevision: selected.revision,
              idempotencyKey: action,
              parameters: request));
      final applied = await api.applyMutation(opened.projectHandle,
          planId: plan.planId, operationId: action);
      expect(reader.paths.where((path) => path.startsWith('maps/other-')),
          isEmpty);
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
          [entry.relativePath],
          reason: action);
      final edited = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      expect(reliefStrokes(edited, 'relief-1').single.closed, isFalse);
      expect(edited.spatialScene!.terrainSurfaces.surfaces.last.closedFlanks,
          isTrue);
      await api.undoMutation(opened.projectHandle,
          entryId: applied.receipt.receiptId, idempotencyKey: '$action-undo');
      expect(await mapFile.readAsBytes(), mapBefore, reason: action);
    }
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

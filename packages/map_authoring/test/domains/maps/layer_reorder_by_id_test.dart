import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'named layer reorder is atomic on two maps over ${jsonl ? 'JSONL' : 'direct API'}',
        () async {
      final root =
          await Directory.systemTemp.createTemp('named-layer-reorder-');
      addTearDown(() => root.delete(recursive: true));
      final maps = [
        for (final id in ['orchard', 'observatory'])
          MapData(
              id: id,
              name: id,
              size: const GridSize(width: 2, height: 2),
              layers: [
                const ObjectLayer(id: 'base', name: 'Base'),
                const ObjectLayer(
                    id: 'moss-crown', name: 'Arbitrary owned layer'),
                const ObjectLayer(id: 'cloud-mask', name: 'Preserved overlay'),
              ])
      ];
      final project =
          ProjectManifest(name: 'Named layers', tilesets: [], maps: [
        for (final map in maps)
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
      ]);
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await Directory('${root.path}/maps').create();
      for (final map in maps) {
        await File('${root.path}/maps/${map.id}.json')
            .writeAsString(jsonEncode(map.toJson()));
      }
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: snapshots);
      final mutations = LocalMapAuthoringMutationApi(
          policy: policy, snapshotLoader: snapshots);
      final opened = await api.openProject(root.path);
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      final worker = JsonlWorker(api: api, mutations: mutations);
      var sequence = 0;
      Future<AuthoringResult> wire(
              String command, Map<String, Object?> args) async =>
          AuthoringResult.fromJson(jsonDecode(await worker.processLine(
              jsonEncode({
            'id': 'named-${sequence++}',
            'command': command,
            'args': args
          }))) as Map<String, dynamic>);
      Future<Map<String, Object?>> plan(
          String mapId, List<Map<String, Object?>> operations) async {
        final snapshot = await snapshots.load(opened.projectHandle);
        final id = 'layer-${sequence++}';
        final request = AuthoringRequest(
            requestId: id,
            idempotencyKey: id,
            actionId: 'map.apply_operations',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            parameters: {'mapId': mapId, 'operations': operations});
        if (!jsonl) return mutations.plan(opened.projectHandle, request);
        final result = await wire('plan', {
          'projectHandle': opened.projectHandle.value,
          'request': request.toJson()
        });
        if (result.status != AuthoringResultStatus.success) {
          throw MapAuthoringException(
              code: result.error!.details['domainCode'] as String,
              message: result.error!.message);
        }
        return result.data;
      }

      for (final map in maps) {
        final file = File('${root.path}/maps/${map.id}.json');
        final other = File(
            '${root.path}/maps/${maps.firstWhere((entry) => entry.id != map.id).id}.json');
        final before = await file.readAsBytes(),
            otherBefore = await other.readAsBytes();
        final planned = await plan(map.id, [
          {
            'kind': 'layer.reorder_by_id',
            'layerId': 'moss-crown',
            'newIndex': 0
          }
        ]);
        expect(await file.readAsBytes(), before);
        if (jsonl) {
          final result = await wire('apply', {
            'projectHandle': opened.projectHandle.value,
            'planId': planned['planId'],
            'operationId': 'apply-${map.id}'
          });
          expect(result.status, AuthoringResultStatus.success,
              reason: result.toJson().toString());
        } else {
          await mutations.apply(opened.projectHandle,
              planId: planned['planId'] as String,
              operationId: 'apply-${map.id}');
        }
        expect(
            MapData.fromJson(jsonDecode(await file.readAsString())
                    as Map<String, dynamic>)
                .layers
                .map((entry) => entry.id),
            ['moss-crown', 'base', 'cloud-mask']);
        expect(await other.readAsBytes(), otherBefore);
        for (final invalid in [
          {'kind': 'layer.reorder_by_id', 'layerId': 'missing', 'newIndex': 0},
          {'kind': 'layer.reorder_by_id', 'layerId': 'base', 'newIndex': -1},
          {'kind': 'layer.reorder_by_id', 'layerId': 'base', 'newIndex': 4},
        ]) {
          final bytes = await file.readAsBytes();
          await expectLater(
              plan(map.id, [
                {
                  'kind': 'layer.rename',
                  'layerId': 'base',
                  'name': 'Must never persist'
                },
                invalid
              ]),
              throwsA(isA<MapAuthoringException>().having(
                  (error) => error.code, 'code', 'map.operation_invalid')));
          expect(await file.readAsBytes(), bytes);
          expect(await other.readAsBytes(), otherBefore);
        }
      }
      await api.closeWorkspace(opened.workspaceHandle);
    });
  }
  test('duplicate local layer identities cannot be selected', () {
    final map = MapData(
        id: 'duplicate',
        name: 'Duplicate',
        size: const GridSize(width: 1, height: 1),
        layers: const [
          ObjectLayer(id: 'same', name: 'First'),
          ObjectLayer(id: 'same', name: 'Second')
        ]);
    expect(
        () => const MapLayerOperations().apply(map,
            {'kind': 'layer.reorder_by_id', 'layerId': 'same', 'newIndex': 0}),
        throwsA(isA<MapAuthoringException>()));
  });
}

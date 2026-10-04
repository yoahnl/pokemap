import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  for (final transport in ['directApi', 'jsonl']) {
    test('$transport first Border layer preserves front-first ordering on disk',
        () async {
      final root = await Directory.systemTemp.createTemp('uwu6-border-order-');
      addTearDown(() => root.delete(recursive: true));
      final map = catalogMap('garden');
      final manifest = catalogSnapshot([map]).manifest;
      await Directory('${root.path}/maps').create();
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(manifest.toJson()));
      final mapFile = File('${root.path}/maps/garden.json');
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final reads = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots,
      );
      final mutations = LocalMapAuthoringMutationApi(
          policy: policy, snapshotLoader: snapshots);
      final opened = await reads.openProject(root.path);
      addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      addTearDown(() => mutations.detachWorkspace(opened.workspaceHandle));
      final worker = JsonlWorker(api: reads, mutations: mutations);
      Future<Map<String, Object?>> wire(
          String command, Map<String, Object?> args) async {
        final result = AuthoringResult.fromJson(
            jsonDecode(await worker.processLine(jsonEncode({
          'id': command,
          'command': command,
          'args': args,
        }))) as Map<String, dynamic>);
        expect(result.status, AuthoringResultStatus.success,
            reason: result.toJson().toString());
        return result.data;
      }

      final snapshot = await snapshots.load(opened.projectHandle);
      final request = AuthoringRequest(
        requestId: 'first-border',
        actionId: 'map.apply_operations',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'first-border',
        parameters: {
          'mapId': 'garden',
          'operations': [
            {
              'kind': 'layer.add',
              'layerKind': 'border',
              'layerId': 'border',
              'name': 'Bordures'
            },
          ],
        },
      );
      final planned = transport == 'directApi'
          ? await mutations.plan(opened.projectHandle, request)
          : await wire('plan', {
              'projectHandle': opened.projectHandle.value,
              'request': request.toJson()
            });
      final applied = transport == 'directApi'
          ? await mutations.apply(opened.projectHandle,
              planId: planned['planId']! as String, operationId: 'apply-border')
          : await wire('apply', {
              'projectHandle': opened.projectHandle.value,
              'planId': planned['planId'],
              'operationId': 'apply-border'
            });
      expect(applied, isNotEmpty);
      final saved = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      expect(saved.layers.first.id, 'border');
      expect(saved.layers.skip(1), orderedEquals(map.layers));
      expect(saved.visualStack, map.visualStack);
    });
  }
}

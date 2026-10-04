import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  for (final transport in ['directApi', 'jsonl']) {
    test(
        '$transport preserves folder duplication and canonical resize/delete protections',
        () async {
      final root = await Directory.systemTemp.createTemp('catalog-transport-');
      addTearDown(() => root.delete(recursive: true));
      final source = catalogMap('source');
      final owner = catalogMap('owner').copyWith(warps: const [
        MapWarp(
            id: 'entry',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'source',
            targetPos: GridPos(x: 5, y: 0))
      ]);
      final initial = catalogSnapshot([source, owner]);
      final project = initial.manifest.copyWith(groups: const [
        ProjectMapGroup(id: 'folder', name: 'Folder', type: MapGroupType.city)
      ]);
      await Directory('${root.path}/maps').create();
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      for (final map in [source, owner]) {
        await File('${root.path}/maps/${map.id}.json')
            .writeAsString(jsonEncode(map.toJson()));
      }
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final reads = AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: snapshots);
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
      final description = AuthoringResult.fromJson(jsonDecode(
          await worker.processLine(jsonEncode({
        'id': 'describe-catalog',
        'command': 'describe',
        'args': {}
      }))) as Map<String, dynamic>);
      final descriptor = (description.data['mutationActions'] as List)
          .cast<Map>()
          .singleWhere((action) => action['id'] == 'map.duplicate');
      final schema = ((descriptor['extensions'] as Map)['inputSchema'] as Map);
      expect((schema['properties'] as Map)['groupId'], {
        'type': ['string', 'null']
      });
      expect(schema['selfReferences'], 'sourceMap');
      var sequence = 0;
      Future<Map<String, Object?>> call(
          String command, Map<String, Object?> args) async {
        if (transport == 'jsonl') {
          final result = AuthoringResult.fromJson(jsonDecode(
              await worker.processLine(jsonEncode({
            'id': 'wire-${sequence++}',
            'command': command,
            'args': args
          }))) as Map<String, dynamic>);
          if (result.status != AuthoringResultStatus.success) {
            throw StateError(result.toJson().toString());
          }
          return result.data;
        }
        return switch (command) {
          'plan' => mutations.plan(
              opened.projectHandle,
              AuthoringRequest.fromJson(
                  Map<String, dynamic>.from(args['request']! as Map))),
          'confirm' => mutations.confirm(opened.projectHandle,
              planId: args['planId']! as String),
          'apply' => mutations.apply(opened.projectHandle,
              planId: args['planId']! as String,
              operationId: args['operationId']! as String,
              confirmationToken: args['confirmationToken'] as String?),
          _ => throw StateError(command),
        };
      }

      Future<Map<String, Object?>> plan(
          String action, Map<String, Object?> params) async {
        final snapshot = await snapshots.load(opened.projectHandle);
        final request = AuthoringRequest(
            requestId: 'plan-${sequence++}',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'idem-${sequence++}',
            parameters: params);
        return call('plan', {
          'projectHandle': opened.projectHandle.value,
          'request': request.toJson()
        });
      }

      Future<void> apply(Map<String, Object?> planned,
          {bool destructive = false}) async {
        final args = <String, Object?>{
          'projectHandle': opened.projectHandle.value,
          'planId': planned['planId'],
          'operationId': 'apply-${sequence++}'
        };
        if (destructive) {
          final confirmation = await call('confirm', {
            'projectHandle': opened.projectHandle.value,
            'planId': planned['planId']
          });
          args['confirmationToken'] = confirmation['confirmationToken'];
        }
        final result = await call('apply', args);
        expect((result['receipt'] as Map)['status'], 'applied');
      }

      final before = await File('${root.path}/maps/source.json').readAsBytes();
      await expectLater(
          plan(
              'map.resize_apply', {'mapId': 'source', 'width': 4, 'height': 5}),
          throwsA(predicate(
              (error) => error.toString().contains('map.resize_impacts'))));
      await expectLater(
          plan('map.delete_apply', {'mapId': 'source'}),
          throwsA(predicate((error) =>
              error.toString().contains('map.references_blocking'))));
      expect(await File('${root.path}/maps/source.json').readAsBytes(), before);
      await apply(await plan(
          'map.duplicate', {'sourceMapId': 'source', 'groupId': 'folder'}));
      final copied = await snapshots.load(opened.projectHandle);
      expect(
          copied.manifest.maps
              .singleWhere((entry) => entry.id == 'source_copy')
              .groupId,
          'folder');
      expect(copied.mapById('source_copy')!.size, source.size);
      await apply(await plan('map.resize_apply',
          {'mapId': 'source_copy', 'width': 7, 'height': 6}));
      expect(
          (await snapshots.load(opened.projectHandle))
              .mapById('source_copy')!
              .size,
          const GridSize(width: 7, height: 6));
      await apply(await plan('map.delete_apply', {'mapId': 'source_copy'}),
          destructive: true);
      expect(
          await File('${root.path}/maps/source_copy.json').exists(), isFalse);
      expect(await File('${root.path}/maps/source.json').readAsBytes(), before);
      expect(
          (await snapshots.load(opened.projectHandle))
              .manifest
              .maps
              .map((entry) => entry.id),
          unorderedEquals(['owner', 'source']));
    });
  }
}

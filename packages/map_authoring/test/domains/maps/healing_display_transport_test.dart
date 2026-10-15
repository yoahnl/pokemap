import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'healing_display_fixture.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'Healing display ${jsonl ? 'JSONL' : 'direct API'} applies, clears and undoes only the healing display payload',
        () async {
      final root =
          await Directory.systemTemp.createTemp('healing-display-authoring-');
      addTearDown(() => root.delete(recursive: true));
      final map = healingMap();
      final project = healingProject();
      final mapFile = File('${root.path}/maps/route.json');
      await mapFile.parent.create();
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      final projectFile = File('${root.path}/project.json');
      await projectFile.writeAsString(jsonEncode(project.toJson()));
      final projectBefore = await projectFile.readAsBytes();
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
      final worker = JsonlWorker(api: api, mutations: mutations);
      var sequence = 0;
      Future<AuthoringResult> wireResult(
              String command, Map<String, Object?> args) async =>
          AuthoringResult.fromJson(
              jsonDecode(await worker.processLine(jsonEncode({
            'id': 'healing-display-${sequence++}',
            'command': command,
            'args': args,
          }))) as Map<String, dynamic>);
      Future<Map<String, Object?>> wire(
          String command, Map<String, Object?> args) async {
        final result = await wireResult(command, args);
        expect(result.status, AuthoringResultStatus.success,
            reason: '${result.toJson()}');
        return result.data;
      }

      final described = await wire('describe', {});
      final descriptor = (described['mutationActions']! as List)
          .cast<Map>()
          .singleWhere(
              (action) => action['id'] == 'entity.set_healing_display');
      expect((descriptor['extensions']! as Map)['healingDisplay'], isA<Map>());
      late ProjectHandle projectHandle;
      late WorkspaceHandle workspaceHandle;
      if (jsonl) {
        final opened = await wire('open', {'projectRoot': root.path});
        projectHandle = ProjectHandle(opened['projectHandle']! as String);
        workspaceHandle = WorkspaceHandle(opened['workspaceHandle']! as String);
      } else {
        final opened = await api.openProject(root.path);
        projectHandle = opened.projectHandle;
        workspaceHandle = opened.workspaceHandle;
        await mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: workspaceHandle,
            projectHandle: projectHandle);
      }
      Future<Map<String, Object?>> call(
          String command, Map<String, Object?> args) async {
        if (jsonl) {
          return wire(command, {'projectHandle': projectHandle.value, ...args});
        }
        return switch (command) {
          'plan' => mutations.plan(
              projectHandle,
              AuthoringRequest.fromJson(
                  Map<String, dynamic>.from(args['request']! as Map))),
          'apply' => mutations.apply(projectHandle,
              planId: args['planId']! as String,
              operationId: args['operationId']! as String),
          'history' => mutations.history(projectHandle, limit: 1),
          'undo' => mutations.undo(projectHandle,
              entryId: args['entryId']! as String,
              idempotencyKey: args['idempotencyKey']! as String),
          'query' => api.query(
              projectHandle,
              AuthoringQueryRequest.fromJson(
                  Map<String, dynamic>.from(args['request']! as Map))),
          _ => throw StateError(command),
        };
      }

      Future<AuthoringRequest> request(Object? healingDisplay,
          {String? revision}) async {
        final snapshot = await snapshots.load(projectHandle);
        return AuthoringRequest(
            requestId: 'healing-display-${sequence++}',
            actionId: 'entity.set_healing_display',
            actionVersion: 1,
            workspaceHandle: workspaceHandle.value,
            expectedRevision: revision ?? snapshot.revision,
            idempotencyKey: 'healing-display-${sequence++}',
            parameters: {
              'mapId': 'route',
              'entityId': 'balls',
              'healingDisplay': healingDisplay,
            });
      }

      Future<MapData> read() async {
        final data = await call('query', {
          'request': AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: ['route'],
          ).toJson()
        });
        return MapData.fromJson(
            Map<String, dynamic>.from((data['items']! as List).single as Map));
      }

      final initial = await snapshots.load(projectHandle);
      final before = await mapFile.readAsBytes();
      final set = await request(healingPayload().toJson());
      final plan = await call('plan', {'request': set.toJson()});
      expect(await mapFile.readAsBytes(), before);
      await call(
          'apply', {'planId': plan['planId'], 'operationId': 'set-display'});
      final expected = map.copyWith(entities: [
        map.entities.single.copyWith(healingDisplay: healingPayload())
      ]);
      expect(await read(), expected);
      final afterSet = await mapFile.readAsBytes();
      final stale = await request(null, revision: initial.revision);
      if (jsonl) {
        final result = await wireResult('plan',
            {'projectHandle': projectHandle.value, 'request': stale.toJson()});
        expect(result.status, AuthoringResultStatus.failure);
        expect(result.error!.code, AuthoringErrorCode.revisionConflict);
        expect(result.error!.details['domainCode'], 'plan.stale');
      } else {
        await expectLater(
            mutations.plan(projectHandle, stale),
            throwsA(isA<AuthoringPlanException>()
                .having((error) => error.code, 'code', 'plan.stale')));
      }
      expect(await mapFile.readAsBytes(), afterSet);
      final clear = await request(null);
      final clearPlan = await call('plan', {'request': clear.toJson()});
      expect(await mapFile.readAsBytes(), afterSet);
      await call('apply',
          {'planId': clearPlan['planId'], 'operationId': 'clear-display'});
      expect(await read(), map);
      final history = await call('history', {'limit': 1});
      final entry = (history['entries']! as List).single as Map;
      await call('undo', {
        'entryId': entry['entryId'],
        'idempotencyKey': 'undo-clear-display'
      });
      expect(await read(), expected);
      expect(await mapFile.readAsBytes(), afterSet);
      expect(await projectFile.readAsBytes(), projectBefore);
      if (jsonl) {
        await wire('close', {'workspaceHandle': workspaceHandle.value});
      } else {
        await api.closeWorkspace(workspaceHandle);
      }
    });
  }
}

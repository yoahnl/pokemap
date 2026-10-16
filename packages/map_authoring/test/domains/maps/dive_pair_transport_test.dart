import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'dive_pair_actions_test.dart' show divePairMap;

void main() {
  for (final jsonl in [false, true]) {
    test(
        'Dive ${jsonl ? 'JSONL' : 'direct API'} plans without writes, publishes, unlinks and reopens cold',
        () async {
      final root = await Directory.systemTemp.createTemp('dive-authoring-');
      addTearDown(() => root.delete(recursive: true));
      final maps = [
        divePairMap('sea', DiveZoneRole.surface),
        divePairMap('deep', DiveZoneRole.underwater)
      ];
      await Directory('${root.path}/maps').create();
      for (final map in maps) {
        await File('${root.path}/maps/${map.id}.json')
            .writeAsString(jsonEncode(map.toJson()));
      }
      final mapFile = File('${root.path}/maps/sea.json');
      final project =
          ProjectManifest(name: 'Dive transport', tilesets: const [], maps: [
        for (final map in maps)
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
      ]);
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
          AuthoringResult.fromJson(jsonDecode(await worker.processLine(
              jsonEncode({
            'id': 'dive-${sequence++}',
            'command': command,
            'args': args
          }))) as Map<String, dynamic>);
      Future<Map<String, Object?>> wire(
          String command, Map<String, Object?> args) async {
        final result = await wireResult(command, args);
        expect(result.status, AuthoringResultStatus.success,
            reason: '${result.toJson()}');
        return result.data;
      }

      late ProjectHandle projectHandle;
      late WorkspaceHandle workspaceHandle;
      if (jsonl) {
        final opened = await wire('open', {'projectRoot': root.path});
        projectHandle = ProjectHandle(opened['projectHandle'] as String);
        workspaceHandle = WorkspaceHandle(opened['workspaceHandle'] as String);
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
                  Map<String, dynamic>.from(args['request'] as Map))),
          'apply' => mutations.apply(projectHandle,
              planId: args['planId'] as String,
              operationId: args['operationId'] as String),
          'history' => mutations.history(projectHandle, limit: 1),
          'undo' => mutations.undo(projectHandle,
              entryId: args['entryId'] as String,
              idempotencyKey: args['idempotencyKey'] as String),
          _ => throw StateError(command),
        };
      }

      Future<Map<String, Object?>> plan(
          String action, Map<String, Object?> params) async {
        final snapshot = await snapshots.load(projectHandle);
        final request = AuthoringRequest(
            requestId: 'dive-${sequence++}',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'dive-${sequence++}',
            parameters: {'mapId': 'sea', ...params});
        final before = await mapFile.readAsBytes();
        final result = await call('plan', {'request': request.toJson()});
        expect(await mapFile.readAsBytes(), before);
        return result;
      }

      Future<void> apply(String action, Map<String, Object?> params) async {
        final prepared = await plan(action, params);
        await call('apply', {
          'planId': prepared['planId'],
          'operationId': 'dive-${sequence++}'
        });
      }

      Future<MapData> read(String id) async => MapData.fromJson(
          jsonDecode(await File('${root.path}/maps/$id.json').readAsString())
              as Map<String, dynamic>);
      final parameters = {
        'zoneId': 'point',
        'targetMapId': 'deep',
        'targetZoneId': 'point'
      };
      await plan('gameplay_zone.dive.link_pair_apply', parameters);
      expect((await read('sea')).gameplayZones.last.fieldAction!.dive!.link,
          isNull);
      expect((await read('deep')).gameplayZones.last.fieldAction!.dive!.link,
          isNull);
      await apply('gameplay_zone.dive.link_pair_apply', parameters);
      validateDiveZonePair(
          sourceMap: await read('sea'),
          sourceZoneId: 'point',
          targetMap: await read('deep'),
          targetZoneId: 'point');
      final linkedBytes =
          await File('${root.path}/maps/deep.json').readAsBytes();
      await plan('gameplay_zone.dive.unlink_pair_apply', {'zoneId': 'point'});
      expect(
          await File('${root.path}/maps/deep.json').readAsBytes(), linkedBytes);
      await apply('gameplay_zone.dive.unlink_pair_apply', {'zoneId': 'point'});
      expect(await read('sea'), maps.first);
      expect(await read('deep'), maps.last);
      expect(await projectFile.readAsBytes(), projectBefore);
      if (jsonl) {
        await wire('close', {'workspaceHandle': workspaceHandle.value});
      } else {
        await mutations.detachWorkspace(workspaceHandle);
        api.closeWorkspace(workspaceHandle);
      }
    });
  }
}

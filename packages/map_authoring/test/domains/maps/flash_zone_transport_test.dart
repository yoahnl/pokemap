import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

Map<String, Object?> darkness(double opacity) => {
      'actionKind': 'darkness',
      'darkness': {'opacity': opacity},
    };
Map<String, Object?> zoneJson() => {
      'id': 'dark',
      'kind': 'fieldAction',
      'area': {
        'pos': {'x': 1, 'y': 1},
        'size': {'width': 2, 'height': 2}
      },
      'fieldAction': darkness(.7),
    };

void main() {
  test(
      'Flash parity registry points to the four executed semantic transport journeys',
      () {
    final evidence = AuthoringFullParityCatalog.canonical()
        .requireMutationAction('gameplay_zone.set_field_action_payload');
    const paths = {
      AuthoringTransport.directApi:
          'test/domains/maps/flash_zone_transport_test.dart',
      AuthoringTransport.cli:
          'test/domains/maps/flash_zone_transport_test.dart',
      AuthoringTransport.editor:
          '../../apps/avelune_studio/test/map_workspace/flash_zone_editing_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/flash_zone_stdio.test.ts',
    };
    expect(evidence.endToEndEvidence, paths);
    expect(evidence.endToEndVerifiedTransports, paths.keys.toSet());
    expect(evidence.contractTestPath, paths[AuthoringTransport.directApi]);
    for (final path in paths.values) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
  test(
      'canonical update retypes a painted encounter into an exclusive darkness rectangle',
      () {
    final map = catalogMap('cave').copyWith(gameplayZones: const [
      MapGameplayZone(
          id: 'dark',
          kind: GameplayZoneKind.encounter,
          area: MapRect(
              pos: GridPos(x: 1, y: 1), size: GridSize(width: 2, height: 2)),
          cellMask: [GridPos(x: 0, y: 0)],
          encounter: EncounterZonePayload()),
    ]);
    final draft = const TriggerZoneActions().build(catalogContext(
        catalogSnapshot([map]),
        'gameplay_zone.update',
        {'mapId': 'cave', 'zoneId': 'dark', 'zone': zoneJson()}));
    final updated = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>);
    expect(updated.gameplayZones.single.cellMask, isNull);
    expect(updated.gameplayZones.single.kind, GameplayZoneKind.fieldAction);
    expect(updated.gameplayZones.single.fieldAction!.darkness.opacity, .7);
  });
  for (final jsonl in [false, true]) {
    test(
        'Flash ${jsonl ? 'JSONL' : 'direct API'} creates, edits, undoes and cold reopens a semantic zone',
        () async {
      final root = await Directory.systemTemp.createTemp('flash-authoring-');
      addTearDown(() => root.delete(recursive: true));
      final mapFile = File('${root.path}/maps/cave.json');
      await mapFile.parent.create();
      await mapFile.writeAsString(jsonEncode(catalogMap('cave').toJson()));
      const project = ProjectManifest(
          name: 'Flash transport',
          tilesets: [],
          maps: [
            ProjectMapEntry(
                id: 'cave', name: 'Cave', relativePath: 'maps/cave.json')
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
            'id': 'flash-${sequence++}',
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

      final description = await wire('describe', {});
      final descriptor = (description['mutationActions'] as List)
          .cast<Map>()
          .singleWhere((action) =>
              action['id'] == 'gameplay_zone.set_field_action_payload');
      expect(
          ((descriptor['extensions'] as Map)['fieldActionZone']
              as Map)['lifetime'],
          'mapInstance');
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
            requestId: 'flash-${sequence++}',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'flash-${sequence++}',
            parameters: {'mapId': 'cave', ...params});
        final before = await mapFile.readAsBytes();
        final result = await call('plan', {'request': request.toJson()});
        expect(await mapFile.readAsBytes(), before);
        return result;
      }

      Future<void> apply(String action, Map<String, Object?> params) async {
        final prepared = await plan(action, params);
        await call('apply', {
          'planId': prepared['planId'],
          'operationId': 'flash-${sequence++}'
        });
      }

      Future<MapData> read() async => MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      await apply('gameplay_zone.create', {'zone': zoneJson()});
      expect((await read()).gameplayZones.single.fieldAction!.darkness.opacity,
          .7);
      await plan('gameplay_zone.set_field_action_payload',
          {'zoneId': 'dark', 'payload': darkness(.35)});
      expect((await read()).gameplayZones.single.fieldAction!.darkness.opacity,
          .7);
      await apply('gameplay_zone.set_field_action_payload',
          {'zoneId': 'dark', 'payload': darkness(.85)});
      expect((await read()).gameplayZones.single.fieldAction!.darkness.opacity,
          .85);
      final history = await call('history', {'limit': 1});
      await call('undo', {
        'entryId': ((history['entries'] as List).first as Map)['entryId'],
        'idempotencyKey': 'undo-flash'
      });
      expect((await read()).gameplayZones.single.fieldAction!.darkness.opacity,
          .7);
      await apply('gameplay_zone.move', {'zoneId': 'dark', 'x': 2, 'y': 1});
      await apply(
          'gameplay_zone.resize', {'zoneId': 'dark', 'width': 3, 'height': 2});
      await apply(
          'gameplay_zone.set_priority', {'zoneId': 'dark', 'priority': 2});
      await apply('gameplay_zone.clone',
          {'zoneId': 'dark', 'newId': 'dark-copy', 'x': 0, 'y': 0});
      await apply('gameplay_zone.clear_payload', {'zoneId': 'dark-copy'});
      expect((await read()).gameplayZones.last.fieldAction, isNull);
      await apply('gameplay_zone.delete', {'zoneId': 'dark-copy'});
      final cold = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      expect(cold.gameplayZones.single.fieldAction!.darkness.opacity, .7);
      expect(cold.gameplayZones.single.area.pos, const GridPos(x: 2, y: 1));
      expect(cold.gameplayZones.single.priority, 2);
      expect(await projectFile.readAsBytes(), projectBefore);
    });
  }
}

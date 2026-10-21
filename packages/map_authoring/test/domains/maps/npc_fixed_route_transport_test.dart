import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'fixed-route steps and suspension survive ${jsonl ? 'JSONL' : 'direct API'} plan/apply',
        () async {
      final root =
          await Directory.systemTemp.createTemp('npc-fixed-route-transport-');
      addTearDown(() => root.delete(recursive: true));
      final map = catalogMap('center').copyWith(entities: [
        MapEntity(
            id: 'nurse',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 2, y: 1),
            npc: const MapEntityNpcData(displayName: 'Nurse')),
      ]);
      final projectFile = File('${root.path}/project.json');
      final mapFile = File('${root.path}/maps/center.json');
      await mapFile.parent.create();
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      await projectFile.writeAsString(jsonEncode(ProjectManifest(
          name: 'Counter transport',
          version: ProjectVersion.v8,
          maps: [
            const ProjectMapEntry(
                id: 'center', name: 'Center', relativePath: 'maps/center.json')
          ],
          tilesets: []).toJson()));
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
      Future<Map<String, Object?>> wire(
          String command, Map<String, Object?> args) async {
        final result = AuthoringResult.fromJson(jsonDecode(
            await worker.processLine(jsonEncode({
          'id': 'fixed-route-$command',
          'command': command,
          'args': args
        }))) as Map<String, dynamic>);
        expect(result.status, AuthoringResultStatus.success,
            reason: result.toJson().toString());
        return result.data;
      }

      late String projectHandle;
      late String workspaceHandle;
      if (jsonl) {
        final opened = await wire('open', {'projectRoot': root.path});
        projectHandle = opened['projectHandle']! as String;
        workspaceHandle = opened['workspaceHandle']! as String;
      } else {
        final opened = await api.openProject(root.path);
        projectHandle = opened.projectHandle.value;
        workspaceHandle = opened.workspaceHandle.value;
        await mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
      }
      final snapshot = await snapshots.load(ProjectHandle(projectHandle));
      final request = AuthoringRequest(
          requestId: 'fixed-route-edit',
          actionId: 'npc.set_movement_mode',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'fixed-route-edit',
          parameters: {
            'mapId': 'center',
            'entityId': 'nurse',
            'mode': 'fixedRoute',
            'routeSteps': [
              {'kind': 'move', 'direction': 'east'},
              {'kind': 'face', 'direction': 'west'},
              {'kind': 'randomFacing'},
              {'kind': 'randomMove'},
            ],
            'suspendWhenInstanceBoolean': {
              'key': 'npc.autonomousRouteStopped',
              'value': true
            },
            'pauseDurationMs': 1600,
            'stepDurationMs': 250,
            'loop': true,
          });
      final before = await mapFile.readAsBytes();
      final projectBefore = await projectFile.readAsBytes();
      final plan = jsonl
          ? await wire('plan',
              {'projectHandle': projectHandle, 'request': request.toJson()})
          : await mutations.plan(ProjectHandle(projectHandle), request);
      expect(await mapFile.readAsBytes(), before);
      if (jsonl) {
        await wire('apply', {
          'projectHandle': projectHandle,
          'planId': plan['planId'],
          'operationId': 'apply-fixed-route'
        });
      } else {
        await mutations.apply(ProjectHandle(projectHandle),
            planId: plan['planId']! as String,
            operationId: 'apply-fixed-route');
      }
      final updated = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      final movement = updated.entities.single.npc!.movement;
      expect(movement.mode, MapEntityNpcMovementMode.fixedRoute);
      expect(movement.routeSteps, const [
        MapEntityNpcRouteStep.move(direction: EntityFacing.east),
        MapEntityNpcRouteStep.face(direction: EntityFacing.west),
        MapEntityNpcRouteStep.randomFacing(),
        MapEntityNpcRouteStep.randomMove(),
      ]);
      expect(movement.pauseDurationMs, 1600);
      expect(movement.stepDurationMs, 250);
      expect(movement.suspendWhenInstanceBoolean,
          MapEntityNpcRouteInstanceBoolean(key: 'npc.autonomousRouteStopped'));
      expect(updated.entities.single.npc!.displayName, 'Nurse');
      expect(updated.entities.single.pos, map.entities.single.pos);
      expect(updated.layers, map.layers);
      expect(await projectFile.readAsBytes(), projectBefore);
      await expectLater(
          mutations.plan(
              ProjectHandle(projectHandle),
              AuthoringRequest(
                  requestId: 'stale-fixed-route',
                  actionId: request.actionId,
                  actionVersion: 1,
                  workspaceHandle: workspaceHandle,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: 'stale-fixed-route',
                  parameters: request.parameters)),
          throwsA(isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.stale')));
      expect(
          MapData.fromJson(
              jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>),
          updated);
      await api.closeWorkspace(WorkspaceHandle(workspaceHandle));
    });
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'NPC local time conditions survive ${jsonl ? 'JSONL' : 'direct API'} plan/apply',
        () async {
      final root =
          await Directory.systemTemp.createTemp('npc-hours-transport-');
      addTearDown(() => root.delete(recursive: true));
      final map = catalogMap('center').copyWith(entities: [
        MapEntity(
            id: 'nurse',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 2, y: 1),
            npc: const MapEntityNpcData(
                displayName: 'Nurse', trainerId: 'guard')),
      ]);
      final projectFile = File('${root.path}/project.json');
      final mapFile = File('${root.path}/maps/center.json');
      await mapFile.parent.create();
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      await projectFile.writeAsString(jsonEncode(ProjectManifest(
          name: 'NPC hours transport',
          trainers: const [
            ProjectTrainerEntry(
                id: 'guard', name: 'Guard', trainerClass: 'Police')
          ],
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
          'id': 'counter-$command',
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
          requestId: 'counter-edit',
          actionId: 'npc.set_trainer_battle_rule',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'counter-edit',
          parameters: {
            'mapId': 'center',
            'entityId': 'nurse',
            'trainerBattleWhen': const MapEntityRuntimePredicate(
                    kind: MapEntityRuntimePredicateKind.localTimeWindow,
                    timeWindow:
                        LocalTimeWindow(startMinute: 1200, endMinute: 240))
                .toJson(),
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
          'operationId': 'apply-counter'
        });
      } else {
        await mutations.apply(ProjectHandle(projectHandle),
            planId: plan['planId']! as String, operationId: 'apply-counter');
      }
      final updated = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      expect(updated.entities.single.npc!.trainerBattleWhen!.timeWindow,
          const LocalTimeWindow(startMinute: 1200, endMinute: 240));
      expect(updated.entities.single.npc!.displayName, 'Nurse');
      expect(updated.entities.single.pos, map.entities.single.pos);
      expect(updated.layers, map.layers);
      expect(await projectFile.readAsBytes(), projectBefore);
      await expectLater(
          mutations.plan(
              ProjectHandle(projectHandle),
              AuthoringRequest(
                  requestId: 'stale-counter',
                  actionId: request.actionId,
                  actionVersion: 1,
                  workspaceHandle: workspaceHandle,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: 'stale-counter',
                  parameters: request.parameters)),
          throwsA(isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.stale')));
      expect(
          MapData.fromJson(
              jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>),
          updated);
      const presence = MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.localTimeWindow,
              timeWindow: LocalTimeWindow(startMinute: 240, endMinute: 1200)));
      final presenceRequest = AuthoringRequest(
          requestId: 'hours-presence',
          actionId: 'npc.set_visibility_rule',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          expectedRevision:
              (await snapshots.load(ProjectHandle(projectHandle))).revision,
          idempotencyKey: 'hours-presence',
          parameters: {
            'mapId': 'center',
            'entityId': 'nurse',
            'visibilityRule': presence.toJson()
          });
      final beforePresence = await mapFile.readAsBytes();
      final presencePlan = jsonl
          ? await wire('plan', {
              'projectHandle': projectHandle,
              'request': presenceRequest.toJson()
            })
          : await mutations.plan(ProjectHandle(projectHandle), presenceRequest);
      expect(await mapFile.readAsBytes(), beforePresence);
      if (jsonl) {
        await wire('apply', {
          'projectHandle': projectHandle,
          'planId': presencePlan['planId'],
          'operationId': 'apply-hours-presence'
        });
      } else {
        await mutations.apply(ProjectHandle(projectHandle),
            planId: presencePlan['planId']! as String,
            operationId: 'apply-hours-presence');
      }
      await api.closeWorkspace(WorkspaceHandle(workspaceHandle));
      final reopened = await api.openProject(root.path);
      final reloaded = await snapshots.load(reopened.projectHandle);
      expect(reloaded.maps.single.entities.single.npc!.trainerBattleWhen,
          updated.entities.single.npc!.trainerBattleWhen);
      expect(
          reloaded.maps.single.entities.single.npc!.visibilityRule, presence);
      expect(await projectFile.readAsBytes(), projectBefore);
      await api.closeWorkspace(reopened.workspaceHandle);
    });
  }
  test(
      'typed NPC presence and battle actions validate and preserve the payload',
      () {
    final map = catalogMap('center').copyWith(entities: [
      const MapEntity(
          id: 'guard',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(
              displayName: 'Guard',
              trainerId: 'guard',
              dialogue: DialogueRef(dialogueId: 'day'))),
    ]);
    const predicate = MapEntityRuntimePredicate(
        kind: MapEntityRuntimePredicateKind.localTimeWindow,
        timeWindow: LocalTimeWindow(startMinute: 1200, endMinute: 240));
    const actions = EntityActions();
    final visible = actions.setVisibilityRule(map,
        entityId: 'guard',
        visibilityRule: const MapEntityNpcVisibilityRule(
            mode: MapEntityNpcVisibilityMode.visibleWhen,
            predicate: predicate));
    final gated = actions.setTrainerBattleRule(visible,
        entityId: 'guard', trainerBattleWhen: predicate);
    expect(gated.entities.single.npc!.displayName, 'Guard');
    expect(gated.entities.single.npc!.dialogue!.dialogueId, 'day');
    expect(gated.entities.single.npc!.visibilityRule,
        visible.entities.single.npc!.visibilityRule);
    expect(MapData.fromJson(gated.toJson()).entities.single.npc,
        gated.entities.single.npc);
    final cleared = actions.setTrainerBattleRule(gated,
        entityId: 'guard', trainerBattleWhen: null);
    expect(cleared.entities.single.npc!.trainerBattleWhen, isNull);
    expect(
        actions
            .setVisibilityRule(cleared, entityId: 'guard', visibilityRule: null)
            .entities
            .single
            .npc!
            .visibilityRule,
        isNull);
    expect(
        () => actions.setTrainerBattleRule(map,
            entityId: 'guard',
            trainerBattleWhen: const MapEntityRuntimePredicate(
                kind: MapEntityRuntimePredicateKind.localTimeWindow,
                timeWindow: LocalTimeWindow(startMinute: 10, endMinute: 10))),
        throwsA(isA<ValidationException>()));
    final noTrainer = map.copyWith(entities: [
      map.entities.single.copyWith(npc: const MapEntityNpcData())
    ]);
    expect(
        () => actions.setTrainerBattleRule(noTrainer,
            entityId: 'guard', trainerBattleWhen: predicate),
        throwsA(isA<ValidationException>()));
  });
}

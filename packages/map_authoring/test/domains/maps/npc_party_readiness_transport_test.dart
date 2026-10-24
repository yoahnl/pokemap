import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'NPC readiness condition and refusal survive ${jsonl ? 'JSONL' : 'direct API'} plan/apply',
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
          dialogues: const [
            ProjectDialogueEntry(
                id: 'refusal',
                name: 'Refus',
                relativePath: 'dialogues/refusal.yarn')
          ],
          version: ProjectVersion.v8,
          maps: [
            const ProjectMapEntry(
                id: 'center', name: 'Center', relativePath: 'maps/center.json')
          ],
          tilesets: []).toJson()));
      final refusal = File('${root.path}/dialogues/refusal.yarn');
      await refusal.parent.create();
      await refusal.writeAsString(
          'title: Start\n---\nIl vous faut deux Pokémon en forme.\n===\n');
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
          actionId: 'npc.set_trainer_battle_readiness',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'counter-edit',
          parameters: {
            'mapId': 'center',
            'entityId': 'nurse',
            'trainerBattleNotReadyDialogue':
                const DialogueRef(dialogueId: 'refusal').toJson(),
            'trainerBattleReadyWhen': const MapEntityRuntimePredicate(
                    kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
                    minimumCount: 2)
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
      expect(
          updated.entities.single.npc!.trainerBattleReadyWhen!.minimumCount, 2);
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
      expect(
          updated
              .entities.single.npc!.trainerBattleNotReadyDialogue?.dialogueId,
          'refusal');
      await api.closeWorkspace(WorkspaceHandle(workspaceHandle));
      final reopened = await api.openProject(root.path);
      final reloaded = await snapshots.load(reopened.projectHandle);
      expect(reloaded.maps.single.entities.single.npc!.trainerBattleReadyWhen,
          updated.entities.single.npc!.trainerBattleReadyWhen);
      expect(
          reloaded
              .maps.single.entities.single.npc!.trainerBattleNotReadyDialogue,
          updated.entities.single.npc!.trainerBattleNotReadyDialogue);
      await api.closeWorkspace(reopened.workspaceHandle);
    });
  }
}

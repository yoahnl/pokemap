import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'standard_event_template_test.dart'
    show templateMap, templateProject, templateSpec;

void main() {
  test('standard event contract declares its actual four transport proofs', () {
    final evidence = AuthoringFullParityCatalog.canonical()
        .requireMutationAction('event_v2.template.apply');
    expect(evidence.endToEndEvidence.keys.toSet(),
        AuthoringTransport.values.toSet());
    expect(evidence.contractTestPath,
        'test/domains/narrative/standard_event_template_transport_test.dart');
    expect(evidence.endToEndEvidence[AuthoringTransport.editor],
        '../../apps/avelune_studio/test/events/standard_event_template_publication_test.dart');
  });

  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'API'} discovers and atomically applies owned pages',
        () async {
      final temporary =
          await Directory.systemTemp.createTemp('standard-template-');
      final root = Directory(await temporary.resolveSymbolicLinks());
      addTearDown(() => root.delete(recursive: true));
      final map = templateMap();
      final manifest = templateProject().copyWith(
          trainers: [],
          tilesets: const [
            ProjectTilesetEntry(
                id: 'people', name: 'People', relativePath: 'people.png')
          ]);
      await Directory('${root.path}/maps').create();
      await Directory('${root.path}/dialogues').create();
      await File('${root.path}/people.png').writeAsBytes(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j4WQAAAAASUVORK5CYII='));
      for (final dialogue in manifest.dialogues) {
        await File('${root.path}/${dialogue.relativePath}')
            .writeAsString('title: Start\n---\nHello.\n===\n');
      }
      final projectFile = File('${root.path}/project.json');
      final mapFile = File('${root.path}/maps/room.json');
      await projectFile.writeAsString(jsonEncode(manifest.toJson()));
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(root.path);
      final mutations = LocalMapAuthoringMutationApi(
          policy: policy, snapshotLoader: snapshots);
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      addTearDown(() => mutations.detachWorkspace(opened.workspaceHandle));
      final worker = JsonlWorker(
          api: AuthoringReadApi(openService: opener, snapshotLoader: snapshots),
          mutations: mutations);
      Future<AuthoringResult> command(
              String id, String name, Map<String, Object?> arguments) async =>
          AuthoringResult.fromJson(jsonDecode(await worker.processLine(
                  jsonEncode({'id': id, 'command': name, 'args': arguments})))
              as Map<String, dynamic>);
      final described = await command('describe', 'describe', {});
      expect(
          jsonEncode(described.toJson()), contains('event_v2.template.apply'));
      final beforeProject = await projectFile.readAsBytes();
      final beforeMap = await mapFile.readAsBytes();
      final snapshot = await snapshots.load(opened.projectHandle);
      AuthoringRequest request(String id, StandardEventTemplateSpec spec,
              {String? mapRevision}) =>
          AuthoringRequest(
              requestId: id,
              actionId: 'event_v2.template.apply',
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: id,
              parameters: {
                'spec': spec.toJson(),
                'mapRevision': mapRevision ??
                    narrativeEventBytesFingerprint(
                        snapshot.resourceBytes('map:room'))
              });
      final invalid = templateSpec(StandardEventTemplateKind.conditionalNpc);
      final badSpec = StandardEventTemplateSpec(
          kind: invalid.kind,
          mapId: invalid.mapId,
          entityId: invalid.entityId,
          name: invalid.name,
          parameters: {...invalid.parameters, 'dialogueId': 'missing'});
      if (jsonl) {
        final rejected = await command('invalid', 'plan', {
          'projectHandle': opened.projectHandle.value,
          'request': request('invalid', badSpec).toJson()
        });
        expect(rejected.status, AuthoringResultStatus.failure);
      } else {
        await expectLater(
            mutations.planMutation(
                opened.projectHandle, request('invalid', badSpec)),
            throwsA(isA<Exception>()));
      }
      expect(await projectFile.readAsBytes(), beforeProject);
      expect(await mapFile.readAsBytes(), beforeMap);
      late String planId;
      if (jsonl) {
        final planned = await command('plan', 'plan', {
          'projectHandle': opened.projectHandle.value,
          'request': request('valid', invalid).toJson()
        });
        expect(planned.status, AuthoringResultStatus.success,
            reason: jsonEncode(planned.toJson()));
        planId = planned.data['planId'] as String;
      } else {
        planId = (await mutations.planMutation(
                opened.projectHandle, request('valid', invalid)))
            .planId;
      }
      expect(await projectFile.readAsBytes(), beforeProject);
      expect(await mapFile.readAsBytes(), beforeMap);
      if (jsonl) {
        final result = await command('apply', 'apply', {
          'projectHandle': opened.projectHandle.value,
          'planId': planId,
          'operationId': 'apply'
        });
        expect(result.status, AuthoringResultStatus.success,
            reason: jsonEncode(result.toJson()));
      } else {
        await mutations.applyMutation(opened.projectHandle,
            planId: planId, operationId: 'apply');
      }
      final reopened = await snapshots.load(opened.projectHandle);
      expect(reopened.manifest.eventRegistry!.records, hasLength(2));
      expect(reopened.manifest.scenes, hasLength(2));
      expect(
          readStandardEventTemplate(
                  project: reopened.manifest,
                  map: reopened.maps.single,
                  entityId: 'guide')
              ?.toJson(),
          invalid.toJson());
      expect(reopened.manifest.eventRegistry!.mode, EventSystemMode.v2Only);
      expect(reopened.manifest.dialogues, manifest.dialogues);
    });
  }
}

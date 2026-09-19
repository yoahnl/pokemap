import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL discovers coherent dialogue/map publication and reopens it',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('narrative_document_');
    final root = Directory(await temporary.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    final map = MapData(
        id: 'garden',
        name: 'Jardin',
        size: const GridSize(width: 2, height: 2),
        layers: [
          TileLayer(id: 'ground', name: 'Sol', cells: [0, 0, 0, 0])
        ]);
    final manifest = ProjectManifest(name: 'Publication', maps: [
      const ProjectMapEntry(
          id: 'garden', name: 'Jardin', relativePath: 'maps/garden.json')
    ], tilesets: []);
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/garden.json')
        .writeAsString(jsonEncode(map.toJson()));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(root.path);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() => mutations.detachWorkspace(opened.workspaceHandle));
    final worker = JsonlWorker(
        api: AuthoringReadApi(openService: opener, snapshotLoader: snapshots),
        mutations: mutations);
    Future<AuthoringResult> request(
            String id, String command, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(jsonDecode(await worker.processLine(
                jsonEncode({'id': id, 'command': command, 'args': args})))
            as Map<String, dynamic>);
    final described = await request('describe', 'describe', {});
    expect(
        jsonEncode(described.toJson()), contains('narrative.publish_document'));
    final snapshot = await snapshots.load(opened.projectHandle);
    final dirty = map.copyWith(name: 'Carte et dialogue');
    const entry = ProjectDialogueEntry(
        id: 'hello', name: 'Bonjour', relativePath: 'dialogues/hello.yarn');
    const source = 'title: Start\n---\nBonjour !\n===\n';
    final plan = await request('plan', 'plan', {
      'projectHandle': opened.projectHandle.value,
      'request': AuthoringRequest(
          requestId: 'narrative_plan',
          actionId: 'narrative.publish_document',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'narrative_publish',
          parameters: {
            'map': dirty.toJson(),
            'mapRevision': narrativeEventBytesFingerprint(
                snapshot.resourceBytes('map:garden')),
            'dialogues': [
              {'entry': entry.toJson(), 'source': source, 'revision': null}
            ],
          }).toJson(),
    });
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    expect(await File('${root.path}/dialogues/hello.yarn').exists(), false);
    final applied = await request('apply', 'apply', {
      'projectHandle': opened.projectHandle.value,
      'planId': plan.data['planId'],
      'operationId': 'narrative_apply'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    final after = await snapshots.load(opened.projectHandle);
    expect(after.manifest.dialogues, [entry]);
    expect(after.maps.single, dirty);
    expect(utf8.decode(after.resourceBytes('dialogueSource:hello')), source);
    expect(after.manifest.eventRegistry, manifest.eventRegistry);
  });
}

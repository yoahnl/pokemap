import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'direct and JSONL publish the same final Presentation and classification',
      () async {
    final direct = await _run(false);
    final jsonl = await _run(true);
    expect(jsonl, direct);
    final project = ProjectManifest.fromJson(direct);
    expect(project.presentationCinematics.single.title, 'Titre final édité');
    expect(project.cinematicLibraryCatalog.entries.single.family,
        CinematicLibraryFamily.presentation);
    expect(project.maps, isEmpty);
  });
}

Future<Map<String, dynamic>> _run(bool jsonl) async {
  final temp =
      await Directory.systemTemp.createTemp('presentation_ui11_transport_');
  final root = Directory(await temp.resolveSymbolicLinks());
  final file = File('${root.path}/project.json');
  await file.writeAsString(jsonEncode(ProjectManifest(
      name: 'UI11',
      version: ProjectVersion.v7,
      maps: const [],
      tilesets: const []).toJson()));
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: snapshots);
  final mutations =
      LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
  final worker = JsonlWorker(api: api, mutations: mutations);
  Future<Map<String, Object?>> request(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': command, 'command': command, 'args': args})))
        as Map<String, dynamic>);
    expect(result.status, AuthoringResultStatus.success,
        reason: result.error?.toJson().toString());
    return result.data;
  }

  final opened = jsonl
      ? await request('open', {'projectRoot': root.path})
      : await api.open(root.path);
  final project = ProjectHandle(opened['projectHandle'] as String);
  final workspace = WorkspaceHandle(opened['workspaceHandle'] as String);
  try {
    if (!jsonl) {
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: workspace,
          projectHandle: project);
    }
    final before = await file.readAsBytes();
    final revision = (await snapshots.load(project)).revision;
    final command = AuthoringRequest(
        requestId: 'publish',
        actionId: 'presentationCinematic.publish',
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: revision,
        idempotencyKey: 'publish',
        parameters: {
          'cinematic': encodePresentationCinematicAsset(
              PresentationCinematicAsset(
                  id: 'intro',
                  title: 'Titre final édité',
                  durationUs: 12000000)),
          'expectedCinematic': null,
          'expectedEntry': null,
          'expectedMedia': [],
          'folderId': null,
          'imports': [],
        });
    final plan = jsonl
        ? await request('plan',
            {'projectHandle': project.value, 'request': command.toJson()})
        : await mutations.plan(project, command);
    expect(await file.readAsBytes(), before);
    final args = {
      'projectHandle': project.value,
      'planId': plan['planId'],
      'operationId': 'save-intro'
    };
    if (jsonl) {
      await request('apply', args);
      await request('apply', args);
    } else {
      await mutations.apply(project,
          planId: plan['planId'] as String, operationId: 'save-intro');
      await mutations.apply(project,
          planId: plan['planId'] as String, operationId: 'save-intro');
    }
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } finally {
    if (jsonl) {
      await request('close', {'workspaceHandle': workspace.value});
    } else {
      await mutations.detachWorkspace(workspace);
      await api.close(workspace);
    }
    await root.delete(recursive: true);
  }
}

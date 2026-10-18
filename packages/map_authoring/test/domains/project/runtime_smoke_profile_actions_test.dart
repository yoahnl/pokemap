import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'API'} configures two independent runtime policies and removes one',
        () async {
      for (final name in ['first', 'second']) {
        final h = await _Harness.create(name);
        addTearDown(h.dispose);
        final profile = {
          'id': '$name-runtime',
          'version': 3,
          'requiredSuiteIds': ['$name-start', '$name-win']
        };
        expect((await h.query(jsonl)).items, isEmpty);
        await h.configure(profile, jsonl);
        final record = (await h.query(jsonl)).items.single;
        expect(record['id'], profile['id']);
        expect(record['version'], 3);
        expect(record['requiredSuiteIds'], profile['requiredSuiteIds']);
        final manifest = ProjectManifest.fromJson(
            jsonDecode(await h.file.readAsString()) as Map<String, dynamic>);
        expect(manifest.toJson()['runtimeSmokeProfile'], profile);
        expect(manifest.name, name);
        await h.configure(null, jsonl);
        expect((await h.query(jsonl)).items, isEmpty);
        expect(
            (jsonDecode(await h.file.readAsString()) as Map)
                .containsKey('runtimeSmokeProfile'),
            isFalse);
      }
    });
  }

  test('invalid profiles and stale revisions preserve exact manifest bytes',
      () async {
    final h = await _Harness.create('guarded');
    addTearDown(h.dispose);
    final before = await h.file.readAsBytes();
    for (final invalid in [
      {
        'id': 'policy',
        'version': 0,
        'requiredSuiteIds': ['start']
      },
      {'id': 'policy', 'version': 1, 'requiredSuiteIds': []},
      {
        'id': 'policy',
        'version': 1,
        'requiredSuiteIds': ['start'],
        'unknown': true
      },
    ]) {
      await expectLater(h.configure(invalid, false), throwsA(anything));
      expect(await h.file.readAsBytes(), before);
    }
    final revision = (await h.snapshots.load(h.opened.projectHandle)).revision;
    await h.configure({
      'id': 'policy',
      'version': 1,
      'requiredSuiteIds': ['start']
    }, false);
    final saved = await h.file.readAsBytes();
    await expectLater(
        h.configure(null, false, revision: revision), throwsA(anything));
    expect(await h.file.readAsBytes(), saved);
  });
}

class _Harness {
  _Harness(this.root, this.file, this.api, this.mutations, this.snapshots,
      this.opened, this.worker);
  final Directory root;
  final File file;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;

  static Future<_Harness> create(String name) async {
    final root = await Directory.systemTemp.createTemp('runtime-policy-');
    final file = File('${root.path}/project.json');
    await file.writeAsString(jsonEncode(
        ProjectManifest(name: name, maps: [], tilesets: []).toJson()));
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
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Harness(root, file, api, mutations, snapshots, opened,
        JsonlWorker(api: api, mutations: mutations));
  }

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': command, 'command': command, 'args': args})))
        as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw StateError(result.toJson().toString());
    }
    return result.data;
  }

  Future<AuthoringQueryPage> query(bool jsonl) async {
    final request = AuthoringQueryRequest(
        resourceKind: 'runtimeSmokeProfile',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail);
    return jsonl
        ? AuthoringQueryPage.fromJson(Map<String, dynamic>.from(await wire(
            'query', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          })))
        : api.queryProject(opened.projectHandle, request);
  }

  Future<void> configure(Object? profile, bool jsonl,
      {String? revision}) async {
    final id = 'policy-${sequence++}';
    final request = AuthoringRequest(
        requestId: id,
        actionId: 'validation.runtime_smoke_profile.configure',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision:
            revision ?? (await snapshots.load(opened.projectHandle)).revision,
        idempotencyKey: id,
        parameters: {'profile': profile});
    final before = await file.readAsBytes();
    final plan = jsonl
        ? await wire('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          })
        : await mutations.plan(opened.projectHandle, request);
    expect(await file.readAsBytes(), before);
    if (jsonl) {
      await wire('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan['planId'],
        'operationId': id
      });
    } else {
      await mutations.apply(opened.projectHandle,
          planId: plan['planId']! as String, operationId: id);
    }
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

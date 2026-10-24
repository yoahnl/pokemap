import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    final transport = jsonl ? 'JSONL' : 'API';
    test('$transport renames a project preserving content and supports undo',
        () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final before = await h.document();
      final mapBytes = await h.mapFile.readAsBytes();
      final fileBytes = await h.file.readAsBytes();
      final plan = await h.plan({'name': '  Étoile — 冒険  '}, jsonl);
      expect(await h.file.readAsBytes(), fileBytes);
      final result = await h.apply(plan, jsonl);
      expect(await h.document(), {...before, 'name': 'Étoile — 冒険'});
      expect(await h.mapFile.readAsBytes(), mapBytes);
      final receipt = result['receipt']! as Map;
      final repeated = await h.apply(plan, jsonl);
      expect((repeated['receipt']! as Map)['receiptId'], receipt['receiptId']);
      await h.undo(receipt['receiptId']! as String, jsonl);
      expect(await h.document(), before);
      expect(await h.mapFile.readAsBytes(), mapBytes);
    });

    test(
        '$transport rejects invalid names and stale plans without changing data',
        () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final before = await h.file.readAsBytes();
      for (final parameters in <Map<String, Object?>>[
        {},
        {'name': null},
        {'name': 2},
        {'name': ''},
        {'name': '   '},
        {'name': 'A\nB'},
        {'name': 'A\u0000B'},
        {'name': 'A\u007fB'},
        {'name': 'Valid', 'maps': []},
      ]) {
        await expectLater(h.plan(parameters, jsonl), throwsA(anything));
        expect(await h.file.readAsBytes(), before);
      }
      final stale = await h.plan({'name': 'Stale'}, jsonl);
      final current = await h.plan({'name': 'Current'}, jsonl);
      await h.apply(current, jsonl);
      final after = await h.file.readAsBytes();
      await expectLater(h.apply(stale, jsonl), throwsA(anything));
      expect(await h.file.readAsBytes(), after);
    });

    test('$transport treats an unchanged normalized name as a no-op', () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final before = await h.file.readAsBytes();
      final plan = await h.plan({'name': '  Adventure  '}, jsonl);
      final extensions = (plan['receipt']! as Map)['extensions']! as Map;
      expect((extensions['preview']! as Map)['noOp'], isTrue);
      await expectLater(h.apply(plan, jsonl), throwsA(anything));
      expect(await h.file.readAsBytes(), before);
    });
  }
}

final class _Harness {
  _Harness(this.root, this.file, this.mapFile, this.api, this.mutations,
      this.snapshots, this.opened, this.worker);

  final Directory root;
  final File file;
  final File mapFile;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;

  static Future<_Harness> create() async {
    final root = await Directory.systemTemp.createTemp('project-identity-');
    final file = File('${root.path}/project.json');
    final mapFile = File('${root.path}/maps/garden.json');
    await mapFile.parent.create();
    await mapFile.writeAsString(jsonEncode(MapData(
            id: 'garden',
            name: 'Garden',
            size: const GridSize(width: 3, height: 3))
        .toJson()));
    await file.writeAsString(jsonEncode(ProjectManifest(
      name: 'Adventure',
      maps: const [
        ProjectMapEntry(
            id: 'garden', name: 'Garden', relativePath: 'maps/garden.json')
      ],
      tilesets: [],
    ).toJson()));
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
    return _Harness(root, file, mapFile, api, mutations, snapshots, opened,
        JsonlWorker(api: api, mutations: mutations));
  }

  Future<Map<String, Object?>> document() async =>
      Map<String, Object?>.from(jsonDecode(await file.readAsString()) as Map);

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final response = AuthoringResult.fromJson(jsonDecode(
        await worker.processLine(jsonEncode({
      'id': 'wire-${sequence++}',
      'command': command,
      'args': args
    }))) as Map<String, dynamic>);
    if (response.status != AuthoringResultStatus.success) {
      throw StateError(response.toJson().toString());
    }
    return response.data;
  }

  Future<Map<String, Object?>> plan(
      Map<String, Object?> parameters, bool jsonl) async {
    final id = 'rename-${sequence++}';
    final request = AuthoringRequest(
        requestId: id,
        actionId: 'project.rename',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: (await snapshots.load(opened.projectHandle)).revision,
        idempotencyKey: id,
        parameters: parameters);
    return jsonl
        ? wire('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          })
        : mutations.plan(opened.projectHandle, request);
  }

  Future<Map<String, Object?>> apply(
      Map<String, Object?> plan, bool jsonl) async {
    final planId = plan['planId']! as String;
    return jsonl
        ? wire('apply', {
            'projectHandle': opened.projectHandle.value,
            'planId': planId,
            'operationId': 'apply-$planId'
          })
        : mutations.apply(opened.projectHandle,
            planId: planId, operationId: 'apply-$planId');
  }

  Future<void> undo(String entryId, bool jsonl) async {
    if (jsonl) {
      await wire('undo', {
        'projectHandle': opened.projectHandle.value,
        'entryId': entryId,
        'idempotencyKey': 'undo-$entryId'
      });
    } else {
      await mutations.undo(opened.projectHandle,
          entryId: entryId, idempotencyKey: 'undo-$entryId');
    }
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

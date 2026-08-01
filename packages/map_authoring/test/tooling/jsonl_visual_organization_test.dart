import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL applies and queries visual folders and categories', () async {
    final fixture = await _VisualFixture.create();
    addTearDown(fixture.dispose);
    final opened = await fixture.request(
      'open',
      args: {'projectRoot': fixture.root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;

    await fixture.apply(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: 'tileset_folder.upsert',
      parameters: const {
        'folder': {'id': 'm02', 'name': 'M02', 'sortOrder': 2},
      },
    );
    await fixture.apply(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: 'element_category.upsert',
      parameters: const {
        'category': {'id': 'nature', 'name': 'Nature', 'sortOrder': 1},
      },
    );

    final folders = await fixture.query(projectHandle, 'tilesetFolder');
    final categories = await fixture.query(projectHandle, 'elementCategory');
    expect(
      (folders.data['items']! as List).single,
      containsPair('id', 'm02'),
    );
    expect(
      (categories.data['items']! as List).single,
      containsPair('id', 'nature'),
    );

    final manifest = ProjectManifest.fromJson(
      jsonDecode(await File('${fixture.root.path}/project.json').readAsString())
          as Map<String, dynamic>,
    );
    expect(manifest.tilesetFolders.single.id, 'm02');
    expect(manifest.elementCategories.single.id, 'nature');

    final missing = await fixture.plan(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: 'tileset_folder.delete',
      parameters: const {'folderId': 'missing'},
    );
    expect(missing.status, AuthoringResultStatus.failure);
    expect(missing.error!.code, AuthoringErrorCode.notFound);
    expect(missing.error!.details['domainCode'], 'tileset_folder.unknown');
  });
}

final class _VisualFixture {
  _VisualFixture({
    required this.root,
    required this.snapshots,
    required this.worker,
  });

  static Future<_VisualFixture> create() async {
    final root = await Directory.systemTemp.createTemp('jsonl-visual-org-');
    final manifest = ProjectManifest(
      name: 'Visual organization fixture',
      version: ProjectVersion.v3,
      maps: const [],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _VisualFixture(
      root: root,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<AuthoringResult> apply({
    required String projectHandle,
    required String workspaceHandle,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    final planned = await plan(
      projectHandle: projectHandle,
      workspaceHandle: workspaceHandle,
      actionId: actionId,
      parameters: parameters,
    );
    expect(
      planned.status,
      AuthoringResultStatus.success,
      reason: jsonEncode(planned.toJson()),
    );
    final applied = await request(
      'apply',
      args: {
        'projectHandle': projectHandle,
        'planId': planned.data['planId'],
        'operationId': 'operation-$actionId',
      },
    );
    expect(
      applied.status,
      AuthoringResultStatus.success,
      reason: jsonEncode(applied.toJson()),
    );
    return applied;
  }

  Future<AuthoringResult> plan({
    required String projectHandle,
    required String workspaceHandle,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    return request(
      'plan',
      args: {
        'projectHandle': projectHandle,
        'request': AuthoringRequest(
          requestId: 'request-$actionId',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'idempotency-$actionId',
        ).toJson(),
      },
    );
  }

  Future<AuthoringResult> query(String projectHandle, String resourceKind) =>
      request(
        'query',
        args: {
          'projectHandle': projectHandle,
          'request': AuthoringQueryRequest(
            resourceKind: resourceKind,
            operation: AuthoringQueryOperation.list,
            view: AuthoringQueryView.detail,
          ).toJson(),
        },
      );

  Future<AuthoringResult> request(
    String command, {
    Map<String, Object?> args = const {},
  }) async {
    final decoded = jsonDecode(
      await worker.processLine(
        jsonEncode({
          'id': 'request-$command',
          'command': command,
          'args': args,
        }),
      ),
    ) as Map<String, dynamic>;
    return AuthoringResult.fromJson(decoded);
  }

  Future<void> dispose() => root.delete(recursive: true);
}

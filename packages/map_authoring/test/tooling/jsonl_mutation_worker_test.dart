import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL exposes lifecycle plan and apply without leaking roots',
      () async {
    final root = await Directory.systemTemp.createTemp('jsonl-mutation-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final manifest = ProjectManifest(
      name: 'JSONL Mutation Fixture',
      version: ProjectVersion.v3,
      maps: const [],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
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
    final worker = JsonlWorker(api: readApi, mutations: mutations);

    final described = await _request(worker, 'describe');
    expect(described.status, AuthoringResultStatus.success);
    expect(described.data['readOnly'], isFalse);
    expect(
      (described.data['commands']! as List)
          .cast<Map<String, Object?>>()
          .map((command) => command['id']),
      [
        'apply',
        'close',
        'confirm',
        'describe',
        'history',
        'open',
        'plan',
        'query',
        'recover',
        'stage_artifact',
        'undo',
        'validate'
      ],
    );

    final opened = await _request(
      worker,
      'open',
      args: {'projectRoot': root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    expect(opened.data['readOnly'], isFalse);
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final request = AuthoringRequest(
      requestId: 'create-jsonl-map',
      actionId: 'map.create',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const {
        'mapId': 'jsonl_map',
        'width': 2,
        'height': 2,
      },
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_jsonl_map',
      dryRun: false,
    );
    final planned = await _request(
      worker,
      'plan',
      args: {
        'projectHandle': projectHandle,
        'request': request.toJson(),
      },
    );
    expect(planned.status, AuthoringResultStatus.success);
    final applied = await _request(
      worker,
      'apply',
      args: {
        'projectHandle': projectHandle,
        'planId': planned.data['planId'],
        'operationId': 'operation_jsonl_map',
      },
    );
    expect(applied.status, AuthoringResultStatus.success);
    expect(
      (applied.data['receipt']! as Map<String, Object?>)['status'],
      'applied',
    );
    expect(await File('${root.path}/maps/jsonl_map.json').exists(), isTrue);

    final history = await _request(
      worker,
      'history',
      args: {
        'projectHandle': projectHandle,
        'limit': 1,
      },
    );
    expect(history.status, AuthoringResultStatus.success);
    expect(history.data['entries'], hasLength(1));
    expect(
      ((history.data['entries']! as List).single as Map)['operationId'],
      'operation_jsonl_map',
    );
    final directHistory = await mutations.history(
      ProjectHandle(projectHandle),
      limit: 1,
    );
    expect(history.data, directHistory);

    final transcript = jsonEncode({
      'describe': described.toJson(),
      'open': opened.toJson(),
      'plan': planned.toJson(),
      'apply': applied.toJson(),
      'history': history.toJson(),
    });
    expect(transcript, isNot(contains(root.path)));
    expect(transcript, isNot(contains('/private/')));
  });
}

Future<AuthoringResult> _request(
  JsonlWorker worker,
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

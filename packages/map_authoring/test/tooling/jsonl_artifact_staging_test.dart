import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL stages an allowed file for asset.import', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final source = File('${fixture.root.path}/source.png');
    await source.writeAsBytes(_pngBytes);

    final staged = await fixture.request(
      'stage_artifact',
      args: {
        'sourcePath': source.path,
        'declaredMediaType': 'image/png',
      },
    );

    expect(staged.status, AuthoringResultStatus.success);
    expect(staged.data['artifactHandle'], startsWith('artifact://sha256/'));
    expect(staged.data['mediaType'], 'image/png');
    expect(jsonEncode(staged.toJson()), isNot(contains(source.path)));

    final opened = await fixture.open();
    final snapshot = await fixture.snapshots.load(opened.projectHandle);
    final planned = await fixture.request(
      'plan',
      args: {
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'stage-import-request',
          actionId: 'asset.import',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: {
            'artifactHandle': staged.data['artifactHandle'],
            'assetId': 'staged-png',
            'logicalPath': 'images/staged.png',
          },
          expectedRevision: snapshot.revision,
          idempotencyKey: 'stage-import-idempotency',
        ).toJson(),
      },
    );

    expect(planned.status, AuthoringResultStatus.success);
  });

  test('JSONL refuses artifact sources outside allowed roots', () async {
    final fixture = await _Fixture.create();
    final outside = await Directory.systemTemp.createTemp('artifact-outside-');
    addTearDown(fixture.dispose);
    addTearDown(() => outside.delete(recursive: true));
    final source = File('${outside.path}/source.png');
    await source.writeAsBytes(_pngBytes);

    final staged = await fixture.request(
      'stage_artifact',
      args: {'sourcePath': source.path},
    );

    expect(staged.status, AuthoringResultStatus.failure);
    expect(staged.error!.code, AuthoringErrorCode.permissionDenied);
    expect(
      staged.error!.details['domainCode'],
      'artifact.source_outside_allowed_roots',
    );
  });

  test('JSONL preserves an unknown artifact domain error', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final opened = await fixture.open();
    final snapshot = await fixture.snapshots.load(opened.projectHandle);

    final planned = await fixture.request(
      'plan',
      args: {
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'unknown-artifact-request',
          actionId: 'asset.import',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const {
            'artifactHandle':
                'artifact://sha256/0000000000000000000000000000000000000000000000000000000000000000',
            'assetId': 'unknown-png',
            'logicalPath': 'images/unknown.png',
          },
          expectedRevision: snapshot.revision,
          idempotencyKey: 'unknown-artifact-idempotency',
        ).toJson(),
      },
    );

    expect(planned.status, AuthoringResultStatus.failure);
    expect(planned.error!.code, AuthoringErrorCode.notFound);
    expect(planned.error!.details['domainCode'], 'artifact.unknown');
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.snapshots,
    required this.worker,
  });

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp('jsonl-artifact-');
    final manifest = ProjectManifest(
      name: 'JSONL artifact fixture',
      version: ProjectVersion.v6,
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
    final artifacts = LocalArtifactStore(
      allowedSourceRoots: [root.path],
      maximumArtifactBytes: 1024,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
    );
    return _Fixture(
      root: root,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<OpenedProject> open() async {
    final result = await request(
      'open',
      args: {'projectRoot': root.path},
    );
    expect(result.status, AuthoringResultStatus.success);
    return OpenedProject(
      workspaceHandle:
          WorkspaceHandle(result.data['workspaceHandle']! as String),
      projectHandle: ProjectHandle(result.data['projectHandle']! as String),
      projectName: result.data['projectName']! as String,
      fingerprint: result.data['fingerprint']! as String,
      expiresAt: DateTime.parse(result.data['expiresAt']! as String),
    );
  }

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

const _pngBytes = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
];

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Presentation clip authoring keeps direct and JSONL transactions equivalent',
    () async {
      final direct = await _Harness.create('direct');
      final jsonl = await _Harness.create('jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directResult = await direct.runDirect();
      final jsonlResult = await jsonl.runJsonl();

      expect(directResult.dryRunBytes, directResult.initialBytes);
      expect(jsonlResult.dryRunBytes, jsonlResult.initialBytes);
      expect(directResult.stablePlan, jsonlResult.stablePlan);
      expect(directResult.stableReceipt, jsonlResult.stableReceipt);
      expect(directResult.replayReceipt, directResult.appliedReceipt);
      expect(jsonlResult.replayReceipt, jsonlResult.appliedReceipt);
      expect(directResult.query, jsonlResult.query);
      expect(directResult.historyActionId, 'presentationClip.create');
      expect(jsonlResult.historyActionId, 'presentationClip.create');
      expect(directResult.afterUndoBytes, directResult.initialBytes);
      expect(jsonlResult.afterUndoBytes, jsonlResult.initialBytes);
      expect(directResult.staleDomainCode, 'plan.stale');
      expect(jsonlResult.staleDomainCode, 'plan.stale');
      expect(
        directResult.duplicateDomainCode,
        'presentation_cinematic.validation_failed',
      );
      expect(
        jsonlResult.duplicateDomainCode,
        'presentation_cinematic.validation_failed',
      );
    },
  );
}

final class _Harness {
  _Harness._({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_Harness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_presentation_cinematic_$suffix',
    );
    final manifest = ProjectManifest(
      name: 'Presentation cinematic transport fixture',
      version: ProjectVersion.v7,
      maps: const [],
      tilesets: const [],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 4000000,
          tracks: <PresentationTrack>[
            PresentationTrack(
              id: 'markers',
              label: 'Markers',
              kind: PresentationTrackKind.marker,
            ),
          ],
        ),
      ],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
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
    return _Harness._(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<_FlowResult> runDirect() async {
    final opened = await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final initialBytes = await _projectBytes();
    final snapshot = await snapshots.load(project);
    final dryRun = await mutations.plan(
      project,
      _request(workspace.value, snapshot.revision, 'dry-run', dryRun: true),
    );
    expect(dryRun['applicable'], isFalse);
    expect(dryRun['nonApplicableReason'], 'dry_run');
    final dryRunBytes = await _projectBytes();
    final plan = await mutations.plan(
      project,
      _request(workspace.value, snapshot.revision, 'apply'),
    );
    final applied = await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'operation-presentation-clip',
    );
    final replay = await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'operation-presentation-clip',
    );
    final query = await readApi.query(project, _clipQuery());
    final history = await mutations.history(project, limit: 1);
    final entry = Map<String, Object?>.from(
      (history['entries']! as List).single as Map,
    );
    final duplicateDomainCode = await _directDuplicateCode(
      project,
      workspace.value,
    );
    final staleDomainCode = await _directStaleCode(project, workspace.value);
    await mutations.undo(
      project,
      entryId: entry['entryId']! as String,
      idempotencyKey: 'undo-presentation-clip',
    );
    return _FlowResult(
      initialBytes: initialBytes,
      dryRunBytes: dryRunBytes,
      stablePlan: _stablePlan(plan),
      appliedReceipt: _receipt(applied),
      replayReceipt: _receipt(replay),
      stableReceipt: _stableReceipt(_receipt(applied)),
      query: query,
      historyActionId:
          (entry['receipt']! as Map<String, Object?>)['actionId']! as String,
      staleDomainCode: staleDomainCode,
      duplicateDomainCode: duplicateDomainCode,
      afterUndoBytes: await _projectBytes(),
    );
  }

  Future<_FlowResult> runJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    final validated = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final initialBytes = await _projectBytes();
    final dryRun = await _jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        validated['snapshotRevision']! as String,
        'dry-run',
        dryRun: true,
      ).toJson(),
    });
    expect(dryRun['applicable'], isFalse);
    expect(dryRun['nonApplicableReason'], 'dry_run');
    final dryRunBytes = await _projectBytes();
    final plan = await _jsonl('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        validated['snapshotRevision']! as String,
        'apply',
      ).toJson(),
    });
    final applyArgs = <String, Object?>{
      'projectHandle': project,
      'planId': plan['planId'],
      'operationId': 'operation-presentation-clip',
    };
    final applied = await _jsonl('apply', applyArgs);
    final replay = await _jsonl('apply', applyArgs);
    final query = await _jsonl('query', <String, Object?>{
      'projectHandle': project,
      'request': _clipQuery().toJson(),
    });
    final history = await _jsonl('history', <String, Object?>{
      'projectHandle': project,
      'limit': 1,
    });
    final entry = Map<String, Object?>.from(
      (history['entries']! as List).single as Map,
    );
    final duplicateDomainCode = await _jsonlDuplicateCode(project, workspace);
    final stale = await _jsonlResult('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(workspace, _staleRevision, 'stale').toJson(),
    });
    await _jsonl('undo', <String, Object?>{
      'projectHandle': project,
      'entryId': entry['entryId'],
      'idempotencyKey': 'undo-presentation-clip',
    });
    return _FlowResult(
      initialBytes: initialBytes,
      dryRunBytes: dryRunBytes,
      stablePlan: _stablePlan(plan),
      appliedReceipt: _receipt(applied),
      replayReceipt: _receipt(replay),
      stableReceipt: _stableReceipt(_receipt(applied)),
      query: query,
      historyActionId:
          (entry['receipt']! as Map<String, Object?>)['actionId']! as String,
      staleDomainCode: stale.error!.details['domainCode']! as String,
      duplicateDomainCode: duplicateDomainCode,
      afterUndoBytes: await _projectBytes(),
    );
  }

  Future<String> _directDuplicateCode(
    ProjectHandle project,
    String workspace,
  ) async {
    final snapshot = await snapshots.load(project);
    try {
      await mutations.plan(
        project,
        _request(workspace, snapshot.revision, 'duplicate'),
      );
    } on PresentationCinematicAuthoringException catch (error) {
      return error.code;
    }
    throw StateError('The duplicate clip request was accepted.');
  }

  Future<String> _directStaleCode(
    ProjectHandle project,
    String workspace,
  ) async {
    try {
      await mutations.plan(
        project,
        _request(workspace, _staleRevision, 'stale'),
      );
    } on AuthoringPlanException catch (error) {
      return error.code;
    }
    throw StateError('The stale request was accepted.');
  }

  Future<String> _jsonlDuplicateCode(String project, String workspace) async {
    final validated = await _jsonl('validate', <String, Object?>{
      'projectHandle': project,
    });
    final duplicate = await _jsonlResult('plan', <String, Object?>{
      'projectHandle': project,
      'request': _request(
        workspace,
        validated['snapshotRevision']! as String,
        'duplicate',
      ).toJson(),
    });
    return duplicate.error!.details['domainCode']! as String;
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final result = await _jsonlResult(command, args);
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: result.error?.toJson().toString(),
    );
    return result.data;
  }

  Future<AuthoringResult> _jsonlResult(
    String command,
    Map<String, Object?> args,
  ) async {
    return AuthoringResult.fromJson(
      jsonDecode(
        await worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'request-$command',
            'command': command,
            'args': args,
          }),
        ),
      ) as Map<String, dynamic>,
    );
  }

  Future<List<int>> _projectBytes() =>
      File('${root.path}/project.json').readAsBytes();

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _FlowResult {
  const _FlowResult({
    required this.initialBytes,
    required this.dryRunBytes,
    required this.stablePlan,
    required this.appliedReceipt,
    required this.replayReceipt,
    required this.stableReceipt,
    required this.query,
    required this.historyActionId,
    required this.staleDomainCode,
    required this.duplicateDomainCode,
    required this.afterUndoBytes,
  });

  final List<int> initialBytes;
  final List<int> dryRunBytes;
  final Map<String, Object?> stablePlan;
  final Map<String, Object?> appliedReceipt;
  final Map<String, Object?> replayReceipt;
  final Map<String, Object?> stableReceipt;
  final Map<String, Object?> query;
  final String historyActionId;
  final String staleDomainCode;
  final String duplicateDomainCode;
  final List<int> afterUndoBytes;
}

AuthoringRequest _request(
  String workspaceHandle,
  String revision,
  String sequence, {
  bool dryRun = false,
}) {
  return AuthoringRequest(
    requestId: 'request-$sequence',
    actionId: 'presentationClip.create',
    actionVersion: 1,
    workspaceHandle: workspaceHandle,
    parameters: const <String, Object?>{
      'cinematicId': 'opening',
      'trackId': 'markers',
      'clip': <String, Object?>{
        'id': 'beat',
        'kind': 'marker',
        'startUs': 1000000,
        'durationUs': 0,
        'label': 'Beat',
        'markerKind': 'ordinary',
      },
    },
    expectedRevision: revision,
    idempotencyKey: 'idempotency-$sequence',
    dryRun: dryRun,
  );
}

AuthoringQueryRequest _clipQuery() => AuthoringQueryRequest(
      resourceKind: 'presentationClip',
      operation: AuthoringQueryOperation.list,
      filters: const <String, Object?>{
        'cinematicId': 'opening',
        'trackId': 'markers',
      },
      pageSize: 1,
      view: AuthoringQueryView.detail,
      fieldMask: const <String>['cinematicId', 'trackId', 'startUs'],
    );

Map<String, Object?> _stablePlan(Map<String, Object?> response) {
  final plan = Map<String, Object?>.from(response['plan']! as Map);
  return <String, Object?>{
    'actionId': plan['actionId'],
    'actionVersion': plan['actionVersion'],
    'baseRevision': plan['baseRevision'],
    'projectedRevision': plan['projectedRevision'],
    'applicable': plan['applicable'],
    'changeSet': plan['changeSet'],
    'preview': plan['preview'],
    'referenceImpact': plan['referenceImpact'],
    'artifacts': plan['artifacts'],
  };
}

Map<String, Object?> _receipt(Map<String, Object?> response) =>
    Map<String, Object?>.from(response['receipt']! as Map);

Map<String, Object?> _stableReceipt(Map<String, Object?> receipt) =>
    <String, Object?>{
      'requestId': receipt['requestId'],
      'actionId': receipt['actionId'],
      'actionVersion': receipt['actionVersion'],
      'status': receipt['status'],
      'beforeRevision': receipt['beforeRevision'],
      'afterRevision': receipt['afterRevision'],
      'diff': receipt['diff'],
      'affectedResources': receipt['affectedResources'],
    };

const String _staleRevision =
    'sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('cinematic library keeps direct and JSONL transactions equivalent',
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
    expect(directResult.afterUndoBytes, directResult.initialBytes);
    expect(jsonlResult.afterUndoBytes, jsonlResult.initialBytes);
    expect(directResult.staleDomainCode, 'plan.stale');
    expect(jsonlResult.staleDomainCode, 'plan.stale');
    expect(
        directResult.duplicateDomainCode, 'cinematic_library.folder_duplicate');
    expect(
        jsonlResult.duplicateDomainCode, 'cinematic_library.folder_duplicate');
  });

  test('JSONL executes every cinematic library catalog action', () async {
    final harness = await _Harness.create('all-actions');
    addTearDown(harness.dispose);

    final result = await harness.runJsonlActionSequence();

    expect(result.actionIds, _cinematicLibraryActionIds);
    expect(result.folder['parentFolderId'], 'root-b');
    expect(result.entries.map((entry) => entry['cinematicId']), ['world-b']);
  });
}

final class _Harness {
  _Harness._(
      this.root, this.readApi, this.mutations, this.snapshots, this.worker);

  static Future<_Harness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp('cin_library_$suffix');
    final manifest = ProjectManifest(
      name: 'Cinematic library transport fixture',
      version: ProjectVersion.v7,
      maps: const [],
      tilesets: const [],
      cinematics: [
        CinematicAsset(
          id: 'world-a',
          title: 'World A',
          timeline: CinematicTimeline(),
        ),
        CinematicAsset(
          id: 'world-b',
          title: 'World B',
          timeline: CinematicTimeline(),
        ),
      ],
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
    return _Harness._(
      root,
      readApi,
      mutations,
      snapshots,
      JsonlWorker(api: readApi, mutations: mutations),
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
    final initialBytes = await _bytes();
    final revision = (await snapshots.load(project)).revision;
    final dryRun = await mutations.plan(
      project,
      _request(workspace.value, revision, 'dry', dryRun: true),
    );
    expect(dryRun['nonApplicableReason'], 'dry_run');
    final dryRunBytes = await _bytes();
    final plan = await mutations.plan(
      project,
      _request(workspace.value, revision, 'apply'),
    );
    final applied = await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'operation-cinematic-library',
    );
    final replay = await mutations.apply(
      project,
      planId: plan['planId']! as String,
      operationId: 'operation-cinematic-library',
    );
    final query = await readApi.query(project, _folderQuery());
    final entry = Map<String, Object?>.from(
      ((await mutations.history(project, limit: 1))['entries']! as List).single
          as Map,
    );
    final duplicateCode = await _directDuplicate(project, workspace.value);
    final staleCode = await _directStale(project, workspace.value);
    await mutations.undo(
      project,
      entryId: entry['entryId']! as String,
      idempotencyKey: 'undo-cinematic-library',
    );
    return _FlowResult(
      initialBytes,
      dryRunBytes,
      _stablePlan(plan),
      _receipt(applied),
      _receipt(replay),
      _stableReceipt(_receipt(applied)),
      query,
      staleCode,
      duplicateCode,
      await _bytes(),
    );
  }

  Future<_FlowResult> runJsonl() async {
    final opened = await _success('open', {'projectRoot': root.path});
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    final initialBytes = await _bytes();
    final validated = await _success('validate', {'projectHandle': project});
    final revision = validated['snapshotRevision']! as String;
    final dryRun = await _success('plan', {
      'projectHandle': project,
      'request': _request(workspace, revision, 'dry', dryRun: true).toJson(),
    });
    expect(dryRun['nonApplicableReason'], 'dry_run');
    final dryRunBytes = await _bytes();
    final plan = await _success('plan', {
      'projectHandle': project,
      'request': _request(workspace, revision, 'apply').toJson(),
    });
    final args = {
      'projectHandle': project,
      'planId': plan['planId'],
      'operationId': 'operation-cinematic-library',
    };
    final applied = await _success('apply', args);
    final replay = await _success('apply', args);
    final query = await _success('query', {
      'projectHandle': project,
      'request': _folderQuery().toJson(),
    });
    final history = await _success('history', {
      'projectHandle': project,
      'limit': 1,
    });
    final entry = Map<String, Object?>.from(
      (history['entries']! as List).single as Map,
    );
    final current = await _success('validate', {'projectHandle': project});
    final duplicate = await _result('plan', {
      'projectHandle': project,
      'request': _request(
        workspace,
        current['snapshotRevision']! as String,
        'duplicate',
      ).toJson(),
    });
    final stale = await _result('plan', {
      'projectHandle': project,
      'request': _request(workspace, _staleRevision, 'stale').toJson(),
    });
    await _success('undo', {
      'projectHandle': project,
      'entryId': entry['entryId'],
      'idempotencyKey': 'undo-cinematic-library',
    });
    return _FlowResult(
      initialBytes,
      dryRunBytes,
      _stablePlan(plan),
      _receipt(applied),
      _receipt(replay),
      _stableReceipt(_receipt(applied)),
      query,
      stale.error!.details['domainCode']! as String,
      duplicate.error!.details['domainCode']! as String,
      await _bytes(),
    );
  }

  Future<_ActionSequenceResult> runJsonlActionSequence() async {
    final opened = await _success('open', {'projectRoot': root.path});
    final project = opened['projectHandle']! as String;
    final workspace = opened['workspaceHandle']! as String;
    var revision = (await _success('validate', {
      'projectHandle': project,
    }))['snapshotRevision']! as String;
    var sequence = 0;
    final actionIds = <String>{};

    Future<void> apply(
      String actionId,
      Map<String, Object?> parameters, {
      bool confirmed = false,
    }) async {
      sequence += 1;
      final plan = await _success('plan', {
        'projectHandle': project,
        'request': AuthoringRequest(
          requestId: 'all-actions-$sequence',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: workspace,
          parameters: parameters,
          expectedRevision: revision,
          idempotencyKey: 'all-actions-$sequence',
        ).toJson(),
      });
      final confirmation = confirmed
          ? await _success('confirm', {
              'projectHandle': project,
              'planId': plan['planId'],
            })
          : null;
      final applied = await _success('apply', {
        'projectHandle': project,
        'planId': plan['planId'],
        'operationId': 'all-actions-$sequence',
        if (confirmation != null)
          'confirmationToken': confirmation['confirmationToken'],
      });
      actionIds.add(
        (applied['receipt']! as Map<String, Object?>)['actionId']! as String,
      );
      revision = (await _success('validate', {
        'projectHandle': project,
      }))['snapshotRevision']! as String;
    }

    await apply('cinematicLibraryFolder.create', const {
      'folderId': 'root-a',
      'family': 'world',
      'name': 'Root A',
      'parentFolderId': null,
      'targetIndex': 0,
    });
    await apply('cinematicLibraryFolder.create', const {
      'folderId': 'root-b',
      'family': 'world',
      'name': 'Root B',
      'parentFolderId': null,
      'targetIndex': 1,
    });
    await apply('cinematicLibraryFolder.create', const {
      'folderId': 'chapter',
      'family': 'world',
      'name': 'Chapter',
      'parentFolderId': 'root-a',
      'targetIndex': 0,
    });
    await apply('cinematicLibraryFolder.rename', const {
      'folderId': 'chapter',
      'name': 'Opening',
    });
    await apply('cinematicLibraryFolder.move', const {
      'folderId': 'chapter',
      'targetParentFolderId': 'root-b',
      'targetIndex': 0,
    });
    await apply('cinematicLibraryFolder.reorder', const {
      'folderId': 'root-b',
      'targetIndex': 0,
    });
    await apply('cinematicLibraryFolder.setArchived', const {
      'folderId': 'root-a',
      'isArchived': true,
    });
    await apply('cinematicLibraryEntry.place', const {
      'family': 'world',
      'cinematicId': 'world-a',
      'targetFolderId': 'chapter',
      'targetIndex': 0,
    });
    await apply('cinematicLibraryEntry.place', const {
      'family': 'world',
      'cinematicId': 'world-b',
      'targetFolderId': 'chapter',
      'targetIndex': 1,
    });
    await apply('cinematicLibraryEntry.reorder', const {
      'family': 'world',
      'cinematicId': 'world-b',
      'targetIndex': 0,
    });
    await apply('cinematicLibraryEntry.setArchived', const {
      'family': 'world',
      'cinematicId': 'world-a',
      'isArchived': true,
    });
    await apply('cinematicLibraryAsset.create', const {
      'family': 'world',
      'cinematicId': 'world-created',
      'title': 'World created',
      'targetFolderId': 'chapter',
      'targetIndex': 2,
      'startingPoint': 'blank',
    });
    await apply('cinematicLibraryAsset.duplicate', const {
      'family': 'world',
      'cinematicId': 'world-created',
      'duplicateId': 'world-created-copy',
      'title': 'World created copy',
      'targetFolderId': 'chapter',
      'targetIndex': 3,
    });
    await apply(
      'cinematicLibraryAsset.delete',
      const {'family': 'world', 'cinematicId': 'world-created-copy'},
      confirmed: true,
    );
    await apply(
      'cinematicLibraryAsset.delete',
      const {'family': 'world', 'cinematicId': 'world-created'},
      confirmed: true,
    );
    await apply(
      'cinematicLibraryEntry.remove',
      const {'family': 'world', 'cinematicId': 'world-a'},
      confirmed: true,
    );
    await apply(
      'cinematicLibraryFolder.delete',
      const {'folderId': 'root-a'},
      confirmed: true,
    );
    final folderResponse = await _success('query', {
      'projectHandle': project,
      'request': AuthoringQueryRequest(
        resourceKind: 'cinematicLibraryFolder',
        operation: AuthoringQueryOperation.get,
        ids: const ['chapter'],
        view: AuthoringQueryView.detail,
      ).toJson(),
    });
    final entryResponse = await _success('query', {
      'projectHandle': project,
      'request': AuthoringQueryRequest(
        resourceKind: 'cinematicLibraryEntry',
        operation: AuthoringQueryOperation.list,
        filters: const {'family': 'world'},
        view: AuthoringQueryView.detail,
      ).toJson(),
    });
    return _ActionSequenceResult(
      actionIds: actionIds,
      folder: Map<String, Object?>.from(
        (folderResponse['items']! as List).single as Map,
      ),
      entries: [
        for (final entry in entryResponse['items']! as List)
          Map<String, Object?>.from(entry as Map),
      ],
    );
  }

  Future<String> _directDuplicate(
      ProjectHandle project, String workspace) async {
    try {
      await mutations.plan(
        project,
        _request(
            workspace, (await snapshots.load(project)).revision, 'duplicate'),
      );
    } on CinematicLibraryAuthoringException catch (error) {
      return error.code;
    }
    throw StateError('Duplicate folder accepted.');
  }

  Future<String> _directStale(ProjectHandle project, String workspace) async {
    try {
      await mutations.plan(
          project, _request(workspace, _staleRevision, 'stale'));
    } on AuthoringPlanException catch (error) {
      return error.code;
    }
    throw StateError('Stale request accepted.');
  }

  Future<Map<String, Object?>> _success(
    String command,
    Map<String, Object?> args,
  ) async {
    final result = await _result(command, args);
    expect(result.status, AuthoringResultStatus.success,
        reason: result.error?.toJson().toString());
    return result.data;
  }

  Future<AuthoringResult> _result(
    String command,
    Map<String, Object?> args,
  ) async {
    final line = await worker.processLine(jsonEncode({
      'id': 'request-$command',
      'command': command,
      'args': args,
    }));
    return AuthoringResult.fromJson(
      jsonDecode(line) as Map<String, dynamic>,
    );
  }

  Future<List<int>> _bytes() => File('${root.path}/project.json').readAsBytes();

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _FlowResult {
  const _FlowResult(
    this.initialBytes,
    this.dryRunBytes,
    this.stablePlan,
    this.appliedReceipt,
    this.replayReceipt,
    this.stableReceipt,
    this.query,
    this.staleDomainCode,
    this.duplicateDomainCode,
    this.afterUndoBytes,
  );

  final List<int> initialBytes;
  final List<int> dryRunBytes;
  final Map<String, Object?> stablePlan;
  final Map<String, Object?> appliedReceipt;
  final Map<String, Object?> replayReceipt;
  final Map<String, Object?> stableReceipt;
  final Map<String, Object?> query;
  final String staleDomainCode;
  final String duplicateDomainCode;
  final List<int> afterUndoBytes;
}

final class _ActionSequenceResult {
  const _ActionSequenceResult({
    required this.actionIds,
    required this.folder,
    required this.entries,
  });

  final Set<String> actionIds;
  final Map<String, Object?> folder;
  final List<Map<String, Object?>> entries;
}

const _cinematicLibraryActionIds = <String>{
  'cinematicLibraryAsset.create',
  'cinematicLibraryAsset.duplicate',
  'cinematicLibraryAsset.delete',
  'cinematicLibraryFolder.create',
  'cinematicLibraryFolder.rename',
  'cinematicLibraryFolder.move',
  'cinematicLibraryFolder.reorder',
  'cinematicLibraryFolder.setArchived',
  'cinematicLibraryFolder.delete',
  'cinematicLibraryEntry.place',
  'cinematicLibraryEntry.reorder',
  'cinematicLibraryEntry.setArchived',
  'cinematicLibraryEntry.remove',
};

AuthoringRequest _request(
  String workspace,
  String revision,
  String sequence, {
  bool dryRun = false,
}) =>
    AuthoringRequest(
      requestId: 'request-$sequence',
      actionId: 'cinematicLibraryFolder.create',
      actionVersion: 1,
      workspaceHandle: workspace,
      parameters: const {
        'folderId': 'chapters',
        'family': 'world',
        'name': 'Chapters',
        'parentFolderId': null,
        'targetIndex': 0,
      },
      expectedRevision: revision,
      idempotencyKey: 'idempotency-$sequence',
      dryRun: dryRun,
    );

AuthoringQueryRequest _folderQuery() => AuthoringQueryRequest(
      resourceKind: 'cinematicLibraryFolder',
      operation: AuthoringQueryOperation.list,
      filters: const {'family': 'world'},
      pageSize: 1,
      view: AuthoringQueryView.detail,
      fieldMask: const ['id', 'family', 'name'],
    );

Map<String, Object?> _stablePlan(Map<String, Object?> response) {
  final plan = Map<String, Object?>.from(response['plan']! as Map);
  return {
    for (final key in const [
      'actionId',
      'actionVersion',
      'baseRevision',
      'projectedRevision',
      'applicable',
      'changeSet',
      'preview',
      'referenceImpact',
      'artifacts',
    ])
      key: plan[key],
  };
}

Map<String, Object?> _receipt(Map<String, Object?> response) =>
    Map<String, Object?>.from(response['receipt']! as Map);

Map<String, Object?> _stableReceipt(Map<String, Object?> receipt) => {
      for (final key in const [
        'requestId',
        'actionId',
        'actionVersion',
        'status',
        'beforeRevision',
        'afterRevision',
        'diff',
        'affectedResources',
      ])
        key: receipt[key],
    };

const _staleRevision =
    'sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

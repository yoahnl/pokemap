import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL transaction IO preserves only safe domain diagnostics', () async {
    final f = await _Fixture.create(workerMutations: _FailedDiscard());
    addTearDown(f.dispose);
    final result = await f.request('discard_preparation',
        operationId: 'failure-operation');
    expect(result.status, AuthoringResultStatus.failure);
    expect(result.error?.details['domainCode'], 'transaction.io');
    expect(jsonEncode(result.toJson()), isNot(contains('/private/')));
    expect(result.receipt, isNull);
  });

  for (final transport in ['direct', 'jsonl']) {
    test(
        '$transport discards a blocked preparation without a snapshot or project writes',
        () async {
      final f = await _Fixture.create(faultInjector: (context) {
        if (context.checkpoint ==
            AuthoringTransactionCheckpoint.afterJournalPreparing) {
          throw const AuthoringTransactionSimulatedCrash();
        }
      });
      addTearDown(f.dispose);
      final plan = await f.api.planMutation(
          f.handle,
          AuthoringRequest(
            requestId: 'create-discard-fixture',
            actionId: 'map.create',
            actionVersion: 1,
            workspaceHandle: f.workspace.value,
            parameters: const {'mapId': 'unwritten', 'width': 2, 'height': 2},
            expectedRevision: f.loaderRevision,
            idempotencyKey: 'create-discard-fixture',
          ));
      await expectLater(
          f.api.applyMutation(f.handle,
              planId: plan.planId, operationId: 'incomplete-operation'),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      await f.project.writeAsString('${await f.project.readAsString()}\n');
      final before = await f.project.readAsBytes();
      final pending = await f.api.resourcePackPending(f.handle);
      expect(pending.single.disposition, AuthoringRecoveryDisposition.blocked);
      f.forbidSnapshotReads();
      final result = transport == 'direct'
          ? (await f.api.discardIncompletePreparation(f.handle,
                  operationId: 'incomplete-operation'))
              .toJson()
          : (await f.request('discard_preparation',
                  operationId: 'incomplete-operation'))
              .data;
      expect(result['disposition'], 'discardedIncompletePreparation');
      expect(result['intendedReceiptId'], isNotNull);
      expect(result['projectDataChanged'], isFalse);
      expect(result['receipt'], isNull);
      expect(await f.project.readAsBytes(), before);
      expect(
          await File('${f.root.path}/maps/unwritten.json').exists(), isFalse);
      expect(await f.api.resourcePackPending(f.handle), isEmpty);
      expect(
          (await f.api.discardIncompletePreparation(f.handle,
                  operationId: 'incomplete-operation'))
              .discarded,
          isFalse);
    });
  }

  test('JSONL idempotent discard preserves project and staged bytes', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.project.readAsBytes();
    final stagedBefore = await f.staged.readAsBytes();
    final artifact = await f.api.artifacts.put(stagedBefore);
    expect(f.api.describeMutationContracts().commands.map((e) => e.id),
        contains('discard_preparation'));
    for (var i = 0; i < 2; i++) {
      final result = await f.request('discard_preparation',
          operationId: 'absent-operation');
      expect(result.status, AuthoringResultStatus.success,
          reason: result.error?.toString());
      expect(result.receipt, isNull);
      expect(result.data, {
        'operationId': 'absent-operation',
        'disposition': 'alreadyAbsent',
        'committed': false,
        'recoverable': false,
        'finalized': true,
        'projectDataChanged': false,
      });
    }
    expect(await f.project.readAsBytes(), before);
    expect(await f.staged.readAsBytes(), stagedBefore);
    expect(await f.api.artifacts.read(artifact.reference.handle), stagedBefore);
    final audit = await FileAuthoringAuditLog.open(projectRoot: f.root.path);
    final records = (await audit.readAll())
        .where((r) => r.actionId == 'transaction.discard_preparation')
        .toList();
    expect(records, hasLength(2));
    expect(
        records.every((r) =>
            r.decision == AuthoringAuditDecision.succeeded &&
            r.receiptId == null),
        isTrue);
    expect(
        await f.root
            .list(recursive: true)
            .where((e) => e.path.endsWith('idempotency.jsonl'))
            .isEmpty,
        isTrue);
  });

  test('JSONL denies discard without recovery scope and preserves staged bytes',
      () async {
    final f =
        await _Fixture.create(actor: AuthoringActor(actorId: 'read-only'));
    addTearDown(f.dispose);
    final before = await f.project.readAsBytes();
    final stagedBefore = await f.staged.readAsBytes();
    final artifact = await f.api.artifacts.put(stagedBefore);
    final result =
        await f.request('discard_preparation', operationId: 'absent-operation');
    expect(result.status, AuthoringResultStatus.failure);
    expect(
        result.error?.details['domainCode'], 'authorization.permission_denied');
    expect(await f.project.readAsBytes(), before);
    expect(await f.staged.readAsBytes(), stagedBefore);
    expect(await f.api.artifacts.read(artifact.reference.handle), stagedBefore);
    final audit = await FileAuthoringAuditLog.open(projectRoot: f.root.path);
    final records = await audit.readAll();
    expect(records.last.actionId, 'transaction.discard_preparation');
    expect(records.last.decision, AuthoringAuditDecision.denied);
    expect(records.last.receiptId, isNull);
  });

  test(
      'JSONL rejects unsafe identities foreign handles and unknown discard arguments',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.project.readAsBytes();
    for (final args in [
      {'projectHandle': f.handle.value, 'operationId': '../outside'},
      {'projectHandle': 'foreign-project', 'operationId': 'absent-operation'},
      {
        'projectHandle': f.handle.value,
        'operationId': 'absent-operation',
        'force': true
      },
    ]) {
      final result = await f.rawRequest('discard_preparation', args);
      expect(result.status, AuthoringResultStatus.failure);
      expect(result.receipt, isNull);
    }
    expect(await f.project.readAsBytes(), before);
  });
}

final class _Fixture {
  _Fixture(
      this.root,
      this.project,
      this.staged,
      this.api,
      this.worker,
      this.handle,
      this.workspace,
      this.loaderRevision,
      this.forbidSnapshotReads,
      this.dispose);
  final Directory root;
  final File project;
  final File staged;
  final LocalMapAuthoringMutationApi api;
  final JsonlWorker worker;
  final ProjectHandle handle;
  final WorkspaceHandle workspace;
  final String loaderRevision;
  final void Function() forbidSnapshotReads;
  final Future<void> Function() dispose;

  static Future<_Fixture> create(
      {AuthoringActor? actor,
      AuthoringTransactionFaultInjector? faultInjector,
      AuthoringMutationApiPort? workerMutations}) async {
    final root =
        await Directory.systemTemp.createTemp('discard-preparation-api-');
    final project = File('${root.path}/project.json');
    await project.writeAsString(jsonEncode(ProjectManifest(
        name: 'Discard',
        version: ProjectVersion.v8,
        maps: const [],
        tilesets: const []).toJson()));
    final staged = File('${root.path}/staged-unrelated.bin');
    await staged.writeAsBytes([0, 4, 8, 255]);
    const reader = LocalProjectFileReader();
    final canonicalRoot = await root.resolveSymbolicLinks();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    var snapshotReadsAllowed = true;
    final registered = handles.registerProject(
        projectName: 'Discard',
        initialFingerprint: 'fixture',
        readBytes: (path) {
          if (!snapshotReadsAllowed) {
            throw StateError('Snapshot reconstruction is forbidden');
          }
          return reader.readBytes(
              projectRoot: canonicalRoot, relativePath: path);
        });
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        actor: actor,
        faultInjector: faultInjector);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: registered.workspaceHandle,
        projectHandle: registered.projectHandle);
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy, fileReader: reader, handles: handles),
            snapshotLoader: loader),
        mutations: workerMutations ?? api);
    final revision = (await loader.load(registered.projectHandle)).revision;
    return _Fixture(
        root,
        project,
        staged,
        api,
        worker,
        registered.projectHandle,
        registered.workspaceHandle,
        revision,
        () => snapshotReadsAllowed = false, () async {
      await api.detachWorkspace(registered.workspaceHandle);
      handles.closeWorkspace(registered.workspaceHandle);
      await root.delete(recursive: true);
    });
  }

  Future<AuthoringResult> request(String command,
          {required String operationId}) =>
      rawRequest(
          command, {'projectHandle': handle.value, 'operationId': operationId});

  Future<AuthoringResult> rawRequest(
          String command, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
              {'id': 'discard-test', 'command': command, 'args': args})))
          as Map<String, dynamic>);
}

final class _FailedDiscard
    implements
        AuthoringMutationApiPort,
        AuthoringIncompletePreparationDiscardPort {
  @override
  Future<AuthoringIncompletePreparationDiscardResult>
      discardIncompletePreparation(ProjectHandle handle,
          {required String operationId}) async {
    throw const TransactionFileGatewayException(
        'transaction.io', 'OS error with /private/secret/project and errno 13');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

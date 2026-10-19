import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_reproducibility.dart';
import 'support/native_writer_fixture.dart';

void main() {
  for (final count in [8, 9]) {
    test('$count composed maps retain import undo history only through eight',
        () async {
      final root = await Directory.systemTemp.createTemp('bootstrap-history-');
      addTearDown(() => root.delete(recursive: true));
      final source = await LiteralTileFixture.create(
          sourceRootPath: '${root.path}/source',
          maps: [
            for (var id = 1; id <= count; id++) LiteralFixtureMap(id: id)
          ]);
      final before = await readNativeStudyTree(source.sourceRootPath!);
      final output = await Directory('${root.path}/output').create();
      final limits = sourceCatalogStudyWriteLimitsFor(count);
      final composition = await const LiteralTileComposer().compose(
          source: source.source,
          files: source.files,
          selectedSourceMapIds: [for (var id = 1; id <= count; id++) id],
          projectName: 'Original bootstrap history qualification',
          parentPath: output.path,
          folderName: 'native-study',
          sourceRootPath: source.sourceRootPath,
          limits: limits);
      expect(composition.canWrite, isTrue);
      final draft = composition.draft!;
      expect(draft.mapIds, hasLength(count));
      expect(composition.nativeMaps, hasLength(count));
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await const NativeProjectWriter()
          .write(approval.plan, approval.context, draft, limits: limits);
      expect(receipt.verified, isTrue);
      expect(receipt.importUndoHistoryRetained, count <= 8);
      expect(receipt.mapHashes, hasLength(count));
      final files = await readNativeStudyTree(receipt.projectPath);
      final history = _lines(files['.pokemap/authoring/history.jsonl']);
      final blobs = files.keys.where((key) =>
          key.startsWith('.pokemap/authoring/blobs/') && key.endsWith('.blob'));
      if (count <= 8) {
        expect(history, hasLength(draft.mutations.length));
        expect(blobs, isNotEmpty);
      } else {
        expect(history, isEmpty);
        expect(blobs, isEmpty);
      }
      await _verifyDurability(receipt, draft);
      await _reopenEditUndo(receipt, composition, draft);
      expect(await readNativeStudyTree(source.sourceRootPath!), before);
    });
  }
}

List<Map<String, dynamic>> _lines(List<int>? bytes) => bytes == null
    ? []
    : const LineSplitter()
        .convert(utf8.decode(bytes))
        .where((line) => line.isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();

Future<void> _verifyDurability(
    NativeWriteReceipt receipt, NativeProjectDraft draft) async {
  final files = await readNativeStudyTree(receipt.projectPath);
  final completed = _lines(files['.pokemap/authoring/idempotency.jsonl'])
      .map((row) => AuthoringIdempotencyRecord.fromJson(
          Map<String, Object?>.from(row['record'] as Map)))
      .where((record) => record.status == AuthoringIdempotencyStatus.completed)
      .toList();
  expect(completed.where((record) => record.scope.actionId == 'project.create'),
      hasLength(1));
  final imported = completed
      .where((record) => record.scope.actionId != 'project.create')
      .toList();
  expect(
      imported.map((record) => record.operationId),
      unorderedEquals(
          draft.mutations.map((mutation) => mutation.operationId.value)));
  expect(
      imported.every(
          (record) => record.receipt?.status == AuthoringReceiptStatus.applied),
      isTrue);
  final audit = _lines(files['.pokemap/authoring/audit.jsonl']);
  expect(audit, hasLength(draft.mutations.length));
  for (final row in audit) {
    final record = AuthoringAuditRecord.fromJson(
        Map<String, Object?>.from(row['record'] as Map));
    expect(record.decision, AuthoringAuditDecision.succeeded);
    expect(record.receiptId, isNotNull);
  }
  final gateway =
      await LocalTransactionFileGateway.open(projectRoot: receipt.projectPath);
  final journals = await gateway.listJournals();
  expect(journals, isEmpty);
  expect(
      files.keys.where((key) =>
          key.startsWith('.pokemap/authoring/transactions/') &&
          !key.endsWith('.lock')),
      isEmpty);
}

Future<void> _reopenEditUndo(NativeWriteReceipt receipt,
    LiteralTileComposition composition, NativeProjectDraft draft) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
  final handles = WorkspaceHandleStore();
  final opener =
      ProjectOpenService(policy: policy, fileReader: reader, handles: handles);
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final opened = await opener.openProject(receipt.projectPath);
  final api =
      LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
  try {
    await api.attachProject(
        projectRootPath: receipt.projectPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final before = await snapshots.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    expect(before.loadDiagnostics, isEmpty);
    expect(before.revision, receipt.nativeRevision);
    expect(before.maps, hasLength(composition.nativeMaps.length));
    for (final map in composition.nativeMaps.values) {
      expect(before.mapById(map.id), map);
    }
    final initialHistory =
        await api.listMutationHistory(opened.projectHandle, limit: 100);
    expect(
        initialHistory.entries,
        hasLength(
            receipt.importUndoHistoryRetained ? draft.mutations.length : 0));
    if (receipt.importUndoHistoryRetained) {
      final replay = await api.recoverMutation(opened.projectHandle,
          operationId: draft.mutations.first.operationId.value);
      expect(replay.receipt.status, AuthoringReceiptStatus.applied);
      expect(replay.snapshotRevision, before.revision);
    } else {
      await expectLater(
          api.recoverMutation(opened.projectHandle,
              operationId: draft.mutations.first.operationId.value),
          throwsA(isA<AuthoringAuthorizationException>().having(
              (error) => error.code,
              'code',
              'authorization.replay_context_mismatch')));
      final refused = await snapshots.load(opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.strict);
      expect(refused.revision, before.revision);
      expect(refused.manifest.toJson(), before.manifest.toJson());
    }
    expect(
        (await api.listMutationHistory(opened.projectHandle, limit: 100))
            .entries,
        hasLength(initialHistory.entries.length));
    final map = composition.nativeMaps.values.first;
    final changed =
        map.copyWith(properties: {...map.properties, 'review': 'edited'});
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'bootstrap-review-edit',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: before.revision,
            idempotencyKey: 'bootstrap-review-edit',
            parameters: {'map': changed.toJson()}));
    expect(plan.applicable, isTrue);
    final applied = await api.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'bootstrap-review-edit');
    expect(applied.receipt.status, AuthoringReceiptStatus.applied);
    final edited = await snapshots.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    expect(edited.mapById(map.id), changed);
    final repeated = await api.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'bootstrap-review-edit');
    expect(repeated.receipt.toJson(), applied.receipt.toJson());
    expect(repeated.snapshotRevision, edited.revision);
    final history =
        await api.listMutationHistory(opened.projectHandle, limit: 100);
    expect(history.entries.first.operationId, 'bootstrap-review-edit');
    expect(history.entries, hasLength(initialHistory.entries.length + 1));
    final undone = await api.undoMutation(opened.projectHandle,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'bootstrap-review-undo');
    expect(undone.receipt.status, AuthoringReceiptStatus.applied);
    final restored = await snapshots.load(opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    expect(restored.mapById(map.id), map);
    expect(restored.revision, before.revision);
    final finalHistory =
        await api.listMutationHistory(opened.projectHandle, limit: 100);
    expect(finalHistory.entries, hasLength(initialHistory.entries.length + 2));
    expect(finalHistory.entries.first.kind, AuthoringHistoryKind.undo);
  } finally {
    await api.detachWorkspace(opened.workspaceHandle);
    opener.closeWorkspace(opened.workspaceHandle);
  }
}

import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:map_distribution/map_distribution.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show LocalResourcePackStore;
import 'package:map_authoring/src/api/authoring_result_projection.dart';
import 'package:map_authoring/src/ports/file_backed_payload_store.dart';
import 'package:test/test.dart';

import '../transactions/bulk_transaction_checkpoint_test.dart'
    show BulkTransactionFixture;

void main() {
  late Directory sandbox;
  late LocalResourcePackStore store;
  late AuthoringResultProjectionStore projections;
  late _CountingPayloadStore measured;
  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('compact-result-');
    store = LocalResourcePackStore(
        cacheDirectory: sandbox.path, allowedSourceRoots: const []);
    measured = _CountingPayloadStore(store);
    projections = AuthoringResultProjectionStore(
        store: measured,
        scope: const FileBackedPayloadScope(
            sessionId: 'session', projectId: 'project'));
  });
  tearDown(() async {
    await projections.dispose();
    await store.close();
    await sandbox.delete(recursive: true);
  });

  test('escaped pack receipt fields compact before exceeding a resources read envelope', () async {
    final fixture = BulkTransactionFixture(1);
    addTearDown(fixture.plans.dispose);
    final requestId = '"\\' * 50000;
    final receipt = _receipt(fixture.plan.changeSet.diff, requestId: requestId, actionId: 'resource_pack.import');
    final full = {'receipt': receipt.toJson(), 'snapshotRevision': fixture.plan.baseRevision};
    expect(utf8.encode(jsonEncode(full)).length, lessThan(240 * 1024));
    expect(utf8.encode(jsonEncode(jsonEncode(full))).length, greaterThan(256 * 1024));
    final projected = await projections.prepareCommittedMutation(receipt: receipt, snapshotRevision: fixture.plan.baseRevision);
    final descriptor = (projected['receipt'] as Map)['requestId'] as Map;
    final restored = BytesBuilder(copy: false);
    for (var offset = 0; offset < (descriptor['byteLength'] as int);) {
      final chunk = await projections.readPayloadChunk(payloadRef: descriptor['payloadRef'] as String, offset: offset);
      restored.add(chunk.bytes);
      offset = chunk.nextOffset;
    }
    expect(jsonDecode(utf8.decode(restored.takeBytes())), requestId);
    final envelope = {'jsonrpc': '2.0', 'id': 'x' * 128, 'result': {'contents': [
      {'uri': 'pokemap://owned', 'text': jsonEncode(projected)}]}};
    expect(utf8.encode(jsonEncode(envelope)).length, lessThanOrEqualTo(256 * 1024));
  });

  test('a committed pack at the inline boundary keeps its receipt and complete diff in bounded job envelopes', () async {
    final fixture = BulkTransactionFixture(1282);
    fixture.certify();
    final jobs = ResourcePackJobService(requireActive: () {});
    try {
      final start = await jobs.startWork(AuthoringJobRequest(requestId: 'budget', kind: 'resource_pack.import',
          projectId: fixture.scope.projectId, projectRevision: fixture.plan.baseRevision), (context) async {
        final receipt = await fixture.transaction().apply(planId: fixture.plan.planId, request: fixture.plan.request,
            currentProjectRevision: fixture.plan.baseRevision, scope: fixture.scope, operationId: fixture.operationId,
            beforeReservation: context.enterFinalization);
        return projections.prepareCommittedMutation(receipt: receipt, snapshotRevision: fixture.plan.baseRevision);
      });
      while (!(await jobs.get(start.jobId)).state.isTerminal) {
        await Future<void>.delayed(Duration.zero);
      }
      expect((await jobs.get(start.jobId)).state, AuthoringJobState.succeeded);
      expect(fixture.gateway.promotions, 1282);
      final value = jobs.result(start.jobId);
      final result = value['result'] as Map;
      final receipt = result['receipt'] as Map;
      expect(receipt['status'], 'applied');
      expect(receipt['receiptId'], fixture.plan.receiptId);
      final diff = receipt['diff'] as Map;
      expect(diff['entryCount'], fixture.plan.changeSet.diff.entries.length);
      final restored = <Object?>[];
      String? cursor;
      do {
        final page = await projections.readDiffPage(diffRef: diff['diffRef'] as String, cursor: cursor);
        restored.addAll(page['entries'] as List);
        cursor = page['nextCursor'] as String?;
      } while (cursor != null);
      expect(restored, fixture.plan.changeSet.diff.toJson()['entries']);
      for (final envelope in [
        {'requestId': 'x' * 128, 'status': 'success', 'data': value, 'artifacts': []},
        {'jsonrpc': '2.0', 'id': 'x' * 128, 'result': {'content': [{'type': 'text', 'text': 'Pack result'}], 'structuredContent': {'ok': true, 'data': value}}},
        {'jsonrpc': '2.0', 'id': 'x' * 128, 'result': {'contents': [{'uri': 'pokemap://owned', 'mimeType': 'application/json', 'text': jsonEncode(value)}]}},
      ]) {
        expect(utf8.encode(jsonEncode(envelope)).length, lessThanOrEqualTo(256 * 1024));
      }
    } finally {
      await jobs.close();
      await fixture.plans.dispose();
    }
  });

  test(
    'binary export projection verifies only bounded segments per payload chunk',
    () async {
      final bytes = List<int>.generate(3 * 128 * 1024 + 17, (i) => i % 251);
      final lease = await store.stage(
        scope: projections.scope,
        chunks: Stream.value(bytes),
        byteLength: bytes.length,
      );
      final descriptor = await projections.projectBinaryPayload(lease.payload);
      measured.verifiedBytes = 0;
      measured.sourceCalls = 0;
      measured.maxSourceBytes = 0;
      final output = BytesBuilder(copy: false);
      for (var offset = 0; offset < bytes.length;) {
        final chunk = await projections.readPayloadChunk(
          payloadRef: descriptor['payloadRef'] as String,
          offset: offset,
          byteLength: 128 * 1024,
        );
        output.add(chunk.bytes);
        offset = chunk.nextOffset;
        expect(chunk.rawSha256, lease.payload.rawSha256);
      }
      expect(output.takeBytes(), bytes);
      expect(measured.sourceCalls, 4);
      expect(measured.verifiedBytes, bytes.length);
      expect(measured.maxSourceBytes, 128 * 1024);
      expect(
        await projections.releasePayload(descriptor['payloadRef'] as String),
        true,
      );
      await expectLater(
        projections.readPayloadChunk(
          payloadRef: descriptor['payloadRef'] as String,
          offset: 0,
        ),
        throwsA(isA<AuthoringProjectionException>()),
      );
      await store.release(scope: projections.scope, leaseId: lease.leaseId);
    },
  );

  test(
      'streamed JSON matches jsonEncode UTF8 at escaping and surrogate boundaries',
      () {
    final boundary = List.filled(4095, 'a').join();
    for (final value in <Object?>[
      {'key"\\\n': 'quote" backslash\\ nul\u0000\b\f\n\r\t accenté astral😀'},
      '$boundary😀tail',
      '$boundary\ud800',
      '$boundary\udc00',
      [
        null,
        true,
        false,
        -123,
        0.5,
        {
          'nested': ['é', '界', '😀']
        }
      ],
    ]) {
      expect(projectionJsonChunks(value).expand((chunk) => chunk).toList(),
          utf8.encode(jsonEncode(value)));
    }
  });

  for (final output in ['summary', 'receipt DTO', 'plan DTO']) {
    test('fallback bounds giant client requestId in $output', () {
      final fixture = BulkTransactionFixture(1);
      addTearDown(fixture.plans.dispose);
      final requestId = 'request_${List.filled(300000, 'x').join()}';
      final receipt =
          _receipt(fixture.plan.changeSet.diff, requestId: requestId);
      final plan = _planWithRequestId(fixture.plan, requestId);
      final json = switch (output) {
        'summary' => compactAuthoringReceiptSummary(receipt),
        'receipt DTO' => AuthoringMutationResult(
                receipt: receipt,
                snapshotRevision: BulkTransactionFixture.revision)
            .toJson(),
        _ => AuthoringMutationPlanResult(
                plan: plan,
                receipt: plan.toPlannedReceipt(),
                snapshotRevision: BulkTransactionFixture.revision)
            .toJson(),
      };
      expect(
          utf8.encode(jsonEncode(json)).length, lessThanOrEqualTo(256 * 1024));
      final summary = output == 'summary' ? json : json['receipt'] as Map;
      expect(
          summary['receiptId'],
          receipt.receiptId == 'receipt' && output != 'plan DTO'
              ? 'receipt'
              : fixture.plan.receiptId);
      expect(summary['requestId'], isNot(requestId));
    });
  }

  test('fallback bounds 100 valid history summaries after final UTF8 encoding',
      () {
    final fixture = BulkTransactionFixture(1);
    addTearDown(fixture.plans.dispose);
    for (final requestLength in [3000, 1000]) {
      final page = AuthoringHistoryPage(entries: [
        for (var i = 0; i < 100; i++)
          _historyEntry(
              _receipt(fixture.plan.changeSet.diff,
                  receiptId: 'receipt_$i',
                  requestId:
                      'request_${List.filled(requestLength, 'x').join()}',
                  actionId: requestLength == 1000
                      ? 'element.${List.filled(1000, 'x').join()}'
                      : 'element.update'),
              fixture.plan.changeSet.changes.single,
              index: i)
      ]);
      final json = AuthoringMutationHistoryResult(page).toJson();
      expect(
          utf8.encode(jsonEncode(json)).length, lessThanOrEqualTo(256 * 1024));
      expect((json['entries'] as List).length, 100);
      expect((json['projectionDiagnostic'] as Map)['code'],
          'projection.unavailable');
      for (var i = 0; i < 100; i++) {
        expect(((json['entries'] as List)[i] as Map)['entryId'], 'receipt_$i');
      }
    }
  });

  test(
      'prepared large client fields retain exact JSON through payload descriptors',
      () async {
    final fixture = BulkTransactionFixture(1);
    addTearDown(fixture.plans.dispose);
    final requestId = 'request_${List.filled(100000, '界').join()}';
    final receipt = _receipt(fixture.plan.changeSet.diff, requestId: requestId);
    Future<Object?> restore(Map descriptor) async {
      final bytes = BytesBuilder(copy: false);
      for (var offset = 0; offset < (descriptor['byteLength'] as int);) {
        final chunk = await projections.readPayloadChunk(
            payloadRef: descriptor['payloadRef'] as String, offset: offset);
        bytes.add(chunk.bytes);
        offset = chunk.nextOffset;
      }
      return jsonDecode(utf8.decode(bytes.takeBytes()));
    }

    final projected = await projections.prepareCommittedMutation(
        receipt: receipt, snapshotRevision: BulkTransactionFixture.revision);
    expect(utf8.encode(jsonEncode(projected)).length,
        lessThanOrEqualTo(256 * 1024));
    expect((projected['receipt'] as Map)['status'], 'applied');
    expect(projected['projectionDiagnostic'], isNull);
    expect(await restore((projected['receipt'] as Map)['requestId'] as Map),
        requestId);
    final plan = _planWithRequestId(fixture.plan, requestId);
    final planned = await projections.preparePlan(
        plan: plan,
        receipt: plan.toPlannedReceipt(),
        snapshotRevision: BulkTransactionFixture.revision);
    expect(
        utf8.encode(jsonEncode(planned)).length, lessThanOrEqualTo(256 * 1024));
    expect(
        await restore((planned['plan'] as Map)['requestId'] as Map), requestId);
    final history = await projections.prepareHistory(AuthoringHistoryPage(
        entries: [
          _historyEntry(receipt, fixture.plan.changeSet.changes.single)
        ]));
    expect(
        utf8.encode(jsonEncode(history)).length, lessThanOrEqualTo(256 * 1024));
    final historyReceipt =
        ((history['entries'] as List).single as Map)['receipt'] as Map;
    expect(await restore(historyReceipt['requestId'] as Map), requestId);
  });

  test(
      'failed committed projection bounds client fields and keeps canonical reread identities',
      () async {
    final fixture = BulkTransactionFixture(1);
    addTearDown(fixture.plans.dispose);
    final requestId = 'request_${List.filled(300000, 'x').join()}';
    final receipt = _receipt(fixture.plan.changeSet.diff, requestId: requestId);
    await store.close();
    final json = await projections.prepareCommittedMutation(
        receipt: receipt, snapshotRevision: BulkTransactionFixture.revision);
    expect(utf8.encode(jsonEncode(json)).length, lessThanOrEqualTo(256 * 1024));
    final summary = json['receipt'] as Map;
    expect(summary['status'], 'applied');
    expect(summary['receiptId'], 'receipt');
    expect(summary['planId'], 'plan');
    expect(summary['operationId'], 'operation');
    expect((json['projectionDiagnostic'] as Map)['code'],
        'projection.unavailable');
    expect(summary['requestId'], isNot(requestId));
  });

  test('compact pages reconstruct an ordered full diff without loss', () async {
    final fixture = BulkTransactionFixture(1000);
    addTearDown(fixture.plans.dispose);
    final receipt = fixture.plan.toPlannedReceipt();
    final projected = await projections.preparePlan(
        plan: fixture.plan,
        receipt: receipt,
        snapshotRevision: fixture.plan.baseRevision);
    expect(utf8.encode(jsonEncode(projected)).length,
        lessThanOrEqualTo(256 * 1024));
    await fixture.plan.releaseAppliedPayload();
    final summary = (projected['receipt'] as Map)['diff'] as Map;
    final rows = <Object?>[];
    String? cursor;
    do {
      final page = await projections.readDiffPage(
          diffRef: summary['diffRef'] as String, cursor: cursor, limit: 200);
      expect(
          utf8.encode(jsonEncode(page)).length, lessThanOrEqualTo(256 * 1024));
      expect((page['entries'] as List).length, lessThanOrEqualTo(200));
      rows.addAll(page['entries'] as List);
      cursor = page['nextCursor'] as String?;
    } while (cursor != null);
    expect(rows, receipt.diff.toJson()['entries']);
    expect(summary['fullDiffFingerprint'],
        bulkDiffFingerprintForTest(receipt.diff));
    expect(receipt.diff.entries.length, 1000);
  });

  test('32 MiB catalogue values become owned descriptors and bounded chunks',
      () async {
    final value = {
      'catalogue': List.filled(16 * 1024, List.filled(1024, 'é').join()).join()
    };
    final receipt = _receipt(AuthoringDiff([
      AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: AuthoringResourceRef(kind: 'catalogue', id: 'large'),
          path: r'$',
          before: value,
          after: {'catalogue': 'new'})
    ]));
    final projected = await projections.prepareMutation(
        receipt: receipt, snapshotRevision: BulkTransactionFixture.revision);
    final summary = (projected['receipt'] as Map)['diff'] as Map;
    final page = await projections.readDiffPage(
        diffRef: summary['diffRef'] as String, limit: 200);
    final row = (page['entries'] as List).single as Map;
    final descriptor = row['before'] as Map;
    expect(
        descriptor.keys,
        containsAll(
            ['payloadRef', 'rawSha256', 'resourceRevision', 'byteLength']));
    measured.verifiedBytes = 0;
    measured.sourceCalls = 0;
    measured.maxSourceBytes = 0;
    final builder = BytesBuilder(copy: false);
    for (var offset = 0; offset < (descriptor['byteLength'] as int);) {
      final chunk = await projections.readPayloadChunk(
          payloadRef: descriptor['payloadRef'] as String,
          offset: offset,
          byteLength: 128 * 1024);
      expect(chunk.bytes.length, lessThanOrEqualTo(128 * 1024));
      builder.add(chunk.bytes);
      offset = chunk.nextOffset;
    }
    expect(measured.verifiedBytes,
        lessThanOrEqualTo((descriptor['byteLength'] as int) + 128 * 1024));
    expect(measured.maxSourceBytes, lessThanOrEqualTo(128 * 1024));
    final beforeCalls = measured.sourceCalls;
    await projections.readPayloadChunk(
        payloadRef: descriptor['payloadRef'] as String,
        offset: 128 * 1024 - 2,
        byteLength: 128 * 1024);
    expect(measured.sourceCalls - beforeCalls, 2);
    final bytes = builder.takeBytes();
    expect(sha256.convert(bytes).toString(), descriptor['rawSha256']);
    expect(jsonDecode(utf8.decode(bytes)), value);
    expect(utf8.encode(jsonEncode(page)).length, lessThanOrEqualTo(256 * 1024));
    await expectLater(
        projections.readPayloadChunk(
            payloadRef: descriptor['payloadRef'] as String,
            offset: 0,
            byteLength: 128 * 1024 + 1),
        throwsArgumentError);
    final foreign = AuthoringResultProjectionStore(
        store: store,
        scope: const FileBackedPayloadScope(
            sessionId: 'other', projectId: 'project'));
    await expectLater(
        foreign.readPayloadChunk(
            payloadRef: descriptor['payloadRef'] as String,
            offset: 0,
            byteLength: 1),
        throwsA(isA<AuthoringProjectionException>()));
    await foreign.dispose();
  });

  test('one oversize row yields a payload reference and advances cursor',
      () async {
    final receipt = _receipt(AuthoringDiff([
      AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: AuthoringResourceRef(kind: 'element', id: 'oversize'),
          path: List.filled(300000, '界').join(),
          after: 1)
    ]));
    final projected = await projections.prepareMutation(
        receipt: receipt, snapshotRevision: BulkTransactionFixture.revision);
    final summary = (projected['receipt'] as Map)['diff'] as Map;
    final page = await projections.readDiffPage(
        diffRef: summary['diffRef'] as String, limit: 1);
    expect((page['entries'] as List).single, contains('payloadRef'));
    expect(page['nextCursor'], isNull);
    expect(utf8.encode(jsonEncode(page)).length, lessThanOrEqualTo(256 * 1024));
  });

  test('raw history result never emits a giant one-entry bulk page', () async {
    final fixture = BulkTransactionFixture(1000);
    addTearDown(fixture.plans.dispose);
    final planned = fixture.plan.toPlannedReceipt();
    final receipt = _receipt(planned.diff);
    final entry = AuthoringHistoryEntry(
        entryId: receipt.receiptId,
        projectId: 'project',
        actorId: 'actor',
        planId: 'plan',
        operationId: 'operation',
        kind: AuthoringHistoryKind.mutation,
        receipt: receipt,
        committedAt: BulkTransactionFixture.now,
        changes: [
          for (final change in fixture.plan.changeSet.changes)
            AuthoringHistoryResourceChange(
                resource: change.resource,
                storageKey: change.storageKey,
                beforeRevision: null,
                afterRevision: change.afterRevision,
                beforeBlobId: null,
                afterBlobId: change.afterRevision)
        ]);
    final result =
        AuthoringMutationHistoryResult(AuthoringHistoryPage(entries: [entry]));
    expect(utf8.encode(jsonEncode(result.toJson())).length,
        lessThanOrEqualTo(256 * 1024));
    final prepared = await projections.prepareHistory(result.page);
    final bounded =
        AuthoringMutationHistoryResult(result.page, publicProjection: prepared)
            .toJson();
    expect(
        utf8.encode(jsonEncode(bounded)).length, lessThanOrEqualTo(256 * 1024));
    final summary = (((bounded['entries'] as List).single as Map)['receipt']
        as Map)['diff'] as Map;
    expect(summary['entryCount'], 1000);
    expect(summary['diffRef'], isA<String>());
  });

  test('composite rollback and dispose release every owned segment', () async {
    final value = List.filled(256, List.filled(1024, 'a').join()).join();
    final receipt = _receipt(AuthoringDiff([
      AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: AuthoringResourceRef(kind: 'element', id: 'rollback'),
          path: r'$',
          after: value)
    ]));
    measured.failStageAt = 2;
    await expectLater(
        projections.prepareMutation(
            receipt: receipt,
            snapshotRevision: BulkTransactionFixture.revision),
        throwsStateError);
    expect(measured.activeLeases, isEmpty);
    measured.failStageAt = null;
    final projected = await projections.prepareMutation(
        receipt: receipt, snapshotRevision: BulkTransactionFixture.revision);
    final summary = (projected['receipt'] as Map)['diff'] as Map;
    final page =
        await projections.readDiffPage(diffRef: summary['diffRef'] as String);
    final descriptor =
        ((page['entries'] as List).single as Map)['after'] as Map;
    await expectLater(
        projections.readPayloadChunk(
            payloadRef: 'invalid', offset: 0, byteLength: 1),
        throwsA(isA<AuthoringProjectionException>()));
    for (final otherScope in const [
      FileBackedPayloadScope(sessionId: 'other', projectId: 'project'),
      FileBackedPayloadScope(sessionId: 'session', projectId: 'other')
    ]) {
      final foreign =
          AuthoringResultProjectionStore(store: measured, scope: otherScope);
      await expectLater(
          foreign.readDiffPage(diffRef: summary['diffRef'] as String),
          throwsA(isA<AuthoringProjectionException>()));
      await expectLater(
          foreign.readPayloadChunk(
              payloadRef: descriptor['payloadRef'] as String,
              offset: 0,
              byteLength: 1),
          throwsA(isA<AuthoringProjectionException>()));
      await foreign.dispose();
    }
    measured.failSource = true;
    await expectLater(
        projections.readPayloadChunk(
            payloadRef: descriptor['payloadRef'] as String,
            offset: 128 * 1024 - 1,
            byteLength: 2),
        throwsStateError);
    measured.failSource = false;
    await projections.dispose();
    expect(measured.activeLeases, isEmpty);
    await expectLater(
        projections.readDiffPage(diffRef: summary['diffRef'] as String),
        throwsA(isA<AuthoringProjectionException>()));
  });

  test(
      'failed committed projection has a bounded applied receipt and separate diagnostic',
      () async {
    final fixture = BulkTransactionFixture(3000);
    addTearDown(fixture.plans.dispose);
    final receipt = _receipt(fixture.plan.changeSet.diff);
    await store.close();
    final projected = await projections.prepareCommittedMutation(
        receipt: receipt, snapshotRevision: BulkTransactionFixture.revision);
    expect((projected['receipt'] as Map)['status'], 'applied');
    expect((projected['receipt'] as Map)['receiptId'], receipt.receiptId);
    expect(projected['snapshotRevision'], BulkTransactionFixture.revision);
    expect((projected['projectionDiagnostic'] as Map)['code'],
        'projection.unavailable');
    expect(projected['diagnostic'], isNull);
    expect(utf8.encode(jsonEncode(projected)).length,
        lessThanOrEqualTo(256 * 1024));
  });
}

AuthoringReceipt _receipt(AuthoringDiff diff,
        {String receiptId = 'receipt',
        String requestId = 'request',
        String actionId = 'resource_pack.import'}) =>
    AuthoringReceipt(
        receiptId: receiptId,
        requestId: requestId,
        actionId: actionId,
        actionVersion: 1,
        status: AuthoringReceiptStatus.applied,
        beforeRevision: BulkTransactionFixture.revision,
        afterRevision: BulkTransactionFixture.revision,
        createdAtUtc: BulkTransactionFixture.now.toIso8601String(),
        diff: diff,
        extensions: const {'planId': 'plan', 'operationId': 'operation'});

AuthoringPlan _planWithRequestId(AuthoringPlan plan, String requestId) =>
    AuthoringPlan(
        planId: plan.planId,
        receiptId: plan.receiptId,
        request: AuthoringRequest(
            requestId: requestId,
            actionId: plan.request.actionId,
            actionVersion: plan.request.actionVersion,
            workspaceHandle: plan.request.workspaceHandle,
            expectedRevision: plan.request.expectedRevision,
            idempotencyKey: plan.request.idempotencyKey),
        baseRevision: plan.baseRevision,
        seed: plan.seed,
        createdAt: plan.createdAt,
        expiresAt: plan.expiresAt,
        changeSet: plan.changeSet);

AuthoringHistoryEntry _historyEntry(
        AuthoringReceipt receipt, AuthoringResourceChange change,
        {int index = 0}) =>
    AuthoringHistoryEntry(
        entryId: receipt.receiptId,
        projectId: 'project',
        actorId: 'actor',
        planId: 'plan_$index',
        operationId: 'operation_$index',
        kind: AuthoringHistoryKind.mutation,
        receipt: receipt,
        committedAt: BulkTransactionFixture.now,
        changes: [
          AuthoringHistoryResourceChange(
              resource: change.resource,
              storageKey: change.storageKey,
              beforeRevision: change.beforeRevision,
              afterRevision: change.afterRevision,
              beforeBlobId: change.beforeRevision,
              afterBlobId: change.afterRevision)
        ]);

String bulkDiffFingerprintForTest(AuthoringDiff diff) =>
    computeAuthoringJsonFingerprint(diff.toJson(),
        logicalName: 'authoring-confirmation-diff.json');

final class _CountingPayloadStore implements FileBackedPayloadStore {
  _CountingPayloadStore(this.delegate);
  final FileBackedPayloadStore delegate;
  int verifiedBytes = 0;
  int maxSourceBytes = 0;
  int sourceCalls = 0;
  int stageCalls = 0;
  int? failStageAt;
  bool failSource = false;
  final activeLeases = <String>{};
  @override
  Future<FileBackedPayloadLease> stage(
      {required FileBackedPayloadScope scope,
      required Stream<List<int>> chunks,
      required int byteLength,
      String? expectedRawSha256,
      void Function()? checkCancelled}) async {
    stageCalls++;
    if (stageCalls == failStageAt) throw StateError('Injected stage failure.');
    final lease = await delegate.stage(
        scope: scope,
        chunks: chunks,
        byteLength: byteLength,
        expectedRawSha256: expectedRawSha256,
        checkCancelled: checkCancelled);
    activeLeases.add(lease.leaseId);
    return lease;
  }

  @override
  Future<FileBackedPayloadLease> retain(
          {required FileBackedPayloadScope scope,
          required String handle,
          FileBackedPayloadPurpose purpose = FileBackedPayloadPurpose.owner}) =>
      delegate.retain(scope: scope, handle: handle, purpose: purpose);
  @override
  Future<bool> release(
      {required FileBackedPayloadScope scope, required String leaseId}) async {
    final released = await delegate.release(scope: scope, leaseId: leaseId);
    activeLeases.remove(leaseId);
    return released;
  }

  @override
  Future<T> withSource<T>(
          {required FileBackedPayloadScope scope,
          required String handle,
          required FutureOr<T> Function(RandomAccessPackageSource source)
              read}) =>
      delegate.withSource(
          scope: scope,
          handle: handle,
          read: (source) {
            if (failSource) throw StateError('Injected segment failure.');
            verifiedBytes += source.length;
            maxSourceBytes = max(maxSourceBytes, source.length);
            sourceCalls++;
            return read(source);
          });
  @override
  Future<void> collectExpired() => delegate.collectExpired();
}

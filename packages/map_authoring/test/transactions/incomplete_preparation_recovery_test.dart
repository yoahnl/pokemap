import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('failed staging before reservation', () {
    test('removes its unreserved intent without changing resources', () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final gateway = _StagingFailureGateway(harness.gateway);

      await expectLater(
          _apply(harness, gateway), throwsA(same(gateway.failure)));

      expect(await harness.readJournal(), isNull);
      expect(await harness.ledger.recordForRecovery(harness.scope), isNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
      expect(await harness.readCreated(), isNull);
      expect(await harness.readDeleted(), TransactionTestHarness.beforeDeleted);
      expect(gateway.promotions, 0);
    });

    test('preserves the original exception when cleanup also fails', () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final gateway = _StagingFailureGateway(harness.gateway)
        ..failCleanup = true;

      await expectLater(
          _apply(harness, gateway), throwsA(same(gateway.failure)));

      expect(gateway.deleteAttempts, 1);
      expect(await harness.readJournal(), isNotNull);
      expect(await harness.ledger.recordForRecovery(harness.scope), isNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(gateway.promotions, 0);
    });

    test('cleans its staged after payload before any reservation', () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final gateway = _StagingFailureGateway(harness.gateway)
        ..failStorageKey = 'data/b.json';

      await expectLater(
          _apply(harness, gateway), throwsA(same(gateway.failure)));

      expect(await harness.readJournal(), isNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
      expect(gateway.promotions, 0);
    });

    test('keeps an intent if a durable reservation appeared', () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final reserved = StateError('Injected reservation');
      final gateway = _StagingFailureGateway(harness.gateway)
        ..beforeFailure = () async {
          await expectLater(
            harness.ledger.execute(
              scope: harness.scope,
              request: harness.plan.request,
              operationId: harness.operationId,
              apply: () => throw reserved,
            ),
            throwsA(same(reserved)),
          );
        };

      await expectLater(
          _apply(harness, gateway), throwsA(same(gateway.failure)));

      expect(await harness.readJournal(), isNotNull);
      expect(await harness.ledger.recordForRecovery(harness.scope), isNotNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(gateway.deleteAttempts, 0);
    });

    test('keeps the intent if an external writer changed a target', () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final external = [9, 8, 7];
      final gateway = _StagingFailureGateway(harness.gateway)
        ..beforeFailure = () => harness.writeExternalA(external);

      await expectLater(
          _apply(harness, gateway), throwsA(same(gateway.failure)));

      expect(await harness.readJournal(), isNotNull);
      expect(await harness.readA(), external);
      expect(gateway.deleteAttempts, 0);
      expect(gateway.promotions, 0);
    });
  });

  group('discard incomplete preparation', () {
    test('preserves later resource bytes and returns a typed no-write result',
        () async {
      final harness = await _incomplete();
      addTearDown(harness.dispose);
      final external = utf8.encode('{ "external": 99 }\n');
      await harness.writeExternalA(external);
      final service = await harness.reopenRecovery();
      final sibling = File(
          '${harness.projectDirectory.path}/.pokemap/authoring/transactions/another-operation/keep.bin');
      await sibling.parent.create();
      await sibling.writeAsBytes([1, 3, 5]);

      final operation = _discard(service, harness);
      await expectLater(operation, completes);
      final result = await operation;

      expect(result, isNot(isA<AuthoringReceipt>()));
      expect(result.discarded, isTrue);
      expect(result.intendedReceiptId, harness.plan.receiptId);
      expect(result.scope!.storageKey, harness.scope.storageKey);
      expect(result.unchangedRevisions!.entries, hasLength(4));
      expect(result.toJson()['projectDataChanged'], isFalse);
      expect(result.toJson()['committed'], isFalse);
      expect(await harness.readA(), external);
      expect(await harness.readB(), TransactionTestHarness.beforeB);
      expect(await harness.readCreated(), isNull);
      expect(await harness.readDeleted(), TransactionTestHarness.beforeDeleted);
      expect(await harness.readJournal(), isNull);
      expect(await harness.ledger.recordForRecovery(harness.scope), isNull);
      expect(await sibling.readAsBytes(), [1, 3, 5]);
      final replay = await _discard(service, harness);
      expect(replay.discarded, isFalse);
      expect(replay.toJson()['disposition'], 'alreadyAbsent');
      expect(replay.unchangedRevisions, isNull);
      expect(await harness.readA(), external);
    });

    for (final field in ['actor', 'project']) {
      test('refuses an unexpected $field scope', () async {
        final harness = await _incomplete();
        addTearDown(harness.dispose);
        final service = await harness.reopenRecovery();
        await expectLater(
          _discard(service, harness,
              actor: field == 'actor' ? 'another-actor' : null,
              project: field == 'project' ? 'another-project' : null),
          _recoveryError('recovery.scope_mismatch'),
        );
        expect(await harness.readJournal(), isNotNull);
        expect(await harness.readA(), TransactionTestHarness.beforeA);
      });
    }

    for (final artifact in [
      'complete',
      'descriptor',
      'payload',
      'payloadTemporary',
      'descriptorTemporary',
      'symlink',
    ]) {
      test('refuses an after $artifact artifact', () async {
        final harness = await _incomplete();
        addTearDown(harness.dispose);
        if (artifact == 'complete') {
          await harness.gateway.stagePayload(
            operationId: harness.operationId,
            storageKey: 'data/a.json',
            kind: TransactionPayloadKind.after,
            bytes: TransactionTestHarness.afterA,
          );
        } else {
          final token = computeAuthoringJsonFingerprint('data/a.json',
                  logicalName: 'transaction-storage-key.json')
              .substring('sha256:'.length);
          final suffix = switch (artifact) {
            'descriptor' => 'after.json',
            'payload' || 'symlink' => 'after.bin',
            'payloadTemporary' => 'after.bin.after.payload.tmp',
            'descriptorTemporary' => 'after.json.after.descriptor.tmp',
            _ => throw StateError(artifact),
          };
          final path = '${_directory(harness)}/$token.$suffix';
          if (artifact == 'symlink') {
            await Link(path).create('${harness.projectDirectory.path}/missing');
          } else {
            await File(path).writeAsString('partial');
          }
        }
        final service = await harness.reopenRecovery();
        await expectLater(_discard(service, harness),
            _recoveryError('recovery.incomplete_preparation_required'));
        expect(await harness.readJournal(), isNotNull);
        expect(await harness.readA(), TransactionTestHarness.beforeA);
      });
    }

    for (final status in [
      AuthoringTransactionStatus.staged,
      AuthoringTransactionStatus.prepared,
      AuthoringTransactionStatus.promoting,
    ]) {
      test('refuses status ${status.name} even without after artifacts',
          () async {
        final harness = await _incomplete();
        addTearDown(harness.dispose);
        final journal = (await harness.readJournal())!;
        await harness.gateway.writeJournal(journal.copyWith(status: status));
        final service = await harness.reopenRecovery();
        await expectLater(_discard(service, harness),
            _recoveryError('recovery.incomplete_preparation_required'));
        expect((await harness.readJournal())!.status, status);
      });
    }

    for (final flag in ['promoted', 'compensated']) {
      test('refuses a $flag entry in a preparing journal', () async {
        final harness = await _incomplete();
        addTearDown(harness.dispose);
        final journal = (await harness.readJournal())!;
        await harness.gateway.writeJournal(journal.copyWith(entries: [
          journal.entries.first.copyWith(
            promoted: flag == 'promoted',
            compensated: flag == 'compensated',
          ),
          ...journal.entries.skip(1),
        ]));
        final service = await harness.reopenRecovery();
        await expectLater(_discard(service, harness),
            _recoveryError('recovery.incomplete_preparation_required'));
        expect(await harness.readJournal(), isNotNull);
      });
    }

    test('refuses a pending reservation', () async {
      final harness = await _incomplete();
      addTearDown(harness.dispose);
      final marker = StateError('Reserved');
      await expectLater(
          harness.ledger.execute(
            scope: harness.scope,
            request: harness.plan.request,
            operationId: harness.operationId,
            apply: () => throw marker,
          ),
          throwsA(same(marker)));
      final service = await harness.reopenRecovery();
      await expectLater(_discard(service, harness),
          _recoveryError('recovery.incomplete_preparation_required'));
      expect(await harness.readJournal(), isNotNull);
    });

    test('refuses a gateway without an artifact probe', () async {
      final harness = await _incomplete();
      addTearDown(harness.dispose);
      final service = AuthoringRecoveryService(
        gateway: _StagingFailureGateway(harness.gateway),
        idempotency: harness.ledger,
        clock: () => harness.now,
      );
      await expectLater(_discard(service, harness),
          _recoveryError('recovery.artifact_probe_unavailable'));
      expect(await harness.readJournal(), isNotNull);
    });

    for (final name in ['unknown.after.bin', 'unknown.before.bin', 'foreign']) {
      test('refuses an unbound preparation artifact $name', () async {
        final harness = await _incomplete();
        addTearDown(harness.dispose);
        await File('${_directory(harness)}/$name').writeAsString('unbound');
        final service = await harness.reopenRecovery();
        final refusal = name.contains('.after.')
            ? _recoveryError('recovery.incomplete_preparation_required')
            : throwsA(isA<TransactionFileGatewayException>().having(
                (error) => error.code, 'code', 'transaction.artifact_invalid'));
        await expectLater(_discard(service, harness), refusal);
        expect(await harness.readJournal(), isNotNull);
      });
    }

    test('refuses a committed transaction and preserves its ledger', () async {
      final harness = await TransactionTestHarness.create(
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterJournalCommitted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(harness.dispose);
      await expectLater(
          harness.apply, throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      final service = await harness.reopenRecovery();
      await expectLater(_discard(service, harness),
          _recoveryError('recovery.incomplete_preparation_required'));
      expect((await harness.readJournal())!.status,
          AuthoringTransactionStatus.committed);
      expect(await harness.readA(), TransactionTestHarness.afterA);
      expect(await harness.ledger.recordForRecovery(harness.scope), isNotNull);
    });

    test('checks mutation authorization again before deleting staging',
        () async {
      final harness = await _incomplete();
      addTearDown(harness.dispose);
      var calls = 0;
      final denied = StateError('Authorization revoked');
      final service = await harness.reopenRecovery(mutationGuard: () {
        if (++calls == 2) throw denied;
      });
      await expectLater(_discard(service, harness), throwsA(same(denied)));
      expect(await harness.readJournal(), isNotNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
    });

    test('authorization refusal leaves even an absent operation untouched',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final denied = StateError('Access denied');
      final service =
          await harness.reopenRecovery(mutationGuard: () => throw denied);
      await expectLater(_discard(service, harness), throwsA(same(denied)));
      expect(await harness.readJournal(), isNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
    });

    test('serializes concurrent discards of the same preparation', () async {
      final harness = await _incomplete();
      addTearDown(harness.dispose);
      final service = await harness.reopenRecovery();
      final results = await Future.wait([
        _discard(service, harness),
        _discard(service, harness),
      ]);
      expect(results.map((result) => result.discarded), [true, false]);
      expect(await harness.readJournal(), isNull);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
    });

    test('refuses an external change during the guarded discard', () async {
      final harness = await _incomplete();
      addTearDown(harness.dispose);
      var calls = 0;
      final external = utf8.encode('{"external":"concurrent"}');
      final service = await harness.reopenRecovery(mutationGuard: () {
        if (++calls == 2) {
          File('${harness.projectDirectory.path}/data/a.json')
              .writeAsBytesSync(external);
        }
      });
      await expectLater(_discard(service, harness),
          _recoveryError('recovery.revision_conflict'));
      expect(await harness.readJournal(), isNotNull);
      expect(await harness.readA(), external);
    });

    test('refuses a corrupt journal', () async {
      final harness = await _incomplete();
      addTearDown(harness.dispose);
      final file = File('${_directory(harness)}/journal.json');
      final bytes = utf8.encode('{"unknownSchema":true}');
      await file.writeAsBytes(bytes);
      final service = await harness.reopenRecovery();
      await expectLater(
          _discard(service, harness),
          throwsA(isA<TransactionFileGatewayException>().having(
              (error) => error.code, 'code', 'transaction.journal_corrupt')));
      expect(await file.readAsBytes(), bytes);
      expect(await harness.readA(), TransactionTestHarness.beforeA);
    });
  });
}

Future<TransactionTestHarness> _incomplete() async {
  final harness = await TransactionTestHarness.create(
    faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterJournalPreparing) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );
  await expectLater(
      harness.apply, throwsA(isA<AuthoringTransactionSimulatedCrash>()));
  return harness;
}

Future<AuthoringIncompletePreparationDiscardResult> _discard(
  AuthoringRecoveryService service,
  TransactionTestHarness harness, {
  String? actor,
  String? project,
}) async =>
    service.discardIncompletePreparation(
      harness.operationId,
      expectedActorId: actor ?? harness.scope.actorId,
      expectedProjectId: project ?? harness.scope.projectId,
    );

String _directory(TransactionTestHarness harness) =>
    '${harness.projectDirectory.path}/.pokemap/authoring/transactions/${harness.operationId}';

Matcher _recoveryError(String code) => throwsA(isA<AuthoringRecoveryException>()
    .having((error) => error.code, 'code', code));

Future<AuthoringReceipt> _apply(
  TransactionTestHarness harness,
  TransactionFileGateway gateway,
) =>
    JournaledAuthoringTransaction(
      plans: harness.planStore,
      gateway: gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
    ).apply(
      planId: harness.plan.planId,
      request: harness.plan.request,
      currentProjectRevision: harness.currentProjectRevision,
      scope: harness.scope,
      operationId: harness.operationId,
    );

final class _StagingFailureGateway
    implements TransactionFileGateway, StreamingTransactionFileGateway {
  _StagingFailureGateway(this.delegate);

  final LocalTransactionFileGateway delegate;
  final failure = const FileSystemException('Injected staging failure');
  bool failCleanup = false;
  String? failStorageKey;
  FutureOr<void> Function()? beforeFailure;
  int deleteAttempts = 0;
  int promotions = 0;

  @override
  Future<void> stageAuthoringPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required AuthoringPayload? payload,
  }) async {
    if (kind == TransactionPayloadKind.after &&
        (failStorageKey == null || failStorageKey == storageKey)) {
      await beforeFailure?.call();
      throw failure;
    }
    await delegate.stageAuthoringPayload(
      operationId: operationId,
      storageKey: storageKey,
      kind: kind,
      payload: payload,
    );
  }

  @override
  Future<AuthoringPayload?> captureResourcePayload(String storageKey) =>
      delegate.captureResourcePayload(storageKey);

  @override
  Future<void> deleteTransaction(String operationId) async {
    deleteAttempts++;
    if (failCleanup) throw StateError('Injected cleanup failure');
    await delegate.deleteTransaction(operationId);
  }

  @override
  Future<List<AuthoringTransactionJournal>> listJournals() =>
      delegate.listJournals();

  @override
  Future<void> promoteStaged({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedCurrentRevision,
  }) {
    promotions++;
    return delegate.promoteStaged(
      operationId: operationId,
      storageKey: storageKey,
      kind: kind,
      expectedCurrentRevision: expectedCurrentRevision,
    );
  }

  @override
  Future<AuthoringTransactionJournal?> readJournal(String operationId) =>
      delegate.readJournal(operationId);

  @override
  Future<List<int>?> readResource(String storageKey) =>
      delegate.readResource(storageKey);

  @override
  Future<String?> readResourceRevision(String storageKey) =>
      delegate.readResourceRevision(storageKey);

  @override
  Future<TransactionStagedPayload> readStagedPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
  }) =>
      delegate.readStagedPayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
      );

  @override
  Future<void> stagePayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required List<int>? bytes,
  }) =>
      stageAuthoringPayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
        payload: bytes == null
            ? null
            : AuthoringPayload.inline(bytes, storageKey: storageKey),
      );

  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) =>
      delegate.withExclusiveWriteLock(operation);

  @override
  Future<void> writeJournal(AuthoringTransactionJournal journal) =>
      delegate.writeJournal(journal);
}

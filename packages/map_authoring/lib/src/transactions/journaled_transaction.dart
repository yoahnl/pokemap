import 'dart:async';

import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../history/authoring_history.dart';
import '../ports/idempotency_store.dart';
import '../ports/transaction_file_gateway.dart';
import '../support/authoring_fingerprint.dart';
import 'authoring_plan.dart';
import 'idempotency_ledger.dart';
import 'plan_store.dart';
import 'revision_set.dart';
import 'transaction_journal.dart';

enum AuthoringTransactionCheckpoint {
  afterJournalPreparing,
  afterPayloadsStaged,
  afterJournalStaged,
  afterReservation,
  afterJournalPrepared,
  beforeResourcePromotion,
  afterResourcePromoted,
  afterResourceJournaled,
  afterJournalCommitted,
}

final class AuthoringTransactionCheckpointContext {
  const AuthoringTransactionCheckpointContext({
    required this.checkpoint,
    required this.operationId,
    this.storageKey,
    this.promotionIndex,
  });

  final AuthoringTransactionCheckpoint checkpoint;
  final String operationId;
  final String? storageKey;
  final int? promotionIndex;
}

typedef AuthoringTransactionFaultInjector = FutureOr<void> Function(
  AuthoringTransactionCheckpointContext context,
);
typedef AuthoringTransactionPrecondition = FutureOr<void> Function();

final class AuthoringTransactionSimulatedCrash implements Exception {
  const AuthoringTransactionSimulatedCrash();
}

final class JournaledAuthoringTransactionException implements Exception {
  const JournaledAuthoringTransactionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'JournaledAuthoringTransactionException($code): $message';
}

/// Applies a plan through a durable, recoverable multi-file state machine.
final class JournaledAuthoringTransaction {
  const JournaledAuthoringTransaction({
    required AuthoringPlanStore plans,
    required TransactionFileGateway gateway,
    required AuthoringIdempotencyLedger idempotency,
    required DateTime Function() clock,
    AuthoringTransactionFaultInjector? faultInjector,
    AuthoringTransactionCommitHook? commitHook,
  })  : _plans = plans,
        _gateway = gateway,
        _idempotency = idempotency,
        _clock = clock,
        _faultInjector = faultInjector,
        _commitHook = commitHook;

  final AuthoringPlanStore _plans;
  final TransactionFileGateway _gateway;
  final AuthoringIdempotencyLedger _idempotency;
  final DateTime Function() _clock;
  final AuthoringTransactionFaultInjector? _faultInjector;
  final AuthoringTransactionCommitHook? _commitHook;

  Future<AuthoringReceipt> apply({
    required String planId,
    required AuthoringRequest request,
    required String currentProjectRevision,
    required AuthoringIdempotencyScope scope,
    required String operationId,
    AuthoringTransactionPrecondition? precondition,
  }) {
    return _gateway.withExclusiveWriteLock(() async {
      final replay = await _idempotency.inspect(
        scope: scope,
        request: request,
      );
      if (replay != null) return replay;
      await precondition?.call();

      final plan = _plans.resolve(
        planId,
        currentProjectRevision: currentProjectRevision,
      );
      _requireRequestMatchesPlan(request, plan);
      final expected = AuthoringRevisionSet.beforeChangeSet(plan.changeSet);
      final current = await _currentRevisions(plan);
      expected.requireMatches(current);

      final existingJournal = await _gateway.readJournal(operationId);
      if (existingJournal != null) {
        final safelyRestartable = existingJournal.planId == plan.planId &&
            existingJournal.scope.storageKey == scope.storageKey &&
            (existingJournal.status == AuthoringTransactionStatus.preparing ||
                existingJournal.status == AuthoringTransactionStatus.staged);
        if (!safelyRestartable) {
          throw const JournaledAuthoringTransactionException(
            'transaction.operation_conflict',
            'This operation identity already owns another durable intent.',
          );
        }
        await _gateway.deleteTransaction(operationId);
      }

      final now = _clock().toUtc();
      final historyContext = AuthoringHistoryContext.fromExtensions(
        request.extensions,
      );
      final afterRevisions =
          AuthoringRevisionSet.afterChangeSet(plan.changeSet);
      final intendedReceipt = AuthoringReceipt(
        receiptId: plan.receiptId,
        requestId: request.requestId,
        actionId: request.actionId,
        actionVersion: request.actionVersion,
        status: AuthoringReceiptStatus.applied,
        beforeRevision: expected.fingerprint,
        afterRevision: afterRevisions.fingerprint,
        createdAtUtc: now.toIso8601String(),
        diff: plan.changeSet.diff,
        artifacts: plan.artifacts,
        extensions: {
          'planId': plan.planId,
          'operationId': operationId,
          'multiFileGuarantee': 'recoverable',
          'history': historyContext.toJson(),
        },
      );
      var journal = AuthoringTransactionJournal(
        operationId: operationId,
        planId: plan.planId,
        scope: scope,
        status: AuthoringTransactionStatus.preparing,
        createdAt: now,
        updatedAt: now,
        entries: [
          for (final change in plan.changeSet.changes)
            AuthoringTransactionJournalEntry(
              resource: change.resource,
              storageKey: change.storageKey,
              beforeRevision: change.beforeRevision,
              afterRevision: change.afterRevision,
            ),
        ],
        intendedReceipt: intendedReceipt,
      );

      // The journal exists before idempotency reservation. A process stop can
      // therefore leave either a harmless unreserved intent or a recoverable
      // pending reservation, never a pending key with no transaction identity.
      await _gateway.writeJournal(journal);
      await _checkpoint(
        AuthoringTransactionCheckpoint.afterJournalPreparing,
        operationId,
      );

      for (final change in plan.changeSet.changes) {
        await _gateway.stagePayload(
          operationId: operationId,
          storageKey: change.storageKey,
          kind: TransactionPayloadKind.before,
          bytes: change.beforeBytes,
        );
        await _gateway.stagePayload(
          operationId: operationId,
          storageKey: change.storageKey,
          kind: TransactionPayloadKind.after,
          bytes: change.afterBytes,
        );
        await _requireStagedRevision(
          operationId: operationId,
          storageKey: change.storageKey,
          kind: TransactionPayloadKind.before,
          expectedRevision: change.beforeRevision,
        );
        await _requireStagedRevision(
          operationId: operationId,
          storageKey: change.storageKey,
          kind: TransactionPayloadKind.after,
          expectedRevision: change.afterRevision,
        );
      }
      await _checkpoint(
        AuthoringTransactionCheckpoint.afterPayloadsStaged,
        operationId,
      );
      journal = journal.copyWith(
        status: AuthoringTransactionStatus.staged,
        updatedAt: _clock().toUtc(),
      );
      await _gateway.writeJournal(journal);
      await _checkpoint(
        AuthoringTransactionCheckpoint.afterJournalStaged,
        operationId,
      );

      return _idempotency.execute(
        scope: scope,
        request: request,
        operationId: operationId,
        apply: () async {
          await _checkpoint(
            AuthoringTransactionCheckpoint.afterReservation,
            operationId,
          );
          journal = journal.copyWith(
            status: AuthoringTransactionStatus.prepared,
            updatedAt: _clock().toUtc(),
          );
          await _gateway.writeJournal(journal);
          await _checkpoint(
            AuthoringTransactionCheckpoint.afterJournalPrepared,
            operationId,
          );

          journal = journal.copyWith(
            status: AuthoringTransactionStatus.promoting,
            updatedAt: _clock().toUtc(),
          );
          await _gateway.writeJournal(journal);
          for (var index = 0; index < journal.entries.length; index++) {
            final entry = journal.entries[index];
            await _checkpoint(
              AuthoringTransactionCheckpoint.beforeResourcePromotion,
              operationId,
              storageKey: entry.storageKey,
              promotionIndex: index,
            );
            await _gateway.promoteStaged(
              operationId: operationId,
              storageKey: entry.storageKey,
              kind: TransactionPayloadKind.after,
              expectedCurrentRevision: entry.beforeRevision,
            );
            await _checkpoint(
              AuthoringTransactionCheckpoint.afterResourcePromoted,
              operationId,
              storageKey: entry.storageKey,
              promotionIndex: index,
            );
            journal = journal.copyWith(
              updatedAt: _clock().toUtc(),
              entries: _replaceEntry(
                journal.entries,
                index,
                entry.copyWith(promoted: true),
              ),
            );
            await _gateway.writeJournal(journal);
            await _checkpoint(
              AuthoringTransactionCheckpoint.afterResourceJournaled,
              operationId,
              storageKey: entry.storageKey,
              promotionIndex: index,
            );
          }

          journal = journal.copyWith(
            status: AuthoringTransactionStatus.committed,
            updatedAt: _clock().toUtc(),
            finalReceipt: intendedReceipt,
          );
          await _gateway.writeJournal(journal);
          await _checkpoint(
            AuthoringTransactionCheckpoint.afterJournalCommitted,
            operationId,
          );
          await _commitHook?.record(
            AuthoringCommittedMutation(
              scope: scope,
              planId: plan.planId,
              operationId: operationId,
              receipt: intendedReceipt,
              changes: plan.changeSet.changes,
            ),
          );
          return intendedReceipt;
        },
      );
    });
  }

  Future<AuthoringRevisionSet> _currentRevisions(
    AuthoringPlan plan,
  ) async {
    return AuthoringRevisionSet([
      for (final change in plan.changeSet.changes)
        AuthoringResourceRevision(
          resource: change.resource,
          revision: await _gateway.readResourceRevision(change.storageKey),
        ),
    ]);
  }

  Future<void> _requireStagedRevision({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedRevision,
  }) async {
    final staged = await _gateway.readStagedPayload(
      operationId: operationId,
      storageKey: storageKey,
      kind: kind,
    );
    if (staged.revision != expectedRevision) {
      throw const TransactionFileGatewayException(
        'transaction.stage_corrupt',
        'A staged transaction revision differs from the frozen plan.',
      );
    }
  }

  Future<void> _checkpoint(
    AuthoringTransactionCheckpoint checkpoint,
    String operationId, {
    String? storageKey,
    int? promotionIndex,
  }) async {
    final injector = _faultInjector;
    if (injector == null) return;
    await injector(
      AuthoringTransactionCheckpointContext(
        checkpoint: checkpoint,
        operationId: operationId,
        storageKey: storageKey,
        promotionIndex: promotionIndex,
      ),
    );
  }
}

void _requireRequestMatchesPlan(
  AuthoringRequest request,
  AuthoringPlan plan,
) {
  final planned = plan.request;
  final sameSemantics = request.actionId == planned.actionId &&
      request.actionVersion == planned.actionVersion &&
      request.expectedRevision == planned.expectedRevision &&
      request.idempotencyKey == planned.idempotencyKey &&
      request.dryRun == planned.dryRun &&
      canonicalAuthoringJson(request.parameters) ==
          canonicalAuthoringJson(planned.parameters) &&
      canonicalAuthoringJson(request.extensions) ==
          canonicalAuthoringJson(planned.extensions);
  if (!sameSemantics) {
    throw const JournaledAuthoringTransactionException(
      'transaction.request_plan_mismatch',
      'The apply request does not match the frozen mutation plan.',
    );
  }
}

List<AuthoringTransactionJournalEntry> _replaceEntry(
  List<AuthoringTransactionJournalEntry> entries,
  int index,
  AuthoringTransactionJournalEntry replacement,
) {
  return List.unmodifiable([
    for (var entryIndex = 0; entryIndex < entries.length; entryIndex++)
      if (entryIndex == index) replacement else entries[entryIndex],
  ]);
}

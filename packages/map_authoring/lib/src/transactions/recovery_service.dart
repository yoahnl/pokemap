import '../contracts/authoring_receipt.dart';
import '../ports/idempotency_store.dart';
import '../ports/transaction_file_gateway.dart';
import 'idempotency_ledger.dart';
import 'revision_set.dart';
import 'transaction_journal.dart';

enum AuthoringRecoveryDisposition {
  unreservedIntent,
  resumable,
  completed,
  blocked,
}

final class AuthoringRecoveryInspection {
  const AuthoringRecoveryInspection({
    required this.operationId,
    required this.journalStatus,
    required this.disposition,
    required this.message,
  });

  final String operationId;
  final AuthoringTransactionStatus journalStatus;
  final AuthoringRecoveryDisposition disposition;
  final String message;

  Map<String, Object?> toJson() => {
        'operationId': operationId,
        'journalStatus': journalStatus.name,
        'disposition': disposition.name,
        'message': message,
      };
}

final class AuthoringRecoveryException implements Exception {
  const AuthoringRecoveryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringRecoveryException($code): $message';
}

/// Inspects, resumes, or compensates a durable transaction without guessing.
final class AuthoringRecoveryService {
  const AuthoringRecoveryService({
    required TransactionFileGateway gateway,
    required AuthoringIdempotencyLedger idempotency,
    required DateTime Function() clock,
  })  : _gateway = gateway,
        _idempotency = idempotency,
        _clock = clock;

  final TransactionFileGateway _gateway;
  final AuthoringIdempotencyLedger _idempotency;
  final DateTime Function() _clock;

  Future<List<AuthoringRecoveryInspection>> inspect() {
    return _gateway.withExclusiveWriteLock(() async {
      final journals = await _gateway.listJournals();
      final inspections = <AuthoringRecoveryInspection>[];
      for (final journal in journals) {
        inspections.add(await _inspectJournal(journal));
      }
      return List.unmodifiable(inspections);
    });
  }

  Future<AuthoringReceipt> resume(String operationId) {
    return _gateway.withExclusiveWriteLock(() async {
      var journal = await _requireJournal(operationId);
      final record = await _requireRecoveryRecord(journal);
      if (record.status == AuthoringIdempotencyStatus.completed) {
        return record.receipt!;
      }
      await _requireStages(journal);
      if (journal.status == AuthoringTransactionStatus.compensated) {
        return _idempotency.completeRecovered(
          scope: journal.scope,
          operationId: operationId,
          receipt: journal.finalReceipt!,
        );
      }

      final states = await _states(journal);
      _requireOnlyBeforeOrAfter(states);
      if (journal.status == AuthoringTransactionStatus.committed) {
        if (!states.every((state) => state.isAfter)) {
          throw const AuthoringRecoveryException(
            'recovery.committed_state_mismatch',
            'Committed transaction resources do not match their after state.',
          );
        }
        final recovered = _recoveredReceipt(
          journal,
          outcome: 'resumed',
          beforeRevision: journal.intendedReceipt.beforeRevision,
          afterRevision: journal.intendedReceipt.afterRevision,
        );
        journal = journal.copyWith(
          updatedAt: _clock().toUtc(),
          finalReceipt: recovered,
        );
        await _gateway.writeJournal(journal);
        return _idempotency.completeRecovered(
          scope: journal.scope,
          operationId: operationId,
          receipt: recovered,
        );
      }

      journal = journal.copyWith(
        status: AuthoringTransactionStatus.promoting,
        updatedAt: _clock().toUtc(),
      );
      await _gateway.writeJournal(journal);
      for (var index = 0; index < journal.entries.length; index++) {
        final entry = journal.entries[index];
        final current = await _gateway.readResourceRevision(entry.storageKey);
        if (current == entry.afterRevision) {
          journal = await _checkpointEntry(
            journal,
            index,
            entry.copyWith(promoted: true),
          );
          continue;
        }
        if (current != entry.beforeRevision) {
          throw const AuthoringRecoveryException(
            'recovery.revision_conflict',
            'A transaction resource has an unexpected recovery revision.',
          );
        }
        await _gateway.promoteStaged(
          operationId: operationId,
          storageKey: entry.storageKey,
          kind: TransactionPayloadKind.after,
          expectedCurrentRevision: entry.beforeRevision,
        );
        journal = await _checkpointEntry(
          journal,
          index,
          entry.copyWith(promoted: true),
        );
      }

      final recovered = _recoveredReceipt(
        journal,
        outcome: 'resumed',
        beforeRevision: journal.intendedReceipt.beforeRevision,
        afterRevision: journal.intendedReceipt.afterRevision,
      );
      journal = journal.copyWith(
        status: AuthoringTransactionStatus.committed,
        updatedAt: _clock().toUtc(),
        finalReceipt: recovered,
      );
      await _gateway.writeJournal(journal);
      return _idempotency.completeRecovered(
        scope: journal.scope,
        operationId: operationId,
        receipt: recovered,
      );
    });
  }

  Future<AuthoringReceipt> compensate(String operationId) {
    return _gateway.withExclusiveWriteLock(() async {
      var journal = await _requireJournal(operationId);
      final record = await _requireRecoveryRecord(journal);
      if (record.status == AuthoringIdempotencyStatus.completed) {
        if (journal.status == AuthoringTransactionStatus.compensated) {
          return record.receipt!;
        }
        throw const AuthoringRecoveryException(
          'recovery.already_completed',
          'A completed transaction must be undone as a new transaction.',
        );
      }
      await _requireStages(journal);
      final states = await _states(journal);
      _requireOnlyBeforeOrAfter(states);

      journal = journal.copyWith(
        status: AuthoringTransactionStatus.compensating,
        updatedAt: _clock().toUtc(),
        finalReceipt: null,
      );
      await _gateway.writeJournal(journal);
      for (var index = journal.entries.length - 1; index >= 0; index--) {
        final entry = journal.entries[index];
        final current = await _gateway.readResourceRevision(entry.storageKey);
        if (current == entry.beforeRevision) {
          journal = await _checkpointEntry(
            journal,
            index,
            entry.copyWith(compensated: true),
          );
          continue;
        }
        if (current != entry.afterRevision) {
          throw const AuthoringRecoveryException(
            'recovery.revision_conflict',
            'A transaction resource has an unexpected compensation revision.',
          );
        }
        await _gateway.promoteStaged(
          operationId: operationId,
          storageKey: entry.storageKey,
          kind: TransactionPayloadKind.before,
          expectedCurrentRevision: entry.afterRevision,
        );
        journal = await _checkpointEntry(
          journal,
          index,
          entry.copyWith(compensated: true),
        );
      }

      final beforeSet = AuthoringRevisionSet([
        for (final entry in journal.entries)
          AuthoringResourceRevision(
            resource: entry.resource,
            revision: entry.beforeRevision,
          ),
      ]);
      final recovered = _recoveredReceipt(
        journal,
        outcome: 'compensated',
        beforeRevision: journal.intendedReceipt.afterRevision,
        afterRevision: beforeSet.fingerprint,
      );
      journal = journal.copyWith(
        status: AuthoringTransactionStatus.compensated,
        updatedAt: _clock().toUtc(),
        finalReceipt: recovered,
      );
      await _gateway.writeJournal(journal);
      return _idempotency.completeRecovered(
        scope: journal.scope,
        operationId: operationId,
        receipt: recovered,
      );
    });
  }

  Future<bool> discardUnreserved(String operationId) {
    return _gateway.withExclusiveWriteLock(() async {
      final journal = await _requireJournal(operationId);
      final record = await _idempotency.recordForRecovery(journal.scope);
      if (record != null ||
          (journal.status != AuthoringTransactionStatus.preparing &&
              journal.status != AuthoringTransactionStatus.staged)) {
        throw const AuthoringRecoveryException(
          'recovery.intent_reserved',
          'Only an unreserved preparation may be discarded.',
        );
      }
      final states = await _states(journal);
      if (!states.every((state) => state.isBefore)) {
        throw const AuthoringRecoveryException(
          'recovery.revision_conflict',
          'An unreserved intent cannot be discarded after a resource change.',
        );
      }
      await _gateway.deleteTransaction(operationId);
      return true;
    });
  }

  Future<AuthoringRecoveryInspection> _inspectJournal(
    AuthoringTransactionJournal journal,
  ) async {
    final record = await _idempotency.recordForRecovery(journal.scope);
    final states = await _states(journal);
    final stagesValid = await _stagesValid(journal);
    final hasUnexpected =
        states.any((state) => !state.isBefore && !state.isAfter);
    final stageRequired = record != null ||
        (journal.status != AuthoringTransactionStatus.preparing &&
            journal.status != AuthoringTransactionStatus.staged);
    if (hasUnexpected ||
        (stageRequired && !stagesValid) ||
        (record != null && record.operationId != journal.operationId)) {
      return _inspection(
        journal,
        AuthoringRecoveryDisposition.blocked,
        'Recovery is blocked by an unexpected resource or reservation state.',
      );
    }
    if (record == null) {
      final discardable =
          (journal.status == AuthoringTransactionStatus.preparing ||
                  journal.status == AuthoringTransactionStatus.staged) &&
              states.every((state) => state.isBefore);
      return _inspection(
        journal,
        discardable
            ? AuthoringRecoveryDisposition.unreservedIntent
            : AuthoringRecoveryDisposition.blocked,
        discardable
            ? 'The unreserved intent can be discarded or retried safely.'
            : 'Recovery is blocked because the durable reservation is absent.',
      );
    }
    if (record.status == AuthoringIdempotencyStatus.completed) {
      final stateMatches = switch (journal.status) {
        AuthoringTransactionStatus.committed =>
          states.every((state) => state.isAfter),
        AuthoringTransactionStatus.compensated =>
          states.every((state) => state.isBefore),
        _ => false,
      };
      return _inspection(
        journal,
        stateMatches
            ? AuthoringRecoveryDisposition.completed
            : AuthoringRecoveryDisposition.blocked,
        stateMatches
            ? 'The transaction and idempotency receipt are complete.'
            : 'A completed receipt conflicts with journal or resource state.',
      );
    }
    return _inspection(
      journal,
      AuthoringRecoveryDisposition.resumable,
      'The pending transaction can be resumed or compensated.',
    );
  }

  Future<AuthoringTransactionJournal> _requireJournal(
    String operationId,
  ) async {
    final journal = await _gateway.readJournal(operationId);
    if (journal == null) {
      throw const AuthoringRecoveryException(
        'recovery.journal_missing',
        'The requested recovery journal is unavailable.',
      );
    }
    return journal;
  }

  Future<AuthoringIdempotencyRecord> _requireRecoveryRecord(
    AuthoringTransactionJournal journal,
  ) async {
    final record = await _idempotency.recordForRecovery(journal.scope);
    if (record == null || record.operationId != journal.operationId) {
      throw const AuthoringRecoveryException(
        'recovery.reservation_missing',
        'The matching pending reservation is unavailable.',
      );
    }
    return record;
  }

  Future<List<_ResourceRecoveryState>> _states(
    AuthoringTransactionJournal journal,
  ) async {
    return [
      for (final entry in journal.entries)
        _ResourceRecoveryState(
          entry: entry,
          currentRevision:
              await _gateway.readResourceRevision(entry.storageKey),
        ),
    ];
  }

  void _requireOnlyBeforeOrAfter(List<_ResourceRecoveryState> states) {
    if (states.any((state) => !state.isBefore && !state.isAfter)) {
      throw const AuthoringRecoveryException(
        'recovery.revision_conflict',
        'A transaction resource has an unexpected recovery revision.',
      );
    }
  }

  Future<bool> _stagesValid(AuthoringTransactionJournal journal) async {
    try {
      for (final entry in journal.entries) {
        final before = await _gateway.readStagedPayload(
          operationId: journal.operationId,
          storageKey: entry.storageKey,
          kind: TransactionPayloadKind.before,
        );
        final after = await _gateway.readStagedPayload(
          operationId: journal.operationId,
          storageKey: entry.storageKey,
          kind: TransactionPayloadKind.after,
        );
        if (before.revision != entry.beforeRevision ||
            after.revision != entry.afterRevision) {
          return false;
        }
      }
      return true;
    } on TransactionFileGatewayException {
      return false;
    }
  }

  Future<void> _requireStages(AuthoringTransactionJournal journal) async {
    if (!await _stagesValid(journal)) {
      throw const AuthoringRecoveryException(
        'recovery.stage_invalid',
        'A staged recovery payload is missing or corrupt.',
      );
    }
  }

  Future<AuthoringTransactionJournal> _checkpointEntry(
    AuthoringTransactionJournal journal,
    int index,
    AuthoringTransactionJournalEntry replacement,
  ) async {
    final updated = journal.copyWith(
      updatedAt: _clock().toUtc(),
      entries: [
        for (var entryIndex = 0;
            entryIndex < journal.entries.length;
            entryIndex++)
          if (entryIndex == index) replacement else journal.entries[entryIndex],
      ],
    );
    await _gateway.writeJournal(updated);
    return updated;
  }

  AuthoringReceipt _recoveredReceipt(
    AuthoringTransactionJournal journal, {
    required String outcome,
    required String? beforeRevision,
    required String? afterRevision,
  }) {
    final intended = journal.intendedReceipt;
    return AuthoringReceipt(
      receiptId: intended.receiptId,
      requestId: intended.requestId,
      actionId: intended.actionId,
      actionVersion: intended.actionVersion,
      status: AuthoringReceiptStatus.recovered,
      beforeRevision: beforeRevision,
      afterRevision: afterRevision,
      createdAtUtc: _clock().toUtc().toIso8601String(),
      diff: intended.diff,
      artifacts: intended.artifacts,
      extensions: {
        ...intended.extensions,
        'recoveryOutcome': outcome,
      },
    );
  }
}

AuthoringRecoveryInspection _inspection(
  AuthoringTransactionJournal journal,
  AuthoringRecoveryDisposition disposition,
  String message,
) {
  return AuthoringRecoveryInspection(
    operationId: journal.operationId,
    journalStatus: journal.status,
    disposition: disposition,
    message: message,
  );
}

final class _ResourceRecoveryState {
  const _ResourceRecoveryState({
    required this.entry,
    required this.currentRevision,
  });

  final AuthoringTransactionJournalEntry entry;
  final String? currentRevision;

  bool get isBefore => currentRevision == entry.beforeRevision;
  bool get isAfter => currentRevision == entry.afterRevision;
}

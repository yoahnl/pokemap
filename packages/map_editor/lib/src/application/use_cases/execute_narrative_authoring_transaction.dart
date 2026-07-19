import 'package:map_core/map_core.dart';

import '../models/narrative_authoring_transaction.dart';
import '../ports/narrative_authoring_persistence_gateway.dart';

/// Serializes validated narrative mutations through the persistence boundary.
///
/// Pure rejections and no-ops are returned locally. Applicable mutations reach
/// the gateway exactly once, and a second call is refused while that await is
/// in flight so one use-case instance cannot overlap project writes.
final class ExecuteNarrativeAuthoringTransaction {
  ExecuteNarrativeAuthoringTransaction(this._persistenceGateway);

  final NarrativeAuthoringPersistenceGateway _persistenceGateway;
  bool _busy = false;

  bool get isBusy => _busy;

  Future<NarrativeAuthoringTransactionResult> execute({
    required String projectPath,
    required String operationId,
    required NarrativeAssetMutationResult mutation,
  }) async {
    final transaction = NarrativeAuthoringTransaction.fromMutation(
      projectPath: projectPath,
      operationId: operationId,
      mutation: mutation,
    );

    switch (mutation) {
      case NarrativeAssetRejected(:final code, :final message):
        return NarrativeAuthoringTransactionResult(
          status: NarrativeAuthoringTransactionStatus.rejected,
          code: code,
          message: message,
          transaction: transaction,
        );
      case NarrativeAssetNoChange(:final reason):
        return NarrativeAuthoringTransactionResult(
          status: NarrativeAuthoringTransactionStatus.noChange,
          code: 'noChange',
          message: reason,
          transaction: transaction,
        );
      case NarrativeAssetCreated() ||
            NarrativeAssetUpdated() ||
            NarrativeAssetDeleted():
        break;
    }

    // Rejections and no-ops are pure local answers and must keep their exact
    // diagnostics even while another applicable write is awaiting I/O.
    if (_busy) {
      return NarrativeAuthoringTransactionResult(
        status: NarrativeAuthoringTransactionStatus.busy,
        code: 'transactionBusy',
        message: 'Another narrative mutation is already being persisted.',
        transaction: transaction,
      );
    }

    _busy = true;
    try {
      final persistenceResult = await _persistenceGateway.persist(transaction);
      return NarrativeAuthoringTransactionResult(
        status: _transactionStatus(persistenceResult.status),
        code: persistenceResult.code,
        message: persistenceResult.message,
        transaction: transaction,
        persistenceResult: persistenceResult,
      );
    } on Object catch (error, stackTrace) {
      return NarrativeAuthoringTransactionResult(
        status: NarrativeAuthoringTransactionStatus.persistenceFailed,
        code: 'unexpectedPersistenceFailure',
        message: 'The narrative mutation could not be persisted.',
        transaction: transaction,
        persistenceError: error,
        persistenceStackTrace: stackTrace,
      );
    } finally {
      _busy = false;
    }
  }
}

NarrativeAuthoringTransactionStatus _transactionStatus(
  NarrativeAuthoringPersistenceStatus status,
) {
  return switch (status) {
    NarrativeAuthoringPersistenceStatus.committed =>
      NarrativeAuthoringTransactionStatus.committed,
    NarrativeAuthoringPersistenceStatus.persistenceFailed =>
      NarrativeAuthoringTransactionStatus.persistenceFailed,
    NarrativeAuthoringPersistenceStatus.recoveryRequired =>
      NarrativeAuthoringTransactionStatus.recoveryRequired,
  };
}

import '../transactions/authoring_payload.dart';
import '../transactions/transaction_journal.dart';

enum TransactionPayloadKind { before, after }

final class TransactionFileGatewayException implements Exception {
  const TransactionFileGatewayException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'TransactionFileGatewayException($code): $message';
}

final class TransactionStagedPayload {
  TransactionStagedPayload(
      {required this.storageKey, required Iterable<int>? bytes})
      : payload = bytes == null
            ? null
            : AuthoringPayload.inline(bytes, storageKey: storageKey);

  TransactionStagedPayload.withPayload(
      {required this.storageKey, required this.payload});
  final String storageKey;
  final AuthoringPayload? payload;
  List<int>? get bytes => payload?.inlineBytes;
  String? get revision => payload?.resourceRevision;
}

abstract interface class StreamingTransactionFileGateway {
  Future<AuthoringPayload?> captureResourcePayload(String storageKey);
  Future<void> stageAuthoringPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required AuthoringPayload? payload,
  });
}

abstract interface class TransactionStagedArtifactProbe {
  Future<bool> hasStagedArtifacts({
    required String operationId,
    required TransactionPayloadKind kind,
    required Iterable<String> storageKeys,
  });
}

extension TransactionPayloadGateway on TransactionFileGateway {
  Future<AuthoringPayload?> captureResourcePayload(String storageKey) async {
    final gateway = this;
    if (gateway is StreamingTransactionFileGateway) {
      return (gateway as StreamingTransactionFileGateway)
          .captureResourcePayload(storageKey);
    }
    throw const TransactionFileGatewayException(
        'transaction.streaming_required',
        'The transaction gateway cannot capture a bounded payload.');
  }

  Future<void> stageAuthoringPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required AuthoringPayload? payload,
  }) async {
    final gateway = this;
    if (gateway is StreamingTransactionFileGateway) {
      await (gateway as StreamingTransactionFileGateway).stageAuthoringPayload(
          operationId: operationId,
          storageKey: storageKey,
          kind: kind,
          payload: payload);
      return;
    }
    await stagePayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
        bytes: payload?.inlineBytes);
  }
}

/// Project-local storage capabilities required by the write state machine.
abstract interface class TransactionFileGateway {
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation);

  Future<List<int>?> readResource(String storageKey);

  Future<String?> readResourceRevision(String storageKey);

  Future<void> stagePayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required List<int>? bytes,
  });

  Future<TransactionStagedPayload> readStagedPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
  });

  Future<void> promoteStaged({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedCurrentRevision,
  });

  Future<void> writeJournal(AuthoringTransactionJournal journal);

  Future<AuthoringTransactionJournal?> readJournal(String operationId);

  Future<List<AuthoringTransactionJournal>> listJournals();

  Future<void> deleteTransaction(String operationId);
}

abstract interface class PendingTransactionJournalGateway {
  Future<void> preparePendingJournalIndex();
  Future<List<AuthoringTransactionJournal>> listPendingJournals();
}

Future<void> preparePendingTransactionJournals(
    TransactionFileGateway gateway) async {
  if (gateway is PendingTransactionJournalGateway) {
    await (gateway as PendingTransactionJournalGateway)
        .preparePendingJournalIndex();
  }
}

Future<List<AuthoringTransactionJournal>> readPendingTransactionJournals(
    TransactionFileGateway gateway,
    {bool allowLegacyScan = false}) async {
  if (gateway is PendingTransactionJournalGateway) {
    try {
      return await (gateway as PendingTransactionJournalGateway)
          .listPendingJournals();
    } on TransactionFileGatewayException catch (error) {
      if (!allowLegacyScan ||
          error.code != 'transaction.pending_index_preparation_required') {
        rethrow;
      }
    }
  }
  return gateway.listJournals();
}

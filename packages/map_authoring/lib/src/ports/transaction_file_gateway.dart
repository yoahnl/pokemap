import '../support/authoring_fingerprint.dart';
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
  TransactionStagedPayload({
    required this.storageKey,
    required Iterable<int>? bytes,
  }) : bytes = bytes == null
            ? null
            : List<int>.unmodifiable(bytes.toList(growable: false)) {
    if (this.bytes?.any((value) => value < 0 || value > 255) ?? false) {
      throw ArgumentError.value(bytes, 'bytes', 'must contain bytes');
    }
    revision = this.bytes == null
        ? null
        : computeAuthoringBytesFingerprint(
            this.bytes!,
            logicalName: storageKey,
          );
  }

  final String storageKey;
  final List<int>? bytes;
  late final String? revision;
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

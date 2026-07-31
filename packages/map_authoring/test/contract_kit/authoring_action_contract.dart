import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

/// Reusable assertions for every future action adapter contract test.
abstract final class AuthoringActionContractKit {
  static void expectWellFormed({
    required AuthoringRequest request,
    required AuthoringResult result,
  }) {
    expect(result.requestId, request.requestId);
    if (result.status == AuthoringResultStatus.success) {
      expect(result.error, isNull);
      final receipt = result.receipt;
      if (receipt != null) {
        expect(receipt.requestId, request.requestId);
        expect(receipt.actionId, request.actionId);
        expect(receipt.actionVersion, request.actionVersion);
        expect(
          receipt.status,
          request.dryRun
              ? AuthoringReceiptStatus.planned
              : AuthoringReceiptStatus.applied,
        );
      }
    } else {
      expect(result.error, isNotNull);
      expect(result.receipt, isNull);
    }
  }
}

/// In-memory fixture that proves the common dry-run and idempotency contract.
///
/// It is intentionally test-only. Real persistence and durable idempotency
/// belong to PMCP-021 and must not be implied by this fixture.
final class FakeAuthoringActionRepository {
  final Map<String, AuthoringResult> _appliedByIdempotencyKey = {};

  int value = 0;
  int applyCount = 0;

  AuthoringResult execute(AuthoringRequest request) {
    final amount = request.parameters['amount'];
    if (amount is! int) {
      return AuthoringResult.failure(
        requestId: request.requestId,
        error: AuthoringError(
          code: AuthoringErrorCode.validationFailed,
          message: 'amount must be an integer',
          retryable: false,
          fieldPath: r'$.parameters.amount',
        ),
      );
    }

    if (!request.dryRun) {
      final idempotencyKey = request.idempotencyKey;
      if (idempotencyKey != null) {
        final previous = _appliedByIdempotencyKey[idempotencyKey];
        if (previous != null) return previous;
      }
    }

    final before = value;
    final after = before + amount;
    if (!request.dryRun) {
      value = after;
      applyCount++;
    }

    final status = request.dryRun
        ? AuthoringReceiptStatus.planned
        : AuthoringReceiptStatus.applied;
    final result = AuthoringResult.success(
      requestId: request.requestId,
      data: {
        'value': after,
        'mutated': !request.dryRun,
      },
      receipt: AuthoringReceipt(
        receiptId: 'receipt-${request.requestId}',
        requestId: request.requestId,
        actionId: request.actionId,
        actionVersion: request.actionVersion,
        status: status,
        beforeRevision: 'rev-$before',
        afterRevision: request.dryRun ? 'rev-$before' : 'rev-$after',
        createdAtUtc: '2026-07-31T00:00:00.000Z',
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: AuthoringResourceRef(
              kind: 'project',
              id: 'fixture',
            ),
            path: r'$.value',
            before: before,
            after: after,
          ),
        ]),
      ),
    );

    final idempotencyKey = request.idempotencyKey;
    if (!request.dryRun && idempotencyKey != null) {
      _appliedByIdempotencyKey[idempotencyKey] = result;
    }
    return result;
  }
}

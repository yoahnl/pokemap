import 'dart:async';

import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../ports/idempotency_store.dart';
import '../support/authoring_fingerprint.dart';
import 'authoring_plan.dart';

typedef AuthoringIdempotencyClock = DateTime Function();

final class AuthoringIdempotencyException implements Exception {
  AuthoringIdempotencyException({
    required this.code,
    required this.message,
    Iterable<String> remediation = const [],
  }) : remediation = List.unmodifiable(remediation);

  final String code;
  final String message;
  final List<String> remediation;

  @override
  String toString() => 'AuthoringIdempotencyException($code): $message';
}

/// Reserves a durable mutation identity before invoking an apply callback.
final class AuthoringIdempotencyLedger {
  AuthoringIdempotencyLedger({
    required IdempotencyStore store,
    AuthoringIdempotencyClock? clock,
    this.completedRetention = const Duration(days: 30),
  })  : _store = store,
        _clock = clock ?? _systemClock {
    if (completedRetention <= Duration.zero) {
      throw ArgumentError.value(
        completedRetention,
        'completedRetention',
        'must be positive',
      );
    }
  }

  final IdempotencyStore _store;
  final AuthoringIdempotencyClock _clock;
  final Duration completedRetention;

  Future<AuthoringReceipt> execute({
    required AuthoringIdempotencyScope scope,
    required AuthoringRequest request,
    required String operationId,
    required FutureOr<AuthoringReceipt> Function() apply,
  }) async {
    _requireScopeMatchesRequest(scope, request);
    final now = _clock().toUtc();
    final payloadFingerprint =
        computeAuthoringIdempotencyPayloadFingerprint(request);
    final pending = AuthoringIdempotencyRecord(
      scope: scope,
      payloadFingerprint: payloadFingerprint,
      operationId: operationId,
      status: AuthoringIdempotencyStatus.pending,
      createdAt: now,
    );
    final reservation = await _store.reserve(pending);
    if (!reservation.acquired) {
      final existing = reservation.record;
      if (existing.payloadFingerprint != payloadFingerprint) {
        throw AuthoringIdempotencyException(
          code: 'idempotency.payload_conflict',
          message: 'This idempotency key was used with another payload.',
          remediation: const ['Use a new idempotency key for a new mutation.'],
        );
      }
      if (existing.status == AuthoringIdempotencyStatus.completed) {
        return existing.receipt!;
      }
      throw AuthoringIdempotencyException(
        code: 'idempotency.recovery_required',
        message: 'A durable mutation reservation has no final receipt yet.',
        remediation: const [
          'Inspect and recover the pending transaction before retrying.',
        ],
      );
    }

    // Any exception after the flushed reservation intentionally leaves it
    // pending. The caller may already have made a write visible, so deleting
    // the reservation here would make an automatic retry unsafe.
    final receipt = await Future<AuthoringReceipt>.sync(apply);
    _validateReceipt(receipt, request);
    final completed = AuthoringIdempotencyRecord(
      scope: scope,
      payloadFingerprint: payloadFingerprint,
      operationId: operationId,
      status: AuthoringIdempotencyStatus.completed,
      createdAt: now,
      expiresAt: now.add(completedRetention),
      receipt: receipt,
    );
    return (await _store.complete(completed)).receipt!;
  }

  Future<int> pruneExpired() => _store.pruneExpired(_clock().toUtc());

  /// Returns an already completed receipt before a transaction prepares new
  /// artifacts. A pending record deliberately raises recovery-required.
  Future<AuthoringReceipt?> inspect({
    required AuthoringIdempotencyScope scope,
    required AuthoringRequest request,
  }) async {
    _requireScopeMatchesRequest(scope, request);
    return _inspect(
      scope,
      computeAuthoringIdempotencyPayloadFingerprint(request),
    );
  }

  Future<AuthoringReceipt?> inspectPlan({
    required AuthoringIdempotencyScope scope,
    required AuthoringPlan plan,
  }) async {
    _requireScopeMatchesRequest(scope, plan.request);
    return _inspect(scope, plan.idempotencyPayloadFingerprint);
  }

  Future<AuthoringReceipt?> _inspect(
    AuthoringIdempotencyScope scope,
    String payloadFingerprint,
  ) async {
    final existing = await _store.read(scope);
    if (existing == null) return null;
    if (existing.payloadFingerprint != payloadFingerprint) {
      throw AuthoringIdempotencyException(
        code: 'idempotency.payload_conflict',
        message: 'This idempotency key was used with another payload.',
        remediation: const ['Use a new idempotency key for a new mutation.'],
      );
    }
    if (existing.status == AuthoringIdempotencyStatus.completed) {
      return existing.receipt;
    }
    throw AuthoringIdempotencyException(
      code: 'idempotency.recovery_required',
      message: 'A durable mutation reservation has no final receipt yet.',
      remediation: const [
        'Inspect and recover the pending transaction before retrying.',
      ],
    );
  }

  Future<AuthoringIdempotencyRecord?> recordForRecovery(
    AuthoringIdempotencyScope scope,
  ) =>
      _store.read(scope);

  /// Completes the existing pending record from a verified journal receipt.
  Future<AuthoringReceipt> completeRecovered({
    required AuthoringIdempotencyScope scope,
    required String operationId,
    required AuthoringReceipt receipt,
  }) async {
    final existing = await _store.read(scope);
    if (existing == null || existing.operationId != operationId) {
      throw AuthoringIdempotencyException(
        code: 'idempotency.recovery_record_missing',
        message: 'The matching durable reservation is unavailable.',
      );
    }
    if (existing.status == AuthoringIdempotencyStatus.completed) {
      return existing.receipt!;
    }
    _validateReceiptForScope(receipt, scope);
    final completed = AuthoringIdempotencyRecord(
      scope: scope,
      payloadFingerprint: existing.payloadFingerprint,
      operationId: operationId,
      status: AuthoringIdempotencyStatus.completed,
      createdAt: existing.createdAt,
      expiresAt: _clock().toUtc().add(completedRetention),
      receipt: receipt,
    );
    return (await _store.complete(completed)).receipt!;
  }
}

void _requireScopeMatchesRequest(
  AuthoringIdempotencyScope scope,
  AuthoringRequest request,
) {
  final key = request.idempotencyKey;
  if (scope.actionId != request.actionId ||
      scope.actionVersion != request.actionVersion ||
      key == null ||
      !scope.matchesKey(key)) {
    throw AuthoringIdempotencyException(
      code: 'idempotency.scope_mismatch',
      message: 'The durable idempotency scope does not match the request.',
      remediation: const ['Rebuild the scope from the mutation request.'],
    );
  }
  if (request.dryRun) {
    throw AuthoringIdempotencyException(
      code: 'idempotency.apply_required',
      message: 'Dry-run planning must not reserve a durable apply key.',
    );
  }
}

void _validateReceipt(AuthoringReceipt receipt, AuthoringRequest request) {
  if (receipt.requestId != request.requestId ||
      receipt.actionId != request.actionId ||
      receipt.actionVersion != request.actionVersion ||
      receipt.status == AuthoringReceiptStatus.planned) {
    throw AuthoringIdempotencyException(
      code: 'idempotency.receipt_invalid',
      message: 'The apply callback returned an incompatible receipt.',
      remediation: const [
        'Recover the pending mutation and rebuild its canonical receipt.',
      ],
    );
  }
}

void _validateReceiptForScope(
  AuthoringReceipt receipt,
  AuthoringIdempotencyScope scope,
) {
  if (receipt.actionId != scope.actionId ||
      receipt.actionVersion != scope.actionVersion ||
      receipt.status == AuthoringReceiptStatus.planned) {
    throw AuthoringIdempotencyException(
      code: 'idempotency.receipt_invalid',
      message: 'The recovery receipt is incompatible with its reservation.',
    );
  }
}

DateTime _systemClock() => DateTime.now().toUtc();

import '../contracts/authoring_receipt.dart';
import '../support/authoring_fingerprint.dart';

enum AuthoringIdempotencyStatus { pending, completed }

/// Durable uniqueness scope for one mutation intent.
///
/// The caller key remains in memory only. Durable JSON stores its fingerprint
/// so operator logs cannot reveal a client-supplied idempotency secret.
final class AuthoringIdempotencyScope {
  AuthoringIdempotencyScope({
    required String actorId,
    required String projectId,
    required String actionId,
    required int actionVersion,
    required String key,
  })  : actorId = _safeIdentity(actorId, 'actorId'),
        projectId = _safeIdentity(projectId, 'projectId'),
        actionId = _actionId(actionId),
        actionVersion = _positiveVersion(actionVersion),
        _rawKey = _nonBlank(key, 'key'),
        keyFingerprint = computeAuthoringJsonFingerprint(
          _nonBlank(key, 'key'),
          logicalName: 'idempotency-key.json',
        );

  AuthoringIdempotencyScope._stored({
    required this.actorId,
    required this.projectId,
    required this.actionId,
    required this.actionVersion,
    required this.keyFingerprint,
  }) : _rawKey = null;

  factory AuthoringIdempotencyScope.fromJson(Map<String, dynamic> json) {
    const keys = {
      'actorId',
      'projectId',
      'actionId',
      'actionVersion',
      'keyFingerprint',
    };
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Unknown idempotency scope field.');
    }
    final actorId = json['actorId'];
    final projectId = json['projectId'];
    final actionId = json['actionId'];
    final actionVersion = json['actionVersion'];
    final keyFingerprint = json['keyFingerprint'];
    if (actorId is! String ||
        projectId is! String ||
        actionId is! String ||
        actionVersion is! int ||
        keyFingerprint is! String) {
      throw const FormatException('Invalid idempotency scope fields.');
    }
    try {
      return AuthoringIdempotencyScope._stored(
        actorId: _safeIdentity(actorId, 'actorId'),
        projectId: _safeIdentity(projectId, 'projectId'),
        actionId: _actionId(actionId),
        actionVersion: _positiveVersion(actionVersion),
        keyFingerprint: _fingerprint(keyFingerprint, 'keyFingerprint'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String actorId;
  final String projectId;
  final String actionId;
  final int actionVersion;
  final String? _rawKey;
  final String keyFingerprint;

  String get key =>
      _rawKey ??
      (throw StateError('The raw idempotency key is not durably retained.'));

  bool matchesKey(String value) =>
      keyFingerprint ==
      computeAuthoringJsonFingerprint(
        value,
        logicalName: 'idempotency-key.json',
      );

  String get storageKey => canonicalAuthoringJson(toJson());

  Map<String, Object?> toJson() => {
        'actorId': actorId,
        'projectId': projectId,
        'actionId': actionId,
        'actionVersion': actionVersion,
        'keyFingerprint': keyFingerprint,
      };
}

final class AuthoringIdempotencyRecord {
  AuthoringIdempotencyRecord({
    required this.scope,
    required String payloadFingerprint,
    required String operationId,
    required this.status,
    required DateTime createdAt,
    DateTime? expiresAt,
    AuthoringReceipt? receipt,
  })  : payloadFingerprint =
            _fingerprint(payloadFingerprint, 'payloadFingerprint'),
        operationId = _safeIdentity(operationId, 'operationId'),
        createdAt = createdAt.toUtc(),
        expiresAt = expiresAt?.toUtc(),
        receipt = receipt {
    if (status == AuthoringIdempotencyStatus.pending &&
        (this.expiresAt != null || receipt != null)) {
      throw ArgumentError(
        'A pending idempotency record cannot expire or contain a receipt.',
      );
    }
    if (status == AuthoringIdempotencyStatus.completed &&
        (this.expiresAt == null || receipt == null)) {
      throw ArgumentError(
        'A completed idempotency record requires expiry and a receipt.',
      );
    }
    if (this.expiresAt != null && !this.expiresAt!.isAfter(this.createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must be after createdAt',
      );
    }
  }

  factory AuthoringIdempotencyRecord.fromJson(Map<String, dynamic> json) {
    const keys = {
      'scope',
      'payloadFingerprint',
      'operationId',
      'status',
      'createdAtUtc',
      'expiresAtUtc',
      'receipt',
    };
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Unknown idempotency record field.');
    }
    final rawScope = json['scope'];
    final rawReceipt = json['receipt'];
    if (rawScope is! Map || (rawReceipt != null && rawReceipt is! Map)) {
      throw const FormatException('Invalid idempotency record objects.');
    }
    final status = switch (json['status']) {
      'pending' => AuthoringIdempotencyStatus.pending,
      'completed' => AuthoringIdempotencyStatus.completed,
      _ => throw const FormatException('Invalid idempotency record status.'),
    };
    try {
      return AuthoringIdempotencyRecord(
        scope: AuthoringIdempotencyScope.fromJson(
          Map<String, dynamic>.from(rawScope),
        ),
        payloadFingerprint:
            _requiredString(json['payloadFingerprint'], 'payloadFingerprint'),
        operationId: _requiredString(json['operationId'], 'operationId'),
        status: status,
        createdAt: _utcDate(json['createdAtUtc'], 'createdAtUtc'),
        expiresAt: json['expiresAtUtc'] == null
            ? null
            : _utcDate(json['expiresAtUtc'], 'expiresAtUtc'),
        receipt: rawReceipt == null
            ? null
            : AuthoringReceipt.fromJson(
                Map<String, dynamic>.from(rawReceipt),
              ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final AuthoringIdempotencyScope scope;
  final String payloadFingerprint;
  final String operationId;
  final AuthoringIdempotencyStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final AuthoringReceipt? receipt;

  Map<String, Object?> toJson() => {
        'scope': scope.toJson(),
        'payloadFingerprint': payloadFingerprint,
        'operationId': operationId,
        'status': status.name,
        'createdAtUtc': createdAt.toIso8601String(),
        if (expiresAt != null) 'expiresAtUtc': expiresAt!.toIso8601String(),
        if (receipt != null) 'receipt': receipt!.toJson(),
      };
}

final class AuthoringIdempotencyReservation {
  const AuthoringIdempotencyReservation({
    required this.acquired,
    required this.record,
  });

  final bool acquired;
  final AuthoringIdempotencyRecord record;
}

abstract interface class IdempotencyStore {
  Future<AuthoringIdempotencyRecord?> read(
    AuthoringIdempotencyScope scope,
  );

  Future<AuthoringIdempotencyReservation> reserve(
    AuthoringIdempotencyRecord pendingRecord,
  );

  Future<AuthoringIdempotencyRecord> complete(
    AuthoringIdempotencyRecord completedRecord,
  );

  Future<int> pruneExpired(DateTime now);
}

String _requiredString(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

DateTime _utcDate(Object? value, String field) {
  final raw = _requiredString(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null || !parsed.isUtc || !raw.endsWith('Z')) {
    throw FormatException('$field must be a UTC timestamp.');
  }
  return parsed;
}

String _safeIdentity(String value, String field) {
  final normalized = _nonBlank(value, field);
  if (normalized.length > 200 ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must be a safe opaque identity',
    );
  }
  return normalized;
}

String _actionId(String value) {
  final normalized = _nonBlank(value, 'actionId');
  if (!RegExp(r'^[a-z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+$')
      .hasMatch(normalized)) {
    throw ArgumentError.value(value, 'actionId', 'must be a dotted action ID');
  }
  return normalized;
}

int _positiveVersion(int value) {
  if (value < 1) {
    throw ArgumentError.value(value, 'actionVersion', 'must be positive');
  }
  return value;
}

String _fingerprint(String value, String field) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 fingerprint');
  }
  return value;
}

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return normalized;
}

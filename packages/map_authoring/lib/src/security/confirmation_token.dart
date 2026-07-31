import 'dart:convert';
import 'dart:math';

import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import 'authoring_permission.dart';

final class AuthoringConfirmationException implements Exception {
  const AuthoringConfirmationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringConfirmationException($code): $message';
}

/// Server-side confirmation binding. The client receives only an opaque token.
final class AuthoringConfirmationBinding {
  AuthoringConfirmationBinding({
    required String actorId,
    required String projectId,
    required String actionId,
    required int actionVersion,
    required String planId,
    required String diffFingerprint,
  })  : actorId = safeAuthoringSecurityIdentifier(actorId, 'actorId'),
        projectId = safeAuthoringSecurityIdentifier(projectId, 'projectId'),
        actionId = safeAuthoringSecurityIdentifier(actionId, 'actionId'),
        actionVersion = _positiveVersion(actionVersion),
        planId = safeAuthoringSecurityIdentifier(planId, 'planId'),
        diffFingerprint = _fingerprint(diffFingerprint);

  factory AuthoringConfirmationBinding.forPlan({
    required String actorId,
    required String projectId,
    required AuthoringPlan plan,
  }) {
    return AuthoringConfirmationBinding(
      actorId: actorId,
      projectId: projectId,
      actionId: plan.request.actionId,
      actionVersion: plan.request.actionVersion,
      planId: plan.planId,
      diffFingerprint: computeAuthoringJsonFingerprint(
        plan.changeSet.diff.toJson(),
        logicalName: 'authoring-confirmation-diff.json',
      ),
    );
  }

  final String actorId;
  final String projectId;
  final String actionId;
  final int actionVersion;
  final String planId;
  final String diffFingerprint;

  bool matches(AuthoringConfirmationBinding other) =>
      actorId == other.actorId &&
      projectId == other.projectId &&
      actionId == other.actionId &&
      actionVersion == other.actionVersion &&
      planId == other.planId &&
      diffFingerprint == other.diffFingerprint;
}

/// An opaque capability. Its string representation deliberately hides value.
final class AuthoringConfirmationToken {
  const AuthoringConfirmationToken._(this._value);

  factory AuthoringConfirmationToken.fromWireValue(String value) =>
      AuthoringConfirmationToken._(_safeToken(value));

  final String _value;

  /// Opaque transport value. Bindings remain exclusively in the server store.
  String get wireValue => _value;

  @override
  String toString() => '[REDACTED]';
}

final class AuthoringConfirmationStore {
  AuthoringConfirmationStore({
    required DateTime Function() clock,
    String Function()? tokenFactory,
    this.lifetime = const Duration(minutes: 5),
  })  : _clock = clock,
        _tokenFactory = tokenFactory ?? _secureToken {
    if (lifetime <= Duration.zero) {
      throw ArgumentError.value(lifetime, 'lifetime', 'must be positive');
    }
  }

  final DateTime Function() _clock;
  final String Function() _tokenFactory;
  final Duration lifetime;
  final Map<String, _ConfirmationRecord> _records = {};

  AuthoringConfirmationToken issue(AuthoringConfirmationBinding binding) {
    for (var attempt = 0; attempt < 16; attempt++) {
      final value = _safeToken(_tokenFactory());
      if (_records.containsKey(value)) continue;
      final now = _clock().toUtc();
      _records[value] = _ConfirmationRecord(
        binding: binding,
        expiresAt: now.add(lifetime),
      );
      return AuthoringConfirmationToken._(value);
    }
    throw const AuthoringConfirmationException(
      'confirmation.identity_unavailable',
      'A unique confirmation identity could not be allocated.',
    );
  }

  void consume(
    AuthoringConfirmationToken token,
    AuthoringConfirmationBinding expected,
  ) {
    final record = _records[token._value];
    if (record == null) {
      throw const AuthoringConfirmationException(
        'confirmation.invalid',
        'The confirmation token is invalid.',
      );
    }
    if (record.used) {
      throw const AuthoringConfirmationException(
        'confirmation.used',
        'The confirmation token was already consumed.',
      );
    }
    if (!_clock().toUtc().isBefore(record.expiresAt)) {
      throw const AuthoringConfirmationException(
        'confirmation.expired',
        'The confirmation token expired.',
      );
    }
    if (!record.binding.matches(expected)) {
      throw const AuthoringConfirmationException(
        'confirmation.binding_mismatch',
        'The confirmation token does not match this mutation.',
      );
    }
    record.used = true;
  }

  int pruneExpired() {
    final now = _clock().toUtc();
    final expired = _records.entries
        .where((entry) => !now.isBefore(entry.value.expiresAt))
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in expired) {
      _records.remove(key);
    }
    return expired.length;
  }
}

final class _ConfirmationRecord {
  _ConfirmationRecord({required this.binding, required this.expiresAt});

  final AuthoringConfirmationBinding binding;
  final DateTime expiresAt;
  bool used = false;
}

String _secureToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String _safeToken(String value) {
  if (value.length < 8 ||
      value.length > 256 ||
      !_tokenPattern.hasMatch(value)) {
    throw const AuthoringConfirmationException(
      'confirmation.identity_invalid',
      'The confirmation identity generator returned an unsafe value.',
    );
  }
  return value;
}

String _fingerprint(String value) {
  if (!_fingerprintPattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'diffFingerprint',
      'must be a lowercase SHA-256 fingerprint',
    );
  }
  return value;
}

int _positiveVersion(int value) {
  if (value <= 0) {
    throw ArgumentError.value(value, 'actionVersion', 'must be positive');
  }
  return value;
}

final RegExp _tokenPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
final RegExp _fingerprintPattern = RegExp(r'^sha256:[0-9a-f]{64}$');

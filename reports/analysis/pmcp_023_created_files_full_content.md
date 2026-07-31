# PMCP-023 — Created Files Full Content

This appendix reproduces every file created by PMCP-023 exactly as it stood immediately before the lot commit. The Evidence Pack and this appendix are reporting artifacts and are intentionally not self-reproduced.

## `packages/map_authoring/lib/src/security/authoring_permission.dart`

~~~~~~~~dart
enum AuthoringPermissionScope {
  projectRead('project.read'),
  projectWrite('project.write'),
  projectDestructive('project.destructive'),
  assetRead('asset.read'),
  assetWrite('asset.write'),
  renderRun('render.run'),
  playtestRun('playtest.run'),
  playtestControl('playtest.control'),
  importRun('import.run'),
  exportRun('export.run'),
  migrationRun('migration.run'),
  networkExternal('network.external'),
  processExecute('process.execute'),
  secretUse('secret.use'),
  recoveryApply('recovery.apply');

  const AuthoringPermissionScope(this.wireName);

  final String wireName;

  static AuthoringPermissionScope fromWireName(String value) {
    return AuthoringPermissionScope.values.firstWhere(
      (scope) => scope.wireName == value,
      orElse: () => throw FormatException('Unknown permission scope.'),
    );
  }
}

enum AuthoringSecurityOperation {
  plan('plan'),
  apply('apply'),
  recover('recover'),
  assetWrite('asset.write'),
  networkAccess('network.access');

  const AuthoringSecurityOperation(this.wireName);

  final String wireName;

  static AuthoringSecurityOperation fromWireName(String value) {
    return AuthoringSecurityOperation.values.firstWhere(
      (operation) => operation.wireName == value,
      orElse: () => throw FormatException('Unknown security operation.'),
    );
  }

  AuthoringPermissionScope get primaryPermission => switch (this) {
        AuthoringSecurityOperation.plan => AuthoringPermissionScope.projectRead,
        AuthoringSecurityOperation.apply =>
          AuthoringPermissionScope.projectWrite,
        AuthoringSecurityOperation.recover =>
          AuthoringPermissionScope.recoveryApply,
        AuthoringSecurityOperation.assetWrite =>
          AuthoringPermissionScope.assetWrite,
        AuthoringSecurityOperation.networkAccess =>
          AuthoringPermissionScope.networkExternal,
      };
}

/// Immutable server-side identity and its granted least-privilege scopes.
final class AuthoringActor {
  AuthoringActor({
    required String actorId,
    Iterable<AuthoringPermissionScope> permissions = const [
      AuthoringPermissionScope.projectRead,
    ],
  })  : actorId = _safeSecurityIdentifier(actorId, 'actorId'),
        permissions = _sortedPermissions(permissions);

  final String actorId;
  final List<AuthoringPermissionScope> permissions;

  bool allows(AuthoringPermissionScope permission) =>
      permissions.contains(permission);
}

List<AuthoringPermissionScope> _sortedPermissions(
  Iterable<AuthoringPermissionScope> permissions,
) {
  final unique = permissions.toSet().toList()
    ..sort((left, right) => left.wireName.compareTo(right.wireName));
  return List.unmodifiable(unique);
}

String safeAuthoringSecurityIdentifier(String value, String field) =>
    _safeSecurityIdentifier(value, field);

String _safeSecurityIdentifier(String value, String field) {
  if (value.length > 160 ||
      value.trim() != value ||
      !_securityIdentifierPattern.hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a safe opaque identity');
  }
  return value;
}

final RegExp _securityIdentifierPattern =
    RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:@-]*$');
~~~~~~~~

## `packages/map_authoring/lib/src/security/authorization_policy.dart`

~~~~~~~~dart
import '../contracts/action_descriptor.dart';
import 'authoring_permission.dart';
import 'confirmation_token.dart';

final class AuthoringAuthorizationException implements Exception {
  const AuthoringAuthorizationException({
    required this.code,
    required this.message,
    this.remediation = const [],
  });

  final String code;
  final String message;
  final List<String> remediation;

  @override
  String toString() => 'AuthoringAuthorizationException($code): $message';
}

final class AuthoringSecurityLimits {
  const AuthoringSecurityLimits({
    this.maxRequestBytes = 1024 * 1024,
    this.maxTouchedResources = 500,
    this.maxOperationsPerWindow = 60,
    this.rateWindow = const Duration(minutes: 1),
  })  : assert(maxRequestBytes > 0),
        assert(maxTouchedResources > 0),
        assert(maxOperationsPerWindow > 0);

  final int maxRequestBytes;
  final int maxTouchedResources;
  final int maxOperationsPerWindow;
  final Duration rateWindow;
}

final class AuthoringAuthorizationRequest {
  AuthoringAuthorizationRequest({
    required this.actor,
    required String projectId,
    required this.operation,
    required String actionId,
    required int actionVersion,
    required this.riskLevel,
    required this.requestBytes,
    required this.touchedResources,
    String? planId,
    String? diffFingerprint,
    this.destructive = false,
    this.confirmationToken,
    Iterable<AuthoringPermissionScope> additionalPermissions = const [],
  })  : projectId = safeAuthoringSecurityIdentifier(projectId, 'projectId'),
        actionId = safeAuthoringSecurityIdentifier(actionId, 'actionId'),
        actionVersion = _positiveVersion(actionVersion),
        planId = planId == null
            ? null
            : safeAuthoringSecurityIdentifier(planId, 'planId'),
        diffFingerprint =
            diffFingerprint == null ? null : _fingerprint(diffFingerprint),
        additionalPermissions = _sortedPermissions(additionalPermissions) {
    if (requestBytes < 0) {
      throw ArgumentError.value(requestBytes, 'requestBytes', 'must be >= 0');
    }
    if (touchedResources < 0) {
      throw ArgumentError.value(
        touchedResources,
        'touchedResources',
        'must be >= 0',
      );
    }
  }

  final AuthoringActor actor;
  final String projectId;
  final AuthoringSecurityOperation operation;
  final String actionId;
  final int actionVersion;
  final AuthoringRiskLevel riskLevel;
  final int requestBytes;
  final int touchedResources;
  final String? planId;
  final String? diffFingerprint;
  final bool destructive;
  final AuthoringConfirmationToken? confirmationToken;
  final List<AuthoringPermissionScope> additionalPermissions;
}

final class AuthoringAuthorizationDecision {
  const AuthoringAuthorizationDecision({
    required this.requiredPermissions,
    required this.confirmationConsumed,
  });

  final List<AuthoringPermissionScope> requiredPermissions;
  final bool confirmationConsumed;
}

/// Uniform least-privilege policy evaluated before any project mutation.
final class AuthoringAuthorizationPolicy {
  AuthoringAuthorizationPolicy({
    required AuthoringConfirmationStore confirmations,
    required DateTime Function() clock,
    this.limits = const AuthoringSecurityLimits(),
  })  : _confirmations = confirmations,
        _clock = clock {
    if (limits.maxRequestBytes <= 0 ||
        limits.maxTouchedResources <= 0 ||
        limits.maxOperationsPerWindow <= 0 ||
        limits.rateWindow <= Duration.zero) {
      throw ArgumentError.value(
        limits,
        'limits',
        'all security limits must be positive',
      );
    }
  }

  final AuthoringConfirmationStore _confirmations;
  final DateTime Function() _clock;
  final AuthoringSecurityLimits limits;
  final Map<String, List<DateTime>> _rateBuckets = {};

  AuthoringAuthorizationDecision authorize(
    AuthoringAuthorizationRequest request,
  ) {
    final confirmationRequired = request.destructive &&
        (request.riskLevel == AuthoringRiskLevel.high ||
            request.riskLevel == AuthoringRiskLevel.critical);
    final required = <AuthoringPermissionScope>{
      request.operation.primaryPermission,
      ...request.additionalPermissions,
      if (confirmationRequired) AuthoringPermissionScope.projectDestructive,
    }.toList()
      ..sort((left, right) => left.wireName.compareTo(right.wireName));

    for (final permission in required) {
      if (!request.actor.allows(permission)) {
        throw AuthoringAuthorizationException(
          code: 'authorization.permission_denied',
          message: 'The actor lacks a required authoring permission.',
          remediation: [
            'Grant ${permission.wireName} through trusted server policy.',
          ],
        );
      }
    }
    if (request.requestBytes > limits.maxRequestBytes) {
      throw const AuthoringAuthorizationException(
        code: 'authorization.request_too_large',
        message: 'The authoring request exceeds its byte limit.',
      );
    }
    if (request.touchedResources > limits.maxTouchedResources) {
      throw const AuthoringAuthorizationException(
        code: 'authorization.too_many_resources',
        message: 'The mutation touches too many resources.',
      );
    }

    _recordRate(request);

    if (confirmationRequired) {
      final token = request.confirmationToken;
      if (token == null) {
        throw const AuthoringAuthorizationException(
          code: 'confirmation.required',
          message: 'This destructive mutation requires confirmation.',
        );
      }
      final planId = request.planId;
      final diffFingerprint = request.diffFingerprint;
      if (planId == null || diffFingerprint == null) {
        throw const AuthoringAuthorizationException(
          code: 'confirmation.binding_required',
          message:
              'A destructive confirmation requires plan and diff identity.',
        );
      }
      try {
        _confirmations.consume(
          token,
          AuthoringConfirmationBinding(
            actorId: request.actor.actorId,
            projectId: request.projectId,
            actionId: request.actionId,
            actionVersion: request.actionVersion,
            planId: planId,
            diffFingerprint: diffFingerprint,
          ),
        );
      } on AuthoringConfirmationException catch (error) {
        throw AuthoringAuthorizationException(
          code: error.code,
          message: error.message,
        );
      }
    }

    return AuthoringAuthorizationDecision(
      requiredPermissions: List.unmodifiable(required),
      confirmationConsumed: confirmationRequired,
    );
  }

  void _recordRate(AuthoringAuthorizationRequest request) {
    final now = _clock().toUtc();
    final cutoff = now.subtract(limits.rateWindow);
    final key = [
      request.actor.actorId,
      request.projectId,
      request.operation.wireName,
    ].join('\u0000');
    final events = _rateBuckets.putIfAbsent(key, () => <DateTime>[])
      ..removeWhere((timestamp) => !timestamp.isAfter(cutoff));
    if (events.length >= limits.maxOperationsPerWindow) {
      throw const AuthoringAuthorizationException(
        code: 'authorization.rate_limited',
        message: 'The authoring operation rate limit was exceeded.',
      );
    }
    events.add(now);
  }
}

List<AuthoringPermissionScope> _sortedPermissions(
  Iterable<AuthoringPermissionScope> permissions,
) {
  final sorted = permissions.toSet().toList()
    ..sort((left, right) => left.wireName.compareTo(right.wireName));
  return List.unmodifiable(sorted);
}

int _positiveVersion(int value) {
  if (value <= 0) {
    throw ArgumentError.value(value, 'actionVersion', 'must be positive');
  }
  return value;
}

String _fingerprint(String value) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'diffFingerprint',
      'must be a lowercase SHA-256 fingerprint',
    );
  }
  return value;
}
~~~~~~~~

## `packages/map_authoring/lib/src/security/confirmation_token.dart`

~~~~~~~~dart
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
~~~~~~~~

## `packages/map_authoring/lib/src/security/output_redaction.dart`

~~~~~~~~dart
import 'authorization_policy.dart';

final class AuthoringRedactedError {
  const AuthoringRedactedError({required this.code, required this.message});

  final String code;
  final String message;

  Map<String, Object?> toJson() => {'code': code, 'message': message};
}

/// Recursive output sanitizer used by audit and future transport adapters.
final class AuthoringOutputRedactor {
  const AuthoringOutputRedactor({this.maxDepth = 32});

  final int maxDepth;

  Object? redact(Object? value) => _redact(value, 0);

  AuthoringRedactedError redactError(Object error) {
    if (error case AuthoringAuthorizationException(:final code)) {
      return AuthoringRedactedError(
        code: _safeCode(code),
        message: code.startsWith('authorization.') ||
                code.startsWith('confirmation.')
            ? 'The operation was denied safely.'
            : 'The operation failed safely.',
      );
    }
    return const AuthoringRedactedError(
      code: 'internal.error',
      message: 'The operation failed safely.',
    );
  }

  Object? _redact(Object? value, int depth) {
    if (depth > maxDepth) return '[REDACTED]';
    if (value == null || value is num || value is bool) return value;
    if (value is String) return _redactString(value);
    if (value is Map) {
      final output = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) continue;
        output[key] = _secretLikeKey(key)
            ? '[REDACTED]'
            : _redact(entry.value, depth + 1);
      }
      return Map<String, Object?>.unmodifiable(output);
    }
    if (value is Iterable) {
      return List<Object?>.unmodifiable(
        value.map((item) => _redact(item, depth + 1)),
      );
    }
    return '[REDACTED]';
  }
}

String _redactString(String value) {
  var redacted = value.replaceAllMapped(
    _bearerCredential,
    (match) => '${match.group(1) ?? ''}Bearer [REDACTED]',
  );
  redacted = redacted.replaceAll(_windowsAbsolutePath, '<absolute-path>');
  return redacted.replaceAllMapped(
    _posixAbsolutePath,
    (match) => '${match.group(1) ?? ''}<absolute-path>',
  );
}

bool _secretLikeKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  return const [
    'password',
    'passwd',
    'secret',
    'token',
    'credential',
    'authorization',
    'apikey',
    'privatekey',
    'accesskey',
    'cookie',
    'sessionid',
    'idempotencykey',
  ].any(normalized.contains);
}

String _safeCode(String value) =>
    _safeCodePattern.hasMatch(value) ? value : 'internal.error';

final RegExp _safeCodePattern = RegExp(r'^[a-z][a-z0-9_.-]*$');
final RegExp _bearerCredential = RegExp(
  r'(^|\b)Bearer[ \t]+[a-zA-Z0-9._~+/=-]+',
  caseSensitive: false,
);
final RegExp _windowsAbsolutePath = RegExp(
  r'[a-zA-Z]:\\(?:[^\\\s]+\\)*[^\\\s,;)\]}]+',
);
final RegExp _posixAbsolutePath = RegExp(
  r'(^|[\s(=:])/(?!/)[^\s,;)\]}]+',
  multiLine: true,
);
~~~~~~~~

## `packages/map_authoring/lib/src/security/audit_record.dart`

~~~~~~~~dart
import '../contracts/action_descriptor.dart';
import 'authoring_permission.dart';
import 'output_redaction.dart';

enum AuthoringAuditDecision {
  denied('denied'),
  failed('failed'),
  succeeded('succeeded');

  const AuthoringAuditDecision(this.wireName);

  final String wireName;

  static AuthoringAuditDecision fromWireName(String value) {
    return AuthoringAuditDecision.values.firstWhere(
      (decision) => decision.wireName == value,
      orElse: () => throw const FormatException('Unknown audit decision.'),
    );
  }
}

final class AuthoringAuditRecord {
  AuthoringAuditRecord({
    required String auditId,
    required String actorId,
    required String projectId,
    required this.operation,
    required this.decision,
    required String requestId,
    required String actionId,
    required int actionVersion,
    required this.riskLevel,
    String? planId,
    String? receiptId,
    required String code,
    required DateTime timestamp,
    Map<String, Object?> details = const {},
    AuthoringOutputRedactor redactor = const AuthoringOutputRedactor(),
  })  : auditId = safeAuthoringSecurityIdentifier(auditId, 'auditId'),
        actorId = safeAuthoringSecurityIdentifier(actorId, 'actorId'),
        projectId = safeAuthoringSecurityIdentifier(projectId, 'projectId'),
        requestId = safeAuthoringSecurityIdentifier(requestId, 'requestId'),
        actionId = safeAuthoringSecurityIdentifier(actionId, 'actionId'),
        actionVersion = _positiveVersion(actionVersion),
        planId = planId == null
            ? null
            : safeAuthoringSecurityIdentifier(planId, 'planId'),
        receiptId = receiptId == null
            ? null
            : safeAuthoringSecurityIdentifier(receiptId, 'receiptId'),
        code = _safeCode(code),
        timestamp = timestamp.toUtc(),
        details = _redactedDetails(details, redactor);

  factory AuthoringAuditRecord.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'auditId',
      'actorId',
      'projectId',
      'operation',
      'decision',
      'requestId',
      'actionId',
      'actionVersion',
      'riskLevel',
      'planId',
      'receiptId',
      'code',
      'timestampUtc',
      'details',
    };
    if (json['schemaVersion'] != 1 ||
        json.keys.any((key) => !keys.contains(key)) ||
        json['details'] is! Map) {
      throw const FormatException('Invalid audit record schema.');
    }
    try {
      return AuthoringAuditRecord(
        auditId: _requiredString(json['auditId']),
        actorId: _requiredString(json['actorId']),
        projectId: _requiredString(json['projectId']),
        operation: AuthoringSecurityOperation.fromWireName(
          _requiredString(json['operation']),
        ),
        decision: AuthoringAuditDecision.fromWireName(
          _requiredString(json['decision']),
        ),
        requestId: _requiredString(json['requestId']),
        actionId: _requiredString(json['actionId']),
        actionVersion: _requiredInt(json['actionVersion']),
        riskLevel: AuthoringRiskLevel.fromWireName(
          _requiredString(json['riskLevel']),
        ),
        planId: _optionalString(json['planId']),
        receiptId: _optionalString(json['receiptId']),
        code: _requiredString(json['code']),
        timestamp: _requiredDate(json['timestampUtc']),
        details: Map<String, Object?>.from(json['details'] as Map),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String auditId;
  final String actorId;
  final String projectId;
  final AuthoringSecurityOperation operation;
  final AuthoringAuditDecision decision;
  final String requestId;
  final String actionId;
  final int actionVersion;
  final AuthoringRiskLevel riskLevel;
  final String? planId;
  final String? receiptId;
  final String code;
  final DateTime timestamp;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'auditId': auditId,
        'actorId': actorId,
        'projectId': projectId,
        'operation': operation.wireName,
        'decision': decision.wireName,
        'requestId': requestId,
        'actionId': actionId,
        'actionVersion': actionVersion,
        'riskLevel': riskLevel.wireName,
        if (planId != null) 'planId': planId,
        if (receiptId != null) 'receiptId': receiptId,
        'code': code,
        'timestampUtc': timestamp.toIso8601String(),
        'details': details,
      };
}

Map<String, Object?> _redactedDetails(
  Map<String, Object?> details,
  AuthoringOutputRedactor redactor,
) {
  final redacted = redactor.redact(details);
  if (redacted is! Map<String, Object?>) {
    throw ArgumentError.value(details, 'details', 'must be a JSON object');
  }
  return redacted;
}

String _safeCode(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_.-]*$').hasMatch(value)) {
    throw ArgumentError.value(value, 'code', 'must be a stable safe code');
  }
  return value;
}

String _requiredString(Object? value) {
  if (value is! String || value.isEmpty) throw const FormatException();
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  return _requiredString(value);
}

int _requiredInt(Object? value) {
  if (value is! int) throw const FormatException();
  return value;
}

DateTime _requiredDate(Object? value) {
  if (value is! String) throw const FormatException();
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) throw const FormatException();
  return parsed;
}

int _positiveVersion(int value) {
  if (value <= 0) {
    throw ArgumentError.value(value, 'actionVersion', 'must be positive');
  }
  return value;
}
~~~~~~~~

## `packages/map_authoring/lib/src/security/audit_log.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../support/authoring_fingerprint.dart';
import 'audit_record.dart';

final class AuthoringAuditLogException implements Exception {
  const AuthoringAuditLogException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringAuditLogException($code): $message';
}

abstract interface class AuthoringAuditLog {
  Future<void> append(AuthoringAuditRecord record);

  Future<List<AuthoringAuditRecord>> readAll();
}

/// Locked, flushed, hash-chained JSONL audit sink inside project metadata.
final class FileAuthoringAuditLog implements AuthoringAuditLog {
  FileAuthoringAuditLog._(this._projectRoot);

  static Future<FileAuthoringAuditLog> open(
      {required String projectRoot}) async {
    try {
      final directory = Directory(projectRoot);
      if ((await directory.stat()).type != FileSystemEntityType.directory) {
        throw const AuthoringAuditLogException(
          'audit.project_directory_required',
          'The audit project root is not a directory.',
        );
      }
      return FileAuthoringAuditLog._(await directory.resolveSymbolicLinks());
    } on AuthoringAuditLogException {
      rethrow;
    } on Object {
      throw const AuthoringAuditLogException(
        'audit.project_unavailable',
        'The audit project root is unavailable.',
      );
    }
  }

  final String _projectRoot;

  static final Map<String, Future<void>> _inProcessLocks = {};

  @override
  Future<void> append(AuthoringAuditRecord record) {
    return _guard(() async {
      await _withLock(() async {
        final file = await _auditFile();
        final events = await _readEvents(file);
        if (events.any((event) => event.record.auditId == record.auditId)) {
          throw const AuthoringAuditLogException(
            'audit.identity_conflict',
            'The audit identity is already present.',
          );
        }
        final previousDigest = events.isEmpty ? null : events.last.digest;
        final event = _AuditEvent(
          previousDigest: previousDigest,
          record: record,
          digest: _eventDigest(previousDigest, record),
        );
        final writer = await file.open(mode: FileMode.append);
        try {
          await writer.writeString('${jsonEncode(event.toJson())}\n');
          await writer.flush();
        } finally {
          await writer.close();
        }
      });
    });
  }

  @override
  Future<List<AuthoringAuditRecord>> readAll() {
    return _guard(() async {
      return _withLock(() async {
        final events = await _readEvents(await _auditFile());
        return List.unmodifiable(events.map((event) => event.record));
      });
    });
  }

  Future<T> _withLock<T>(Future<T> Function() operation) async {
    final previous = _inProcessLocks[_projectRoot] ?? Future<void>.value();
    final completion = Completer<void>();
    _inProcessLocks[_projectRoot] = completion.future;
    await previous;
    try {
      return await _withOsLock(operation);
    } finally {
      completion.complete();
      if (identical(_inProcessLocks[_projectRoot], completion.future)) {
        _inProcessLocks.remove(_projectRoot);
      }
    }
  }

  Future<T> _withOsLock<T>(Future<T> Function() operation) async {
    late final RandomAccessFile lock;
    try {
      final root = await _authoringRoot();
      lock = await File(_join(root.path, 'audit.lock')).open(
        mode: FileMode.append,
      );
      await lock.lock(FileLock.exclusive);
    } on AuthoringAuditLogException {
      rethrow;
    } on Object {
      throw const AuthoringAuditLogException(
        'audit.io',
        'The audit lock could not be acquired safely.',
      );
    }
    try {
      return await operation();
    } finally {
      try {
        await lock.unlock();
      } on Object {
        // Closing releases the OS lock even if explicit unlock fails.
      }
      await lock.close();
    }
  }

  Future<File> _auditFile() async {
    final file = File(_join((await _authoringRoot()).path, 'audit.jsonl'));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AuthoringAuditLogException(
        'audit.path_invalid',
        'The audit file is not a safe regular file.',
      );
    }
    return file;
  }

  Future<Directory> _authoringRoot() async {
    var current = Directory(_projectRoot);
    for (final segment in const ['.pokemap', 'authoring']) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        await next.create();
      } else if (type != FileSystemEntityType.directory) {
        throw const AuthoringAuditLogException(
          'audit.path_invalid',
          'The audit metadata directory is unsafe.',
        );
      }
      current = next;
    }
    return current;
  }

  Future<List<_AuditEvent>> _readEvents(File file) async {
    if (!await file.exists()) return const [];
    final content = await file.readAsString();
    if (content.isEmpty) return const [];
    final lines = content.split('\n');
    if (lines.last.isEmpty) lines.removeLast();
    if (lines.any((line) => line.isEmpty)) throw const FormatException();
    final events = <_AuditEvent>[];
    String? expectedPrevious;
    for (final line in lines) {
      final decoded = jsonDecode(line);
      if (decoded is! Map) throw const FormatException();
      final event = _AuditEvent.fromJson(Map<String, dynamic>.from(decoded));
      if (event.previousDigest != expectedPrevious ||
          event.digest != _eventDigest(expectedPrevious, event.record)) {
        throw const FormatException();
      }
      events.add(event);
      expectedPrevious = event.digest;
    }
    return events;
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthoringAuditLogException {
      rethrow;
    } on FormatException {
      throw const AuthoringAuditLogException(
        'audit.corrupt',
        'The audit log failed strict verification.',
      );
    } on Object {
      throw const AuthoringAuditLogException(
        'audit.io',
        'The audit log could not be accessed safely.',
      );
    }
  }
}

final class _AuditEvent {
  const _AuditEvent({
    required this.previousDigest,
    required this.record,
    required this.digest,
  });

  factory _AuditEvent.fromJson(Map<String, dynamic> json) {
    const keys = {'schemaVersion', 'previousDigest', 'record', 'digest'};
    final previous = json['previousDigest'];
    if (json['schemaVersion'] != 1 ||
        json.keys.any((key) => !keys.contains(key)) ||
        (previous != null && previous is! String) ||
        json['record'] is! Map ||
        json['digest'] is! String) {
      throw const FormatException();
    }
    return _AuditEvent(
      previousDigest: previous as String?,
      record: AuthoringAuditRecord.fromJson(
        Map<String, dynamic>.from(json['record'] as Map),
      ),
      digest: json['digest'] as String,
    );
  }

  final String? previousDigest;
  final AuthoringAuditRecord record;
  final String digest;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'previousDigest': previousDigest,
        'record': record.toJson(),
        'digest': digest,
      };
}

String _eventDigest(String? previousDigest, AuthoringAuditRecord record) {
  return computeAuthoringJsonFingerprint(
    {
      'schemaVersion': 1,
      'previousDigest': previousDigest,
      'record': record.toJson(),
    },
    logicalName: 'authoring-audit-event.json',
  );
}

String _join(String first, String second) =>
    [first, second].join(Platform.pathSeparator);
~~~~~~~~

## `packages/map_authoring/lib/src/security/secure_mutation_executor.dart`

~~~~~~~~dart
import 'dart:convert';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_receipt.dart';
import '../ports/idempotency_store.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/journaled_transaction.dart';
import 'audit_log.dart';
import 'audit_record.dart';
import 'authoring_permission.dart';
import 'authorization_policy.dart';
import 'confirmation_token.dart';
import 'output_redaction.dart';

/// Mandatory authorization and audit boundary around transaction apply.
final class SecureAuthoringMutationExecutor {
  const SecureAuthoringMutationExecutor({
    required JournaledAuthoringTransaction transaction,
    required AuthoringAuthorizationPolicy policy,
    required AuthoringAuditLog auditLog,
    required DateTime Function() clock,
    required String Function() auditIdFactory,
    AuthoringOutputRedactor redactor = const AuthoringOutputRedactor(),
  })  : _transaction = transaction,
        _policy = policy,
        _auditLog = auditLog,
        _clock = clock,
        _auditIdFactory = auditIdFactory,
        _redactor = redactor;

  final JournaledAuthoringTransaction _transaction;
  final AuthoringAuthorizationPolicy _policy;
  final AuthoringAuditLog _auditLog;
  final DateTime Function() _clock;
  final String Function() _auditIdFactory;
  final AuthoringOutputRedactor _redactor;

  Future<AuthoringReceipt> apply({
    required AuthoringActor actor,
    required String projectId,
    required AuthoringActionDescriptor action,
    required AuthoringPlan plan,
    required String currentProjectRevision,
    required AuthoringIdempotencyScope scope,
    required String operationId,
    AuthoringConfirmationToken? confirmationToken,
  }) async {
    late final AuthoringAuthorizationDecision authorization;
    try {
      _requireContextMatches(
        actor: actor,
        projectId: projectId,
        action: action,
        plan: plan,
        scope: scope,
      );
      final binding = AuthoringConfirmationBinding.forPlan(
        actorId: actor.actorId,
        projectId: projectId,
        plan: plan,
      );
      authorization = _policy.authorize(
        AuthoringAuthorizationRequest(
          actor: actor,
          projectId: projectId,
          operation: AuthoringSecurityOperation.apply,
          actionId: plan.request.actionId,
          actionVersion: plan.request.actionVersion,
          riskLevel: action.riskLevel,
          requestBytes: utf8
              .encode(
                canonicalAuthoringJson(plan.request.toJson()),
              )
              .length,
          touchedResources: plan.changeSet.changes.length,
          planId: plan.planId,
          diffFingerprint: binding.diffFingerprint,
          destructive: plan.changeSet.changes.any(
            (change) => change.beforeBytes != null,
          ),
          confirmationToken: confirmationToken,
          additionalPermissions:
              action.requiredPermissions.map(_securityPermissionForDescriptor),
        ),
      );
    } on Object catch (error, stackTrace) {
      await _appendAudit(
        actor: actor,
        projectId: projectId,
        action: action,
        plan: plan,
        decision: AuthoringAuditDecision.denied,
        error: error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    late final AuthoringReceipt receipt;
    try {
      receipt = await _transaction.apply(
        planId: plan.planId,
        request: plan.request,
        currentProjectRevision: currentProjectRevision,
        scope: scope,
        operationId: operationId,
      );
    } on Object catch (error, stackTrace) {
      await _appendAudit(
        actor: actor,
        projectId: projectId,
        action: action,
        plan: plan,
        decision: AuthoringAuditDecision.failed,
        error: error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    // Audit persistence is part of the secure boundary. If it fails after the
    // durable transaction commits, the caller receives the audit error and can
    // safely replay through the idempotency key without reapplying bytes.
    await _appendAudit(
      actor: actor,
      projectId: projectId,
      action: action,
      plan: plan,
      decision: AuthoringAuditDecision.succeeded,
      receipt: receipt,
      details: {
        'confirmationConsumed': authorization.confirmationConsumed,
        'requiredPermissions': [
          for (final permission in authorization.requiredPermissions)
            permission.wireName,
        ],
        'touchedResources': plan.changeSet.changes.length,
      },
    );
    return receipt;
  }

  Future<void> _appendAudit({
    required AuthoringActor actor,
    required String projectId,
    required AuthoringActionDescriptor action,
    required AuthoringPlan plan,
    required AuthoringAuditDecision decision,
    AuthoringReceipt? receipt,
    Object? error,
    Map<String, Object?> details = const {},
  }) {
    final safeError = error == null ? null : _redactor.redactError(error);
    return _auditLog.append(
      AuthoringAuditRecord(
        auditId: _auditIdFactory(),
        actorId: actor.actorId,
        projectId: projectId,
        operation: AuthoringSecurityOperation.apply,
        decision: decision,
        requestId: plan.request.requestId,
        actionId: plan.request.actionId,
        actionVersion: plan.request.actionVersion,
        riskLevel: action.riskLevel,
        planId: plan.planId,
        receiptId: receipt?.receiptId,
        code: safeError?.code ?? 'mutation.succeeded',
        timestamp: _clock().toUtc(),
        details: {
          ...details,
          if (safeError != null) 'error': safeError.toJson(),
        },
        redactor: _redactor,
      ),
    );
  }
}

void _requireContextMatches({
  required AuthoringActor actor,
  required String projectId,
  required AuthoringActionDescriptor action,
  required AuthoringPlan plan,
  required AuthoringIdempotencyScope scope,
}) {
  if (scope.actorId != actor.actorId ||
      scope.projectId != projectId ||
      scope.actionId != plan.request.actionId ||
      scope.actionVersion != plan.request.actionVersion ||
      action.id != plan.request.actionId ||
      action.version != plan.request.actionVersion) {
    throw const AuthoringAuthorizationException(
      code: 'authorization.context_mismatch',
      message: 'The actor, project, action, plan, and durable scope disagree.',
    );
  }
}

AuthoringPermissionScope _securityPermissionForDescriptor(
  AuthoringPermission permission,
) {
  return switch (permission) {
    AuthoringPermission.projectRead => AuthoringPermissionScope.projectRead,
    AuthoringPermission.projectWrite => AuthoringPermissionScope.projectWrite,
    AuthoringPermission.projectDestructive =>
      AuthoringPermissionScope.projectDestructive,
    AuthoringPermission.assetRead => AuthoringPermissionScope.assetRead,
    AuthoringPermission.assetWrite => AuthoringPermissionScope.assetWrite,
    AuthoringPermission.renderRun => AuthoringPermissionScope.renderRun,
    AuthoringPermission.playtestRun => AuthoringPermissionScope.playtestRun,
    AuthoringPermission.playtestControl =>
      AuthoringPermissionScope.playtestControl,
    AuthoringPermission.importRun => AuthoringPermissionScope.importRun,
    AuthoringPermission.exportRun => AuthoringPermissionScope.exportRun,
    AuthoringPermission.migrationRun => AuthoringPermissionScope.migrationRun,
    AuthoringPermission.networkExternal =>
      AuthoringPermissionScope.networkExternal,
    AuthoringPermission.processExecute =>
      AuthoringPermissionScope.processExecute,
    AuthoringPermission.secretUse => AuthoringPermissionScope.secretUse,
    AuthoringPermission.recoveryApply => AuthoringPermissionScope.recoveryApply,
  };
}
~~~~~~~~

## `packages/map_authoring/test/security/authorization_policy_test.dart`

~~~~~~~~dart
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringAuthorizationPolicy', () {
    late DateTime now;
    late AuthoringConfirmationStore confirmations;

    setUp(() {
      now = DateTime.utc(2026, 7, 31, 13);
      var token = 0;
      confirmations = AuthoringConfirmationStore(
        clock: () => now,
        tokenFactory: () => 'opaque-confirmation-${token++}',
      );
    });

    test('actors are read-only by default and writes cannot be indirect', () {
      final policy = _policy(confirmations, () => now);
      final actor = AuthoringActor(actorId: 'actor-default');

      expect(actor.permissions, [AuthoringPermissionScope.projectRead]);
      expect(
        policy
            .authorize(
              _request(
                  actor: actor, operation: AuthoringSecurityOperation.plan),
            )
            .requiredPermissions,
        [AuthoringPermissionScope.projectRead],
      );

      for (final operation in const [
        AuthoringSecurityOperation.apply,
        AuthoringSecurityOperation.recover,
        AuthoringSecurityOperation.assetWrite,
        AuthoringSecurityOperation.networkAccess,
      ]) {
        expect(
          () => policy.authorize(
            _request(actor: actor, operation: operation),
          ),
          _throwsAuthorization('authorization.permission_denied'),
        );
      }

      final noPermissions = AuthoringActor(
        actorId: 'actor-none',
        permissions: const [],
      );
      expect(
        () => policy.authorize(
          _request(
            actor: noPermissions,
            operation: AuthoringSecurityOperation.plan,
          ),
        ),
        _throwsAuthorization('authorization.permission_denied'),
      );
    });

    test('plan apply recovery asset and network scopes are independent', () {
      final policy = _policy(confirmations, () => now);
      const cases = {
        AuthoringSecurityOperation.plan: AuthoringPermissionScope.projectRead,
        AuthoringSecurityOperation.apply: AuthoringPermissionScope.projectWrite,
        AuthoringSecurityOperation.recover:
            AuthoringPermissionScope.recoveryApply,
        AuthoringSecurityOperation.assetWrite:
            AuthoringPermissionScope.assetWrite,
        AuthoringSecurityOperation.networkAccess:
            AuthoringPermissionScope.networkExternal,
      };

      for (final entry in cases.entries) {
        final actor = AuthoringActor(
          actorId: 'actor-${entry.key.name}',
          permissions: [entry.value],
        );
        expect(
          policy
              .authorize(
                _request(actor: actor, operation: entry.key),
              )
              .requiredPermissions,
          [entry.value],
        );
        for (final other in cases.keys.where((item) => item != entry.key)) {
          expect(
            () => policy.authorize(
              _request(actor: actor, operation: other),
            ),
            _throwsAuthorization('authorization.permission_denied'),
          );
        }
      }
    });

    test('action descriptor permissions cover the canonical catalog scopes',
        () {
      expect(
        AuthoringPermission.values.map((permission) => permission.wireName),
        AuthoringPermissionScope.values.map((scope) => scope.wireName),
      );
      expect(
        AuthoringPermission.fromWireName('render'),
        AuthoringPermission.renderRun,
      );
      expect(
        AuthoringPermission.fromWireName('playtest'),
        AuthoringPermission.playtestRun,
      );
      expect(
        AuthoringPermission.fromWireName('recovery'),
        AuthoringPermission.recoveryApply,
      );
    });

    test('high risk destructive apply needs scope and bound one-use token', () {
      final policy = _policy(confirmations, () => now);
      final writer = AuthoringActor(
        actorId: 'actor-confirm',
        permissions: const [AuthoringPermissionScope.projectWrite],
      );
      expect(
        () => policy.authorize(
          _request(
            actor: writer,
            operation: AuthoringSecurityOperation.apply,
            riskLevel: AuthoringRiskLevel.high,
            destructive: true,
          ),
        ),
        _throwsAuthorization('authorization.permission_denied'),
      );

      final destructiveWriter = AuthoringActor(
        actorId: 'actor-confirm',
        permissions: const [
          AuthoringPermissionScope.projectWrite,
          AuthoringPermissionScope.projectDestructive,
        ],
      );
      expect(
        () => policy.authorize(
          _request(
            actor: destructiveWriter,
            operation: AuthoringSecurityOperation.apply,
            riskLevel: AuthoringRiskLevel.high,
            destructive: true,
          ),
        ),
        _throwsAuthorization('confirmation.required'),
      );

      final binding = _binding(actorId: destructiveWriter.actorId);
      final token = confirmations.issue(binding);
      final transported = AuthoringConfirmationToken.fromWireValue(
        token.wireValue,
      );
      final decision = policy.authorize(
        _request(
          actor: destructiveWriter,
          operation: AuthoringSecurityOperation.apply,
          riskLevel: AuthoringRiskLevel.high,
          destructive: true,
          confirmationToken: transported,
        ),
      );
      expect(decision.confirmationConsumed, isTrue);
      expect(token.toString(), '[REDACTED]');
      expect(
        () => policy.authorize(
          _request(
            actor: destructiveWriter,
            operation: AuthoringSecurityOperation.apply,
            riskLevel: AuthoringRiskLevel.high,
            destructive: true,
            confirmationToken: token,
          ),
        ),
        _throwsAuthorization('confirmation.used'),
      );
    });

    test('confirmation refuses another plan and expires without leaking token',
        () {
      final policy = _policy(confirmations, () => now);
      final actor = AuthoringActor(
        actorId: 'actor-confirm',
        permissions: const [
          AuthoringPermissionScope.projectWrite,
          AuthoringPermissionScope.projectDestructive,
        ],
      );
      final token = confirmations.issue(_binding(actorId: actor.actorId));

      expect(
        () => policy.authorize(
          _request(
            actor: actor,
            operation: AuthoringSecurityOperation.apply,
            riskLevel: AuthoringRiskLevel.critical,
            destructive: true,
            planId: 'plan-other',
            confirmationToken: token,
          ),
        ),
        _throwsAuthorization('confirmation.binding_mismatch'),
      );

      policy.authorize(
        _request(
          actor: actor,
          operation: AuthoringSecurityOperation.apply,
          riskLevel: AuthoringRiskLevel.critical,
          destructive: true,
          confirmationToken: token,
        ),
      );

      final expired = confirmations.issue(_binding(actorId: actor.actorId));
      now = now.add(const Duration(minutes: 6));
      expect(
        () => policy.authorize(
          _request(
            actor: actor,
            operation: AuthoringSecurityOperation.apply,
            riskLevel: AuthoringRiskLevel.high,
            destructive: true,
            confirmationToken: expired,
          ),
        ),
        _throwsAuthorization('confirmation.expired'),
      );
    });

    test('request resource and rate limits are deterministic', () {
      final policy = AuthoringAuthorizationPolicy(
        confirmations: confirmations,
        clock: () => now,
        limits: const AuthoringSecurityLimits(
          maxRequestBytes: 32,
          maxTouchedResources: 2,
          maxOperationsPerWindow: 2,
          rateWindow: Duration(minutes: 1),
        ),
      );
      final actor = AuthoringActor(
        actorId: 'actor-limits',
        permissions: const [AuthoringPermissionScope.projectWrite],
      );

      expect(
        () => policy.authorize(
          _request(
            actor: actor,
            operation: AuthoringSecurityOperation.apply,
            requestBytes: 33,
          ),
        ),
        _throwsAuthorization('authorization.request_too_large'),
      );
      expect(
        () => policy.authorize(
          _request(
            actor: actor,
            operation: AuthoringSecurityOperation.apply,
            touchedResources: 3,
          ),
        ),
        _throwsAuthorization('authorization.too_many_resources'),
      );

      policy.authorize(
        _request(actor: actor, operation: AuthoringSecurityOperation.apply),
      );
      policy.authorize(
        _request(actor: actor, operation: AuthoringSecurityOperation.apply),
      );
      expect(
        () => policy.authorize(
          _request(actor: actor, operation: AuthoringSecurityOperation.apply),
        ),
        _throwsAuthorization('authorization.rate_limited'),
      );

      now = now.add(const Duration(minutes: 1));
      expect(
        policy.authorize(
          _request(actor: actor, operation: AuthoringSecurityOperation.apply),
        ),
        isA<AuthoringAuthorizationDecision>(),
      );
    });
  });
}

AuthoringAuthorizationPolicy _policy(
  AuthoringConfirmationStore confirmations,
  DateTime Function() clock,
) {
  return AuthoringAuthorizationPolicy(
    confirmations: confirmations,
    clock: clock,
  );
}

AuthoringAuthorizationRequest _request({
  required AuthoringActor actor,
  required AuthoringSecurityOperation operation,
  AuthoringRiskLevel riskLevel = AuthoringRiskLevel.low,
  bool destructive = false,
  int requestBytes = 16,
  int touchedResources = 1,
  String planId = 'plan-confirm',
  AuthoringConfirmationToken? confirmationToken,
}) {
  return AuthoringAuthorizationRequest(
    actor: actor,
    projectId: 'project-confirm',
    operation: operation,
    actionId: 'fixture.secure',
    actionVersion: 1,
    riskLevel: riskLevel,
    requestBytes: requestBytes,
    touchedResources: touchedResources,
    planId: planId,
    diffFingerprint:
        'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    destructive: destructive,
    confirmationToken: confirmationToken,
  );
}

AuthoringConfirmationBinding _binding({required String actorId}) {
  return AuthoringConfirmationBinding(
    actorId: actorId,
    projectId: 'project-confirm',
    actionId: 'fixture.secure',
    actionVersion: 1,
    planId: 'plan-confirm',
    diffFingerprint:
        'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  );
}

Matcher _throwsAuthorization(String code) {
  return throwsA(
    isA<AuthoringAuthorizationException>().having(
      (error) => error.code,
      'code',
      code,
    ),
  );
}
~~~~~~~~

## `packages/map_authoring/test/security/output_redaction_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringOutputRedactor', () {
    const redactor = AuthoringOutputRedactor();

    test('recursively removes secret fields credentials and absolute paths',
        () {
      final redacted = redactor.redact({
        'name': 'safe',
        'password': 'super-secret',
        'nested': [
          {
            'apiToken': 'token-value',
            'message': 'Authorization: Bearer abc.def.ghi',
          },
          'read /Users/alice/private/project.json before retrying',
          r'failure at C:\Users\alice\project\main.dart:42',
        ],
        'relativePath': 'maps/route_01.json',
        'url': 'https://example.invalid/v1/maps',
        'jsonPath': r'$.events[0].commands',
      });
      final encoded = jsonEncode(redacted);

      expect(encoded, isNot(contains('super-secret')));
      expect(encoded, isNot(contains('token-value')));
      expect(encoded, isNot(contains('abc.def.ghi')));
      expect(encoded, isNot(contains('/Users/alice')));
      expect(encoded, isNot(contains(r'C:\Users\alice')));
      expect(encoded, contains('[REDACTED]'));
      expect(encoded, contains('<absolute-path>'));
      expect(encoded, contains('maps/route_01.json'));
      expect(encoded, contains('https://example.invalid/v1/maps'));
      expect(encoded, contains(r'$.events[0].commands'));
    });

    test('maps internal exceptions to stable path-free public errors', () {
      final safe = redactor.redactError(
        StateError(
          'database password=hunter2 failed at '
          '/private/tmp/pokemap/internal.dart:9',
        ),
      );
      final encoded = jsonEncode(safe.toJson());

      expect(safe.code, 'internal.error');
      expect(safe.message, 'The operation failed safely.');
      expect(encoded, isNot(contains('hunter2')));
      expect(encoded, isNot(contains('/private/tmp')));
      expect(encoded, isNot(contains('StateError')));
    });

    test('preserves a stable safe error code without copying raw messages', () {
      const error = AuthoringAuthorizationException(
        code: 'authorization.permission_denied',
        message: 'unsafe detail /Users/alice/project',
      );
      final safe = redactor.redactError(error);

      expect(safe.code, 'authorization.permission_denied');
      expect(safe.message, 'The operation was denied safely.');
      expect(jsonEncode(safe.toJson()), isNot(contains('/Users/alice')));
    });
  });
}
~~~~~~~~

## `packages/map_authoring/test/security/audit_log_test.dart`

~~~~~~~~dart
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/transaction_test_fixture.dart';

void main() {
  group('FileAuthoringAuditLog', () {
    test('append-only redacted records survive reopen with a valid hash chain',
        () async {
      final project = await Directory.systemTemp.createTemp('pokemap_audit_');
      addTearDown(() => project.delete(recursive: true));
      final log = await FileAuthoringAuditLog.open(projectRoot: project.path);

      await log.append(
        _record(
          id: 'audit-1',
          decision: AuthoringAuditDecision.denied,
          details: {
            'password': 'super-secret',
            'error': 'Bearer abc.def at /Users/alice/private/file.json',
          },
        ),
      );
      await log.append(
        _record(
          id: 'audit-2',
          decision: AuthoringAuditDecision.succeeded,
          receiptId: 'receipt-1',
          details: {r'windowsPath': r'C:\Users\alice\secret.txt'},
        ),
      );

      final reopened = await FileAuthoringAuditLog.open(
        projectRoot: project.path,
      );
      final records = await reopened.readAll();
      expect(records.map((record) => record.auditId), ['audit-1', 'audit-2']);
      expect(records.last.receiptId, 'receipt-1');

      final raw = await File(
        _join(project.path, '.pokemap', 'authoring', 'audit.jsonl'),
      ).readAsString();
      expect(raw, isNot(contains('super-secret')));
      expect(raw, isNot(contains('abc.def')));
      expect(raw, isNot(contains('/Users/alice')));
      expect(raw, isNot(contains(r'C:\Users\alice')));
      expect(raw, contains('[REDACTED]'));
      expect(raw, contains('<absolute-path>'));
    });

    test('concurrent instances serialize unique appends without lost records',
        () async {
      final project = await Directory.systemTemp.createTemp('pokemap_audit_');
      addTearDown(() => project.delete(recursive: true));
      final first = await FileAuthoringAuditLog.open(projectRoot: project.path);
      final second =
          await FileAuthoringAuditLog.open(projectRoot: project.path);

      await Future.wait([
        for (var index = 0; index < 12; index++)
          (index.isEven ? first : second).append(
            _record(
              id: 'audit-concurrent-$index',
              decision: AuthoringAuditDecision.succeeded,
            ),
          ),
      ]);

      final records = await first.readAll();
      expect(records, hasLength(12));
      expect(records.map((record) => record.auditId).toSet(), hasLength(12));
    });

    test('corrupt audit events fail closed with a path-free error', () async {
      final project = await Directory.systemTemp.createTemp('pokemap_audit_');
      addTearDown(() => project.delete(recursive: true));
      final log = await FileAuthoringAuditLog.open(projectRoot: project.path);
      await log.append(
        _record(
          id: 'audit-before-corruption',
          decision: AuthoringAuditDecision.succeeded,
        ),
      );
      await File(
        _join(project.path, '.pokemap', 'authoring', 'audit.jsonl'),
      ).writeAsString('{"corrupt":true}\n', mode: FileMode.append);

      await expectLater(
        log.readAll,
        throwsA(
          isA<AuthoringAuditLogException>()
              .having((error) => error.code, 'code', 'audit.corrupt')
              .having(
                (error) => error.toString(),
                'public error',
                isNot(contains(project.path)),
              ),
        ),
      );
    });
  });

  group('SecureAuthoringMutationExecutor', () {
    test('audits denied failed and successful attempts and writes only last',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final log = await FileAuthoringAuditLog.open(
        projectRoot: harness.projectDirectory.path,
      );
      var auditId = 0;
      final executor = SecureAuthoringMutationExecutor(
        transaction: harness.transaction,
        policy: AuthoringAuthorizationPolicy(
          confirmations: AuthoringConfirmationStore(clock: () => harness.now),
          clock: () => harness.now,
        ),
        auditLog: log,
        clock: () => harness.now,
        auditIdFactory: () => 'audit-executor-${auditId++}',
      );
      final action = _action(riskLevel: AuthoringRiskLevel.low);
      final readOnly = AuthoringActor(actorId: harness.scope.actorId);

      await expectLater(
        () => executor.apply(
          actor: readOnly,
          projectId: harness.scope.projectId,
          action: action,
          plan: harness.plan,
          currentProjectRevision: harness.currentProjectRevision,
          scope: harness.scope,
          operationId: harness.operationId,
        ),
        throwsA(isA<AuthoringAuthorizationException>()),
      );
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readJournal(), isNull);

      final writer = AuthoringActor(
        actorId: harness.scope.actorId,
        permissions: const [AuthoringPermissionScope.projectWrite],
      );
      await expectLater(
        () => executor.apply(
          actor: writer,
          projectId: harness.scope.projectId,
          action: action,
          plan: harness.plan,
          currentProjectRevision:
              'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          scope: harness.scope,
          operationId: harness.operationId,
        ),
        throwsA(isA<AuthoringPlanException>()),
      );
      expect(await harness.readA(), TransactionTestHarness.beforeA);
      expect(await harness.readJournal(), isNull);

      final receipt = await executor.apply(
        actor: writer,
        projectId: harness.scope.projectId,
        action: action,
        plan: harness.plan,
        currentProjectRevision: harness.currentProjectRevision,
        scope: harness.scope,
        operationId: harness.operationId,
      );
      expect(await harness.readA(), TransactionTestHarness.afterA);

      final records = await log.readAll();
      expect(
        records.map((record) => record.decision),
        [
          AuthoringAuditDecision.denied,
          AuthoringAuditDecision.failed,
          AuthoringAuditDecision.succeeded,
        ],
      );
      expect(
          records.every((record) => record.actorId == writer.actorId), isTrue);
      expect(
          records.every(
              (record) => record.requestId == harness.plan.request.requestId),
          isTrue);
      expect(records.every((record) => record.planId == harness.plan.planId),
          isTrue);
      expect(records.last.receiptId, receipt.receiptId);
      expect(records.last.riskLevel, AuthoringRiskLevel.low);
    });

    test('size resource and rate limits fail before transaction artifacts',
        () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final log = await FileAuthoringAuditLog.open(
        projectRoot: harness.projectDirectory.path,
      );
      var auditId = 0;
      final writer = AuthoringActor(
        actorId: harness.scope.actorId,
        permissions: const [AuthoringPermissionScope.projectWrite],
      );
      final action = _action(riskLevel: AuthoringRiskLevel.low);

      SecureAuthoringMutationExecutor executor(
        AuthoringAuthorizationPolicy policy,
      ) {
        return SecureAuthoringMutationExecutor(
          transaction: harness.transaction,
          policy: policy,
          auditLog: log,
          clock: () => harness.now,
          auditIdFactory: () => 'audit-limit-${auditId++}',
        );
      }

      Future<void> expectDenied(
        AuthoringAuthorizationPolicy policy,
        String code,
      ) async {
        await expectLater(
          () => executor(policy).apply(
            actor: writer,
            projectId: harness.scope.projectId,
            action: action,
            plan: harness.plan,
            currentProjectRevision: harness.currentProjectRevision,
            scope: harness.scope,
            operationId: harness.operationId,
          ),
          throwsA(
            isA<AuthoringAuthorizationException>().having(
              (error) => error.code,
              'code',
              code,
            ),
          ),
        );
        expect(await harness.readA(), TransactionTestHarness.beforeA);
        expect(await harness.readJournal(), isNull);
      }

      await expectDenied(
        AuthoringAuthorizationPolicy(
          confirmations: AuthoringConfirmationStore(clock: () => harness.now),
          clock: () => harness.now,
          limits: const AuthoringSecurityLimits(maxRequestBytes: 1),
        ),
        'authorization.request_too_large',
      );
      await expectDenied(
        AuthoringAuthorizationPolicy(
          confirmations: AuthoringConfirmationStore(clock: () => harness.now),
          clock: () => harness.now,
          limits: const AuthoringSecurityLimits(maxTouchedResources: 3),
        ),
        'authorization.too_many_resources',
      );

      final ratePolicy = AuthoringAuthorizationPolicy(
        confirmations: AuthoringConfirmationStore(clock: () => harness.now),
        clock: () => harness.now,
        limits: const AuthoringSecurityLimits(maxOperationsPerWindow: 1),
      );
      ratePolicy.authorize(
        AuthoringAuthorizationRequest(
          actor: writer,
          projectId: harness.scope.projectId,
          operation: AuthoringSecurityOperation.apply,
          actionId: harness.plan.request.actionId,
          actionVersion: harness.plan.request.actionVersion,
          riskLevel: AuthoringRiskLevel.low,
          requestBytes: 0,
          touchedResources: 0,
        ),
      );
      await expectDenied(ratePolicy, 'authorization.rate_limited');

      expect(
        (await log.readAll()).map((record) => record.decision),
        [
          AuthoringAuditDecision.denied,
          AuthoringAuditDecision.denied,
          AuthoringAuditDecision.denied,
        ],
      );
    });

    test('high-risk apply consumes the exact plan confirmation', () async {
      final harness = await TransactionTestHarness.create();
      addTearDown(harness.dispose);
      final log = await FileAuthoringAuditLog.open(
        projectRoot: harness.projectDirectory.path,
      );
      var tokenId = 0;
      final confirmations = AuthoringConfirmationStore(
        clock: () => harness.now,
        tokenFactory: () => 'secure-token-${tokenId++}',
      );
      var auditId = 0;
      final executor = SecureAuthoringMutationExecutor(
        transaction: harness.transaction,
        policy: AuthoringAuthorizationPolicy(
          confirmations: confirmations,
          clock: () => harness.now,
        ),
        auditLog: log,
        clock: () => harness.now,
        auditIdFactory: () => 'audit-confirm-${auditId++}',
      );
      final actor = AuthoringActor(
        actorId: harness.scope.actorId,
        permissions: const [
          AuthoringPermissionScope.projectWrite,
          AuthoringPermissionScope.projectDestructive,
        ],
      );
      final action = _action(riskLevel: AuthoringRiskLevel.high);

      await expectLater(
        () => executor.apply(
          actor: actor,
          projectId: harness.scope.projectId,
          action: action,
          plan: harness.plan,
          currentProjectRevision: harness.currentProjectRevision,
          scope: harness.scope,
          operationId: harness.operationId,
        ),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'confirmation.required',
          ),
        ),
      );
      expect(await harness.readJournal(), isNull);

      final confirmation = confirmations.issue(
        AuthoringConfirmationBinding.forPlan(
          actorId: actor.actorId,
          projectId: harness.scope.projectId,
          plan: harness.plan,
        ),
      );
      final receipt = await executor.apply(
        actor: actor,
        projectId: harness.scope.projectId,
        action: action,
        plan: harness.plan,
        currentProjectRevision: harness.currentProjectRevision,
        scope: harness.scope,
        operationId: harness.operationId,
        confirmationToken: confirmation,
      );
      expect(receipt.status, AuthoringReceiptStatus.applied);
      expect(await harness.readA(), TransactionTestHarness.afterA);
      expect(
        (await log.readAll()).map((record) => record.decision),
        [AuthoringAuditDecision.denied, AuthoringAuditDecision.succeeded],
      );
    });
  });
}

AuthoringAuditRecord _record({
  required String id,
  required AuthoringAuditDecision decision,
  String? receiptId,
  Map<String, Object?> details = const {},
}) {
  return AuthoringAuditRecord(
    auditId: id,
    actorId: 'actor-audit',
    projectId: 'project-audit',
    operation: AuthoringSecurityOperation.apply,
    decision: decision,
    requestId: 'request-audit',
    actionId: 'fixture.secure',
    actionVersion: 1,
    riskLevel: AuthoringRiskLevel.low,
    planId: 'plan-audit',
    receiptId: receiptId,
    code: decision == AuthoringAuditDecision.succeeded
        ? 'mutation.succeeded'
        : 'authorization.permission_denied',
    timestamp: DateTime.utc(2026, 7, 31, 13),
    details: details,
  );
}

AuthoringActionDescriptor _action({
  required AuthoringRiskLevel riskLevel,
}) {
  return AuthoringActionDescriptor(
    id: 'fixture.multiWrite',
    version: 1,
    summary: 'Secure transaction fixture',
    inputSchemaId: 'schema.fixture.input.v1',
    outputSchemaId: 'schema.fixture.output.v1',
    riskLevel: riskLevel,
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
    ],
  );
}

String _join(String first, String second, String third, String fourth) =>
    [first, second, third, fourth].join(Platform.pathSeparator);
~~~~~~~~

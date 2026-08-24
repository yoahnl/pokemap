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
        assert(maxOperationsPerWindow == null || maxOperationsPerWindow > 0);

  final int maxRequestBytes;
  final int maxTouchedResources;

  /// Operations allowed per [rateWindow], or `null` for an unmetered actor.
  ///
  /// The window guards remote clients of the exposed authoring surface. A
  /// local session whose actor is the person at the keyboard sets it to `null`.
  final int? maxOperationsPerWindow;
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
    final maxOperations = limits.maxOperationsPerWindow;
    if (limits.maxRequestBytes <= 0 ||
        limits.maxTouchedResources <= 0 ||
        (maxOperations != null && maxOperations <= 0) ||
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
    final maxOperations = limits.maxOperationsPerWindow;
    if (maxOperations == null) return;
    final now = _clock().toUtc();
    final cutoff = now.subtract(limits.rateWindow);
    final key = [
      request.actor.actorId,
      request.projectId,
      request.operation.wireName,
    ].join('\u0000');
    final events = _rateBuckets.putIfAbsent(key, () => <DateTime>[])
      ..removeWhere((timestamp) => !timestamp.isAfter(cutoff));
    if (events.length >= maxOperations) {
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

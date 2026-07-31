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

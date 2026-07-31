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

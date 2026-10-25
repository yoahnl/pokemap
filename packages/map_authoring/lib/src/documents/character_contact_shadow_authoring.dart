import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:map_core/map_core.dart';

import '../contracts/action_descriptor.dart';
import '../contracts/authoring_diff.dart';
import '../contracts/authoring_receipt.dart';
import '../contracts/authoring_request.dart';
import '../contracts/resource_ref.dart';
import '../history/content_blob_store.dart';
import '../history/file_history_store.dart';
import '../history/history_store.dart';
import '../ports/idempotency_store.dart';
import '../ports/project_file_reader.dart';
import '../security/audit_log.dart';
import '../security/audit_record.dart';
import '../security/authoring_permission.dart';
import '../security/authorization_policy.dart';
import '../security/confirmation_token.dart';
import '../security/secure_mutation_executor.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/change_set.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/idempotency_ledger.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/local_transaction_file_gateway.dart';
import '../transactions/plan_store.dart';
import '../transactions/recovery_service.dart';
import '../transactions/transaction_journal.dart';
import '../workspace/workspace_policy.dart';

final class CharacterContactShadowMutation {
  const CharacterContactShadowMutation(
      {required this.beforeRevision,
      required this.afterRevision,
      required this.beforeValue,
      required this.afterValue,
      required this.receipt});
  final String beforeRevision;
  final String afterRevision;
  final bool? beforeValue;
  final bool? afterValue;
  final AuthoringReceipt receipt;

  Map<String, Object?> toJson() => {
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'beforeValue': beforeValue,
        'afterValue': afterValue,
        'receipt': receipt.toJson()
      };

  factory CharacterContactShadowMutation.fromReceipt(AuthoringReceipt receipt) {
    final diff = receipt.diff.entries.single;
    return CharacterContactShadowMutation(
        beforeRevision: diff.extensions['documentBeforeRevision']! as String,
        afterRevision: diff.extensions['documentAfterRevision']! as String,
        beforeValue: diff.before as bool?,
        afterValue: diff.after as bool?,
        receipt: receipt);
  }
}

final class LocalCharacterContactShadowAuthoring {
  LocalCharacterContactShadowAuthoring(
      {required WorkspacePolicy policy,
      ProjectFileReader? reader,
      AuthoringActor? actor,
      AuthoringTransactionFaultInjector? faultInjector})
      : _policy = policy,
        _reader = reader ?? const LocalProjectFileReader(),
        _actor = actor ??
            AuthoringActor(actorId: 'local_cli', permissions: const [
              AuthoringPermissionScope.projectRead,
              AuthoringPermissionScope.projectWrite,
              AuthoringPermissionScope.recoveryApply
            ]),
        _faultInjector = faultInjector;

  final WorkspacePolicy _policy;
  final ProjectFileReader _reader;
  final AuthoringActor _actor;
  final AuthoringTransactionFaultInjector? _faultInjector;

  static final descriptor = AuthoringActionDescriptor(
      id: 'characterStudio.contactShadow.set',
      version: 1,
      summary:
          'Set or inherit one character contact shadow without loading the project',
      inputSchemaId:
          'pokemap.authoring.characterStudio.contactShadow.set.input.v1',
      outputSchemaId:
          'pokemap.authoring.characterStudio.contactShadow.set.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const [
        'characterStudioCharacter'
      ],
      requiredPermissions: const [
        AuthoringPermission.projectWrite
      ],
      guarantees: const [
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable
      ],
      extensions: const {
        'revisionScope': 'projectDocument',
        'storageKeys': ['project.json'],
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['characterId', 'enabled'],
          'properties': {
            'characterId': {'type': 'string'},
            'enabled': {
              'type': ['boolean', 'null']
            }
          }
        }
      });

  Future<Map<String, Object?>> inspect(
      {required String projectRoot, required String characterId}) async {
    _requireRead();
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final bytes = await _reader.readBytes(
        projectRoot: root, relativePath: 'project.json');
    final raw = _decode(bytes);
    final character = _character(raw, characterId);
    final value = _value(character);
    final settings = raw['settings'];
    return {
      'revision': narrativeEventBytesFingerprint(bytes),
      'characterId': characterId,
      'contactShadow': value,
      'effectiveContactShadow': value ??
          (settings is Map && settings['actorContactShadowsByDefault'] == true)
    };
  }

  Future<CharacterContactShadowMutation> set(
      {required String projectRoot,
      required String expectedRevision,
      required String characterId,
      required bool? enabled,
      required String operationId,
      FutureOr<void> Function()? precondition}) async {
    _requireRead();
    if (!_actor.allows(AuthoringPermissionScope.projectWrite)) {
      throw const FormatException('project.write permission is required.');
    }
    safeAuthoringSecurityIdentifier(operationId, 'operationId');
    final root = await _policy.authorizeProjectRoot(projectRoot);
    final projectId =
        'local_project_${computeAuthoringJsonFingerprint(root, logicalName: 'local-project-root.json').substring(7)}';
    final request = AuthoringRequest(
        requestId: operationId,
        actionId: descriptor.id,
        actionVersion: 1,
        workspaceHandle: projectId,
        parameters: {'characterId': characterId, 'enabled': enabled},
        expectedRevision: expectedRevision,
        idempotencyKey: operationId);
    final scope = AuthoringIdempotencyScope(
        actorId: _actor.actorId,
        projectId: projectId,
        actionId: descriptor.id,
        actionVersion: 1,
        key: operationId);
    final store = await FileIdempotencyStore.forScope(
        filePath: '$root/.pokemap/authoring/idempotency.jsonl', scope: scope);
    final ledger = AuthoringIdempotencyLedger(store: store);
    final gateway = await LocalTransactionFileGateway.open(projectRoot: root, expectedProjectRoot: root);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: root, incrementalWrites: true);
    final recorder = AuthoringHistoryRecorder(
        store: history,
        blobs: await FileAuthoringContentBlobStore.open(projectRoot: root));
    final existing = await store.read(scope);
    if (existing != null) {
      if (existing.payloadFingerprint !=
              computeAuthoringIdempotencyPayloadFingerprint(request) ||
          existing.operationId != operationId) {
        throw AuthoringIdempotencyException(
            code: 'idempotency.payload_conflict',
            message:
                'This operation already owns a different character mutation.');
      }
      if (existing.status == AuthoringIdempotencyStatus.completed) {
        return _finishReplay(root, projectId, request, scope, ledger, gateway,
            existing.receipt!, recovered: false);
      }
      if (!_actor.allows(AuthoringPermissionScope.recoveryApply)) {
        throw const FormatException('recovery.apply permission is required.');
      }
      final recovered = await AuthoringRecoveryService(
              gateway: gateway,
              idempotency: ledger,
              clock: DateTime.now,
              commitHook: recorder)
          .resume(operationId);
      return _finishReplay(root, projectId, request, scope, ledger, gateway,
          recovered, recovered: true);
    }
    final bytes = await _reader.readBytes(
        projectRoot: root, relativePath: 'project.json');
    if (narrativeEventBytesFingerprint(bytes) != expectedRevision) {
      throw const FormatException(
          'project.document_revision_conflict: The project changed before this edit.');
    }
    final raw = _decode(bytes);
    final character = _character(raw, characterId);
    final before = _value(character);
    if (enabled == null) {
      character.remove('contactShadow');
    } else {
      character['contactShadow'] = enabled;
    }
    final afterBytes = utf8.encode(jsonEncode(raw));
    final afterRevision = narrativeEventBytesFingerprint(afterBytes);
    final resource = AuthoringResourceRef(kind: 'project', id: projectId);
    final diff = AuthoringDiff([
      AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: '/characters/$characterId/contactShadow',
          before: before,
          after: enabled,
          extensions: {
            'documentBeforeRevision': expectedRevision,
            'documentAfterRevision': afterRevision
          })
    ]);
    final plans = AuthoringPlanStore();
    final plan = AuthoringPlan(
        planId: _identity('plan_document_'),
        receiptId: _identity('receipt_document_'),
        request: request,
        baseRevision: expectedRevision,
        seed: 0,
        createdAt: plans.now,
        expiresAt: plans.now.add(plans.ttl),
        changeSet: AuthoringChangeSet(changes: [
          AuthoringResourceChange(
              resource: resource,
              storageKey: 'project.json',
              beforeBytes: bytes,
              afterBytes: afterBytes)
        ], diff: diff));
    plans.save(plan);
    final transaction = JournaledAuthoringTransaction(
        plans: plans,
        gateway: gateway,
        idempotency: ledger,
        clock: DateTime.now,
        commitHook: recorder,
        faultInjector: _faultInjector);
    final authorization = AuthoringAuthorizationPolicy(
        confirmations: AuthoringConfirmationStore(clock: DateTime.now),
        clock: DateTime.now);
    final executor = SecureAuthoringMutationExecutor(
        transaction: transaction,
        policy: authorization,
        auditLog: await FileAuthoringAuditLog.open(
            projectRoot: root, incrementalWrites: true),
        clock: DateTime.now,
        auditIdFactory: () => _identity('audit_document_'));
    try {
      final receipt = await executor.apply(
          actor: _actor,
          projectId: projectId,
          action: descriptor,
          plan: plan,
          currentProjectRevision: expectedRevision,
          scope: scope,
          operationId: operationId,
          precondition: () async {
            await precondition?.call();
            for (final journal in await gateway.listJournals()) {
              if (journal.operationId != operationId &&
                  journal.status != AuthoringTransactionStatus.committed &&
                  journal.status != AuthoringTransactionStatus.compensated) {
                throw const FormatException(
                    'project.recovery_required: Recover the interrupted operation before editing.');
              }
            }
          });
      return CharacterContactShadowMutation.fromReceipt(receipt);
    } finally {
      await plan.releaseAppliedPayload();
    }
  }

  Future<CharacterContactShadowMutation> _finishReplay(
      String root,
      String projectId,
      AuthoringRequest request,
      AuthoringIdempotencyScope scope,
      AuthoringIdempotencyLedger ledger,
      LocalTransactionFileGateway gateway,
      AuthoringReceipt receipt,
      {required bool recovered}) async {
    final planId = receipt.extensions['planId'];
    if (receipt.actionId != descriptor.id ||
        receipt.actionVersion != descriptor.version ||
        receipt.requestId != request.requestId ||
        receipt.status == AuthoringReceiptStatus.planned ||
        receipt.extensions['operationId'] != request.requestId ||
        planId is! String ||
        !RegExp(r'^plan_document_[a-f0-9]{32}$').hasMatch(planId) ||
        !RegExp(r'^receipt_document_[a-f0-9]{32}$').hasMatch(receipt.receiptId) ||
        receipt.diff.entries.length != 1) {
      throw const FormatException('The replay receipt does not match its mutation intent.');
    }
    final diff = receipt.diff.entries.single;
    final afterRevision = diff.extensions['documentAfterRevision'];
    if (diff.resource.kind != 'project' ||
        diff.resource.id != projectId ||
        diff.operation != AuthoringDiffOperation.replace ||
        diff.path != '/characters/${request.parameters['characterId']}/contactShadow' ||
        !diff.hasBefore || !diff.hasAfter ||
        (diff.before != null && diff.before is! bool) ||
        diff.after != request.parameters['enabled'] ||
        diff.extensions['documentBeforeRevision'] != request.expectedRevision ||
        afterRevision is! String ||
        !RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(afterRevision)) {
      throw const FormatException('The replay document change does not match its mutation intent.');
    }
    final audit = await FileAuthoringAuditLog.open(
        projectRoot: root, incrementalWrites: true);
    await audit.append(AuthoringAuditRecord(
        auditId: _identity('audit_document_'),
        actorId: _actor.actorId,
        projectId: projectId,
        operation: recovered ? AuthoringSecurityOperation.recover : AuthoringSecurityOperation.apply,
        decision: AuthoringAuditDecision.succeeded,
        requestId: request.requestId,
        actionId: descriptor.id,
        actionVersion: descriptor.version,
        riskLevel: descriptor.riskLevel,
        planId: planId,
        receiptId: receipt.receiptId,
        code: 'mutation.succeeded',
        timestamp: DateTime.now(),
        details: {'idempotentReplay': !recovered, 'recovery': recovered}));
    await JournaledAuthoringTransaction(
        plans: AuthoringPlanStore(), gateway: gateway, idempotency: ledger,
        clock: DateTime.now).cleanupCompletedReplay(
            scope: scope, planId: planId, operationId: request.requestId,
            receipt: receipt);
    return CharacterContactShadowMutation.fromReceipt(receipt);
  }

  void _requireRead() {
    if (!_actor.allows(AuthoringPermissionScope.projectRead)) {
      throw const FormatException('project.read permission is required.');
    }
  }
}

Map<String, dynamic> _decode(List<int> bytes) {
  final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
  if (raw is! Map<String, dynamic> ||
      raw['characters'] is! List ||
      raw.containsKey('format') ||
      !ProjectVersion.values.any((version) => version.name == raw['version']) ||
      raw['name'] is! String) {
    throw const FormatException(
        'The native project document is invalid or unsupported.');
  }
  return raw;
}

Map<String, dynamic> _character(Map<String, dynamic> raw, String id) {
  final matches = (raw['characters'] as List)
      .where((entry) => entry is Map && entry['id'] == id)
      .toList();
  if (matches.length != 1 || matches.single is! Map<String, dynamic>) {
    throw const FormatException(
        'The character identity is missing or ambiguous.');
  }
  return matches.single as Map<String, dynamic>;
}

bool? _value(Map<String, dynamic> character) {
  final value = character['contactShadow'];
  if (value != null && value is! bool) {
    throw const FormatException(
        'The contact shadow value must be boolean or null.');
  }
  return value as bool?;
}

String _identity(String prefix) {
  final random = Random.secure();
  return '$prefix${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

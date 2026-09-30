import 'dart:io';

import '../contracts/authoring_diff.dart';
import '../contracts/authoring_request.dart';
import '../contracts/resource_ref.dart';
import '../domains/assets/asset_store.dart';
import '../ports/idempotency_store.dart';
import '../ports/project_file_reader.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/change_set.dart';
import '../transactions/file_idempotency_store.dart';
import '../transactions/idempotency_ledger.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/local_transaction_file_gateway.dart';
import '../transactions/plan_store.dart';
import '../transactions/recovery_service.dart';
import 'project_creation_kit.dart';
import 'workspace_handle_store.dart';

Future<void> writeProjectCreationKit(
  String path,
  ProjectCreationKit kit, {
  AuthoringTransactionFaultInjector? faultInjector,
}) async {
  final now = DateTime.now().toUtc();
  final operation = 'creation-${now.microsecondsSinceEpoch}';
  final base =
      computeAuthoringJsonFingerprint(const {}, logicalName: 'empty-project');
  final reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final registered = handles.registerProject(
      projectName: kit.manifest.name,
      initialFingerprint: base,
      readBytes: (relativePath) =>
          reader.readBytes(projectRoot: path, relativePath: relativePath));
  try {
    final request = AuthoringRequest(
        requestId: operation,
        actionId: 'project.create',
        actionVersion: 1,
        workspaceHandle: registered.workspaceHandle.value,
        expectedRevision: base,
        idempotencyKey: operation,
        parameters: {
          'name': kit.manifest.name,
          'tileWidth': kit.manifest.settings.tileWidth,
          'tileHeight': kit.manifest.settings.tileHeight
        });
    final refs = {
      for (final key in kit.files.keys)
        key: AuthoringResourceRef(
            kind: key == 'project.json'
                ? 'project'
                : key == assetCatalogStorageKey
                    ? 'assetCatalog'
                    : key.endsWith('.blob') || key.endsWith('.png')
                        ? 'assetBlob'
                        : 'map',
            id: key == 'project.json' ? registered.projectHandle.value : key)
    };
    final changes = AuthoringChangeSet(
        changes: [
          for (final entry in kit.files.entries)
            AuthoringResourceChange(
                resource: refs[entry.key]!,
                storageKey: entry.key,
                beforeBytes: null,
                afterBytes: entry.value)
        ],
        diff: AuthoringDiff([
          for (final entry in kit.files.entries)
            AuthoringDiffEntry(
                operation: AuthoringDiffOperation.add,
                resource: refs[entry.key]!,
                path: r'$',
                after: {'byteLength': entry.value.length})
        ]));
    final plans = AuthoringPlanStore();
    final plan = AuthoringPlan(
        planId: 'plan-$operation',
        receiptId: 'receipt-$operation',
        request: request,
        baseRevision: base,
        seed: 0,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 10)),
        changeSet: changes);
    plans.save(plan);
    final gateway = await LocalTransactionFileGateway.open(projectRoot: path);
    final ledger = AuthoringIdempotencyLedger(
        store: FileIdempotencyStore(
            filePath:
                '$path${Platform.pathSeparator}.pokemap${Platform.pathSeparator}authoring${Platform.pathSeparator}idempotency.jsonl'));
    final transaction = JournaledAuthoringTransaction(
        plans: plans,
        gateway: gateway,
        idempotency: ledger,
        clock: DateTime.now,
        faultInjector: faultInjector);
    try {
      await transaction.apply(
          planId: plan.planId,
          request: request,
          currentProjectRevision: base,
          operationId: operation,
          scope: AuthoringIdempotencyScope(
              actorId: 'project-creator',
              projectId: registered.projectHandle.value,
              actionId: 'project.create',
              actionVersion: 1,
              key: operation));
    } on Object catch (error) {
      final recovery = AuthoringRecoveryService(
          gateway: gateway, idempotency: ledger, clock: DateTime.now);
      try {
        final intents = await recovery.inspect();
        final intent =
            intents.where((item) => item.operationId == operation).firstOrNull;
        if (intent?.disposition ==
            AuthoringRecoveryDisposition.unreservedIntent) {
          await recovery.discardUnreserved(operation);
        } else if (intent?.disposition ==
            AuthoringRecoveryDisposition.resumable) {
          await recovery.compensate(operation);
        }
      } on Object catch (recoveryError) {
        throw FileSystemException(
            'Échec de création : $error. Récupération refusée : $recoveryError',
            path);
      }
      rethrow;
    }
  } finally {
    handles.closeWorkspace(registered.workspaceHandle);
  }
}

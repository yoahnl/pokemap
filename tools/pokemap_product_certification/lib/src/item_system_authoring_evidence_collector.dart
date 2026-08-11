import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

import 'item_system_authoring_probe.dart';
import 'item_system_certification.dart';
import 'item_system_execution_receipt.dart';
import 'item_system_fixture_digest.dart';

final class ItemSystemAuthoringEvidenceCollector {
  const ItemSystemAuthoringEvidenceCollector();

  Future<ItemSystemExecutionReceipt> collect({
    required Directory projectRootDirectory,
    required String sourceRevision,
    required DateTime recordedAtUtc,
  }) async {
    final required = ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
      ItemSystemProofLevel.authoringL1,
    );
    final succeeded = <String>{};
    final failed = <String>{};
    final payload = <String, Object?>{};
    final fixtureSha256 = await computeItemSystemFixtureSha256(
      projectRootDirectory,
    );
    final temporaryRoot = await Directory.systemTemp.createTemp(
      'pokemap-item-authoring-evidence-',
    );
    final workingRoot = Directory(p.join(temporaryRoot.path, 'project'));
    WorkspaceHandle? workspaceHandle;
    AuthoringReadApi? readApi;
    LocalMapAuthoringMutationApi? mutations;

    try {
      await _copyDirectory(projectRootDirectory, workingRoot);
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: <String>[workingRoot.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      readApi = AuthoringReadApi(
        openService: ProjectOpenService(
          policy: policy,
          fileReader: reader,
          handles: handles,
        ),
        snapshotLoader: snapshots,
      );
      mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
      );
      final opened = await readApi.openProject(workingRoot.path);
      workspaceHandle = opened.workspaceHandle;
      await mutations.attachProject(
        projectRootPath: workingRoot.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final actionReceipts = <String>[];

      for (final action in itemSystemAuthoringProbeActions.take(4)) {
        actionReceipts.add(
          await _applyAction(
            action,
            projectHandle: opened.projectHandle,
            workspaceHandle: opened.workspaceHandle,
            snapshots: snapshots,
            mutations: mutations,
          ),
        );
      }
      succeeded.add('catalog_crud');

      for (final action in itemSystemAuthoringProbeActions.skip(4)) {
        actionReceipts.add(
          await _applyAction(
            action,
            projectHandle: opened.projectHandle,
            workspaceHandle: opened.workspaceHandle,
            snapshots: snapshots,
            mutations: mutations,
          ),
        );
      }
      succeeded.add('effect_authoring');

      final queriedResourceKinds = <String>[];
      final queries = <String, AuthoringQueryRequest>{
        'itemCatalog': AuthoringQueryRequest(
          resourceKind: 'itemCatalog',
          operation: AuthoringQueryOperation.summary,
          view: AuthoringQueryView.summary,
        ),
        'itemDefinition': AuthoringQueryRequest(
          resourceKind: 'itemDefinition',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['cert-probe'],
          view: AuthoringQueryView.detail,
        ),
        'itemUsage': AuthoringQueryRequest(
          resourceKind: 'itemUsage',
          operation: AuthoringQueryOperation.list,
          filters: const <String, Object?>{'itemId': 'cert-probe'},
          view: AuthoringQueryView.detail,
        ),
        'itemReadiness': AuthoringQueryRequest(
          resourceKind: 'itemReadiness',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['cert-probe'],
          view: AuthoringQueryView.detail,
        ),
      };
      for (final entry in queries.entries) {
        final page = await readApi.queryProject(
          opened.projectHandle,
          entry.value,
        );
        if (page.items.isEmpty) {
          throw StateError('${entry.key} returned no authoring evidence.');
        }
        queriedResourceKinds.add(entry.key);
      }
      queriedResourceKinds.sort();
      succeeded.add('usage_readiness');

      String? referenceGuardCode;
      try {
        final snapshot = await snapshots.load(opened.projectHandle);
        await mutations.plan(
          opened.projectHandle,
          AuthoringRequest(
            requestId: 'cert-reference-guard',
            actionId: 'item.delete_apply',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: const <String, Object?>{'itemId': 'potion'},
            expectedRevision: snapshot.revision,
            idempotencyKey: 'cert-reference-guard',
          ),
        );
      } on ItemCatalogAuthoringException catch (error) {
        referenceGuardCode = error.code;
      }
      if (referenceGuardCode != 'item.delete_references_blocking') {
        throw StateError('Referenced item deletion was not refused.');
      }
      succeeded.add('reference_guards');

      final finalSnapshot = await snapshots.load(opened.projectHandle);
      payload
        ..['queriedResourceKinds'] = queriedResourceKinds
        ..['actionReceipts'] = actionReceipts
        ..['referenceGuardCode'] = referenceGuardCode
        ..['finalRevision'] = finalSnapshot.revision;
    } on Object catch (error) {
      failed.addAll(required.difference(succeeded));
      payload['error'] = error.toString();
    } finally {
      if (workspaceHandle != null) {
        await mutations?.detachWorkspace(workspaceHandle);
        await readApi?.closeWorkspace(workspaceHandle);
      }
      if (await temporaryRoot.exists()) {
        await temporaryRoot.delete(recursive: true);
      }
    }

    return ItemSystemExecutionReceipt.record(
      level: ItemSystemProofLevel.authoringL1,
      sourceRevision: sourceRevision,
      fixtureSha256: fixtureSha256,
      payload: payload,
      attemptedCapabilities: required,
      succeededCapabilities: succeeded,
      failedCapabilities: failed,
      producer: 'item-system-authoring-evidence-collector',
      runnerVersion: '1.0.0',
      recordedAtUtc: recordedAtUtc,
    );
  }
}

Future<String> _applyAction(
  ItemSystemAuthoringProbeAction action, {
  required ProjectHandle projectHandle,
  required WorkspaceHandle workspaceHandle,
  required ProjectSnapshotLoader snapshots,
  required LocalMapAuthoringMutationApi mutations,
}) async {
  final snapshot = await snapshots.load(projectHandle);
  final plan = await mutations.plan(
    projectHandle,
    AuthoringRequest(
      requestId: 'cert-${action.slug}',
      actionId: action.actionId,
      actionVersion: 1,
      workspaceHandle: workspaceHandle.value,
      parameters: action.parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'cert-${action.slug}',
    ),
  );
  String? confirmationToken;
  if (action.actionId == 'item.delete_apply') {
    final confirmation = await mutations.confirm(
      projectHandle,
      planId: plan['planId']! as String,
    );
    confirmationToken = confirmation['confirmationToken']! as String;
  }
  final applied = await mutations.apply(
    projectHandle,
    planId: plan['planId']! as String,
    operationId: 'cert-${action.slug}',
    confirmationToken: confirmationToken,
  );
  final receipt = Map<String, Object?>.from(applied['receipt']! as Map);
  if (receipt['status'] != 'applied' ||
      receipt['actionId'] != action.actionId) {
    throw StateError('${action.actionId} did not produce an applied receipt.');
  }
  return '${receipt['actionId']}@${receipt['afterRevision']}';
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final targetPath = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      await entity.copy(targetPath);
    } else {
      throw StateError('Unsupported fixture entity: ${entity.path}');
    }
  }
}

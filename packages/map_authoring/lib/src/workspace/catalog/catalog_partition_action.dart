import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../catalog_storage/catalog_generation_retention.dart';
import '../../catalog_storage/catalog_storage_store.dart';
import '../../catalog_storage/working_project_catalog.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_payload.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../transactions/plan_store.dart';

final class CatalogPartitionAction {
  CatalogPartitionAction({required this.store, required this.projectId});

  final CatalogStorageStore store;
  final String projectId;
  final Map<String, CatalogPartitionPreparation> _preparations = {};
  final Set<String> _retired = {};

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    rejectUnknownContractKeys(
        Map<String, dynamic>.from(context.request.parameters), const {});
    if (context.snapshot.materializedCatalogProject) {
      throw AuthoringPlanException(
          code: 'catalog.already_partitioned',
          message: 'This project already uses a partitioned catalog.');
    }
    final source =
        jsonDecode(utf8.decode(context.snapshot.resourceBytes('project')));
    if (source is! Map || source['format'] != null) {
      throw AuthoringPlanException(
          code: 'catalog.monolithic_project_required',
          message: 'Partitioning requires a complete monolithic project.');
    }
    final project = ProjectManifest.fromJson(Map<String, dynamic>.from(source));
    final prepared = await WorkingProjectCatalog.preparePartition(
        store: store,
        projectId: projectId,
        project: project,
        ownerId: context.planId,
        expectedProjectRevision:
            context.snapshot.resourceFingerprints['project']!);
    try {
      final published = await store.openRoot(prepared.root);
      final reconstructed =
          await (await PortableProjectCatalog.fromSnapshot(published.snapshot))
              .exportProject();
      if (canonicalAuthoringJson(project.toJson()) !=
          canonicalAuthoringJson(reconstructed.toJson())) {
        throw const CatalogStorageException(
            'catalog.partition_projection_mismatch',
            'The partitioned project differs from its typed source.');
      }
      _preparations[context.planId] = prepared;
      final headBytes = prepared.headBytes;
      final inspection = await inspectAuthoringPayload(Stream.value(headBytes),
          storageKey: CatalogStorageStore.headStorageKey,
          byteLength: headBytes.length);
      final headPayload = await AuthoringPayload.verifiedSource(
          storageKey: CatalogStorageStore.headStorageKey,
          byteLength: headBytes.length,
          rawSha256: inspection.rawSha256,
          openRead: () => Stream.value(headBytes),
          release: () async {
            _retired.add(context.planId);
          });
      final projectRef = AuthoringResourceRef(
          kind: 'project',
          id: 'project',
          revision: context.snapshot.resourceFingerprints['project']);
      final headRef = AuthoringResourceRef(kind: 'catalogHead', id: 'catalog');
      final identityRef =
          AuthoringResourceRef(kind: 'catalogIdentity', id: 'catalog');
      return AuthoringMutationDraft(
          projectedProject: project,
          changeSet: AuthoringChangeSet(
              changes: [
                AuthoringResourceChange(
                    resource: projectRef,
                    storageKey: 'project.json',
                    beforeBytes: context.snapshot.resourceBytes('project'),
                    afterBytes: prepared.descriptorBytes),
                AuthoringResourceChange.withPayloads(
                    resource: headRef,
                    storageKey: CatalogStorageStore.headStorageKey,
                    beforePayload: null,
                    afterPayload: headPayload),
                AuthoringResourceChange(
                    resource: identityRef,
                    storageKey: 'catalog/IDENTITY.json',
                    beforeBytes: null,
                    afterBytes: prepared.identityBytes),
              ],
              diff: AuthoringDiff([
                AuthoringDiffEntry(
                    operation: AuthoringDiffOperation.replace,
                    resource: projectRef,
                    path: '/storageFormat',
                    before: 'monolithic',
                    after: 'avelune.working-catalog'),
                AuthoringDiffEntry(
                    operation: AuthoringDiffOperation.add,
                    resource: headRef,
                    path: r'$',
                    after: prepared.root.toJson()),
                AuthoringDiffEntry(
                    operation: AuthoringDiffOperation.add,
                    resource: identityRef,
                    path: r'$',
                    after: {'projectId': projectId}),
              ])),
          preview: {
            'requiresReopen': true,
            'storageFormat': 'avelune.working-catalog',
            'preservedProjectName': project.name,
            'undoable': false
          });
    } on Object {
      _preparations.remove(context.planId);
      await prepared.close();
      rethrow;
    }
  }

  bool containsPlan(String planId) => _preparations.containsKey(planId);

  Future<void> requireApply(String planId, String operationId) async {
    final preparation = _preparations[planId];
    if (preparation == null) {
      throw AuthoringPlanException(
          code: 'catalog.partition_preparation_missing',
          message: 'The prepared catalog partition is unavailable.');
    }
    await preparation.attachOperationUnderLock(operationId);
  }

  Future<void> releaseOperation(String operationId) =>
      store.gateway.withExclusiveWriteLock(() async {
        if (await store.gateway.readJournal(operationId) == null) {
          await CatalogGenerationRetention(store: store)
              .releaseOwnerUnderLock(operationId);
        }
      });

  Future<void> flushRetired() async {
    for (final id in _retired.toList()) {
      await _preparations.remove(id)?.close();
      _retired.remove(id);
    }
  }

  Future<void> close() async {
    for (final preparation in _preparations.values.toList()) {
      await preparation.close();
    }
    _preparations.clear();
  }
}

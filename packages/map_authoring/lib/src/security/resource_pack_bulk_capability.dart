import '../catalog_storage/catalog_revert_merge.dart';
import '../catalog_storage/catalog_history_transition.dart';
import '../contracts/authoring_diff.dart';
import '../contracts/resource_ref.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/authoring_plan.dart';
import '../transactions/change_set.dart';
import 'authoring_permission.dart';

final class ResourcePackBulkCapability {
  ResourcePackBulkCapability._({
    required this.actorId,
    required this.projectId,
    required this.workspaceHandle,
    required this.planId,
    required this.operationId,
    required this.actionId,
    required this.actionVersion,
    required this.inventory,
    required this.diffFingerprint,
    required this.logicalOutputLimit,
    this.originEntryId,
    this.catalogRevert,
    this.catalogHistory,
  }) {
    for (final value in [actorId, projectId, planId, operationId]) {
      safeAuthoringSecurityIdentifier(value, 'bulk identity');
    }
    if (workspaceHandle.isEmpty ||
        actionVersion != 1 ||
        !const {
          'resource_pack.import',
          'history.undo',
          'history.redo',
          'history.revert'
        }.contains(actionId) ||
        (actionId == 'resource_pack.import') != (originEntryId == null) ||
        !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(diffFingerprint)) {
      throw ArgumentError('Invalid internal resource pack bulk capability.');
    }
    if (originEntryId != null) {
      safeAuthoringSecurityIdentifier(originEntryId!, 'originEntryId');
    }
    if (catalogRevert != null && actionId != 'history.revert') {
      throw ArgumentError(
          'A catalog merge attestation belongs only to revert.');
    }
    if (catalogHistory != null &&
        (catalogRevert != null ||
            !const {'history.undo', 'history.redo'}.contains(actionId))) {
      throw ArgumentError('A catalog conversion belongs only to undo or redo.');
    }
    final paths = <String>{};
    final resources = <String>{};
    String? previous;
    for (final item in inventory) {
      if (!paths.add(item.storageKey) ||
          !resources.add('${item.resource.kind}\u0000${item.resource.id}') ||
          (previous != null && previous.compareTo(item.storageKey) >= 0)) {
        throw ArgumentError('Bulk inventory must be ordered and unique.');
      }
      previous = item.storageKey;
    }
    if (catalogRevert != null) {
      final heads =
          inventory.where((item) => item.storageKey == 'catalog/HEAD.json');
      if (heads.length != 1 ||
          heads.single.beforeRevision != catalogRevert!.currentHeadRevision ||
          heads.single.afterRevision != catalogRevert!.resultHeadRevision) {
        throw ArgumentError(
            'The catalog merge attestation differs from its inventory.');
      }
    }
    if (catalogHistory != null) {
      final heads =
          inventory.where((item) => item.storageKey == 'catalog/HEAD.json');
      final undo = actionId == 'history.undo';
      if (heads.length != 1 ||
          heads.single.beforeRevision !=
              (undo
                  ? catalogHistory!.effectiveAfterRevision
                  : catalogHistory!.effectiveBeforeRevision) ||
          heads.single.afterRevision !=
              (undo
                  ? catalogHistory!.effectiveBeforeRevision
                  : catalogHistory!.effectiveAfterRevision)) {
        throw ArgumentError(
            'The catalog conversion differs from its inventory.');
      }
    }
    if (inventory.isEmpty ||
        (paths.contains('project.json') &&
            paths.contains('catalog/HEAD.json')) ||
        logicalOutputLimit < 0 ||
        logicalOutputLimit > 20000 ||
        logicalOutputCount > logicalOutputLimit ||
        contentBlobCount > logicalOutputLimit ||
        (actionId == 'resource_pack.import' &&
            logicalOutputLimit != logicalOutputCount) ||
        metadataCount > 2 ||
        inventory.length > 2 * logicalOutputLimit + 2 ||
        inventory.length > 40002) {
      throw ArgumentError(
          'The resource pack inventory exceeds its internal budget.');
    }
  }

  final String actorId;
  final String projectId;
  final String workspaceHandle;
  final String planId;
  final String operationId;
  final String actionId;
  final int actionVersion;
  final String? originEntryId;
  final CatalogRevertMergeAttestation? catalogRevert;
  final CatalogHistoryTransitionAttestation? catalogHistory;
  final List<ResourcePackBulkInventoryEntry> inventory;
  final String diffFingerprint;
  final int logicalOutputLimit;
  int get logicalOutputCount =>
      inventory.where((item) => item.role == 'logical').length;
  int get contentBlobCount =>
      inventory.where((item) => item.role == 'blob').length;
  int get metadataCount =>
      inventory.where((item) => item.role == 'metadata').length;
  String get inventoryFingerprint => computeAuthoringJsonFingerprint(
      [for (final item in inventory) item.toJson()],
      logicalName: 'resource-pack-bulk-inventory.json');

  void requirePlan(AuthoringPlan plan,
      {required String actorId,
      required String projectId,
      required String operationId}) {
    requireBinding(
        actorId: actorId,
        projectId: projectId,
        planId: plan.planId,
        operationId: operationId,
        actionId: plan.request.actionId,
        actionVersion: plan.request.actionVersion,
        workspaceHandle: plan.request.workspaceHandle,
        diff: plan.changeSet.diff,
        actualInventory: [
          for (final change in plan.changeSet.changes)
            ResourcePackBulkInventoryEntry.fromChange(change,
                role: roleFor(change.storageKey))
        ]);
  }

  late final Map<String, String> _roles = {
    for (final item in inventory) item.storageKey: item.role
  };
  String roleFor(String storageKey) =>
      _roles[storageKey] ??
      (throw ArgumentError('A resource is absent from the bulk inventory.'));

  void requireBinding(
      {required String actorId,
      required String projectId,
      required String planId,
      required String operationId,
      required String actionId,
      required int actionVersion,
      String? workspaceHandle,
      required AuthoringDiff diff,
      required Iterable<ResourcePackBulkInventoryEntry> actualInventory}) {
    final actual = actualInventory.toList()
      ..sort((a, b) => a.storageKey.compareTo(b.storageKey));
    if (this.actorId != actorId ||
        this.projectId != projectId ||
        this.planId != planId ||
        this.operationId != operationId ||
        this.actionId != actionId ||
        this.actionVersion != actionVersion ||
        (workspaceHandle != null && this.workspaceHandle != workspaceHandle) ||
        diffFingerprint != bulkDiffFingerprint(diff) ||
        inventory.length != actual.length) {
      throw ArgumentError('The bulk capability does not match this mutation.');
    }
    for (var i = 0; i < inventory.length; i++) {
      if (canonicalAuthoringJson(inventory[i].toJson()) !=
          canonicalAuthoringJson(actual[i].toJson())) {
        throw ArgumentError(
            'The bulk capability inventory differs from the mutation.');
      }
    }
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': catalogHistory == null ? 3 : 4,
        'logicalOutputLimit': logicalOutputLimit,
        'actorId': actorId,
        'projectId': projectId,
        'workspaceHandle': workspaceHandle,
        'planId': planId,
        'operationId': operationId,
        'actionId': actionId,
        'actionVersion': actionVersion,
        if (originEntryId != null) 'originEntryId': originEntryId,
        if (catalogRevert != null) 'catalogRevert': catalogRevert!.toJson(),
        if (catalogHistory != null) 'catalogHistory': catalogHistory!.toJson(),
        'inventory': [for (final item in inventory) item.toJson()],
        'diffFingerprint': diffFingerprint,
        'inventoryFingerprint': inventoryFingerprint,
        'logicalOutputCount': logicalOutputCount,
        'contentBlobCount': contentBlobCount,
        'metadataCount': metadataCount,
        'touchedResources': inventory.length,
      };

  factory ResourcePackBulkCapability.fromJournalJson(
      Map<String, dynamic> json) {
    try {
      if (!const {3, 4}.contains(json['schemaVersion']) ||
          json['inventory'] is! List) {
        throw const FormatException();
      }
      final capability = ResourcePackBulkCapability._(
          actorId: json['actorId'] as String,
          projectId: json['projectId'] as String,
          workspaceHandle: json['workspaceHandle'] as String,
          planId: json['planId'] as String,
          operationId: json['operationId'] as String,
          actionId: json['actionId'] as String,
          actionVersion: json['actionVersion'] as int,
          diffFingerprint: json['diffFingerprint'] as String,
          logicalOutputLimit: json['logicalOutputLimit'] as int,
          originEntryId: json['originEntryId'] as String?,
          catalogRevert: json['catalogRevert'] == null
              ? null
              : CatalogRevertMergeAttestation.fromJournalJson(
                  Map<String, dynamic>.from(json['catalogRevert'] as Map)),
          catalogHistory: json['catalogHistory'] == null
              ? null
              : CatalogHistoryTransitionAttestation.fromJournalJson(
                  Map<String, dynamic>.from(json['catalogHistory'] as Map)),
          inventory: List.unmodifiable((json['inventory'] as List).map((item) =>
              ResourcePackBulkInventoryEntry.fromJson(
                  Map<String, dynamic>.from(item as Map)))));
      if (canonicalAuthoringJson(json) !=
          canonicalAuthoringJson(capability.toJson())) {
        throw const FormatException();
      }
      return capability;
    } on Object {
      throw const FormatException('Invalid resource pack bulk capability.');
    }
  }
}

final class ResourcePackBulkInventoryEntry {
  ResourcePackBulkInventoryEntry(
      {required this.resource,
      required this.storageKey,
      required this.beforeRevision,
      required this.afterRevision,
      required this.role}) {
    final segments = storageKey.split('/');
    final isCatalogHead = storageKey == 'catalog/HEAD.json';
    final isCatalogNamespace = segments.first.toLowerCase() == 'catalog';
    if (segments.any((segment) =>
            segment.isEmpty || segment == '.' || segment == '..') ||
        storageKey.contains(r'\') ||
        storageKey.contains('\u0000') ||
        storageKey.contains(':') ||
        segments.first == '.pokemap' ||
        (isCatalogNamespace && !isCatalogHead) ||
        (isCatalogHead &&
            (resource.kind != 'catalogHead' || resource.id != 'catalog')) ||
        (resource.kind == 'catalogHead' && !isCatalogHead) ||
        !const {'logical', 'blob', 'metadata'}.contains(role) ||
        (role == 'metadata') !=
            const {
              'project.json',
              'assets/.pokemap-assets.json',
              'catalog/HEAD.json'
            }.contains(storageKey) ||
        (beforeRevision == null && afterRevision == null)) {
      throw ArgumentError('Invalid bulk inventory resource.');
    }
    for (final revision in [beforeRevision, afterRevision]) {
      if (revision != null &&
          !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(revision)) {
        throw ArgumentError('Invalid bulk inventory revision.');
      }
    }
  }
  factory ResourcePackBulkInventoryEntry.fromChange(
          AuthoringResourceChange change,
          {required String role}) =>
      ResourcePackBulkInventoryEntry(
          resource: change.resource,
          storageKey: change.storageKey,
          beforeRevision: change.beforeRevision,
          afterRevision: change.afterRevision,
          role: role);
  final AuthoringResourceRef resource;
  final String storageKey;
  final String? beforeRevision;
  final String? afterRevision;
  final String role;
  Map<String, Object?> toJson() => {
        'resource': resource.toJson(),
        'storageKey': storageKey,
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'role': role
      };
  factory ResourcePackBulkInventoryEntry.fromJson(Map<String, dynamic> json) {
    final item = ResourcePackBulkInventoryEntry(
        resource: AuthoringResourceRef.fromJson(
            Map<String, dynamic>.from(json['resource'] as Map)),
        storageKey: json['storageKey'] as String,
        beforeRevision: json['beforeRevision'] as String?,
        afterRevision: json['afterRevision'] as String?,
        role: json['role'] as String);
    if (canonicalAuthoringJson(json) != canonicalAuthoringJson(item.toJson())) {
      throw const FormatException();
    }
    return item;
  }
}

final class ResourcePackBulkAuthority {
  static ResourcePackBulkCapability certifyImport(
      {required AuthoringPlan plan,
      required String actorId,
      required String projectId,
      required String operationId,
      required Iterable<String> logicalStorageKeys,
      required Iterable<String> contentBlobStorageKeys}) {
    if (plan.request.actionId != 'resource_pack.import' ||
        plan.request.actionVersion != 1) {
      throw ArgumentError(
          'Only the prepared resource pack import can mint a bulk capability.');
    }
    final logicalList = logicalStorageKeys.toList();
    final blobList = contentBlobStorageKeys.toList();
    final logical = logicalList.toSet();
    final blobs = blobList.toSet();
    if (logical.length != logicalList.length ||
        blobs.length != blobList.length ||
        logical.intersection(blobs).isNotEmpty) {
      throw ArgumentError('The frozen output inventory must be unique.');
    }
    final inventory = <ResourcePackBulkInventoryEntry>[];
    for (final change in plan.changeSet.changes) {
      final role = logical.remove(change.storageKey)
          ? 'logical'
          : blobs.remove(change.storageKey)
              ? 'blob'
              : 'metadata';
      if (role == 'blob' &&
          (change.beforeRevision != null || change.afterRevision == null)) {
        throw ArgumentError(
            'An import may certify only newly created content blobs.');
      }
      inventory
          .add(ResourcePackBulkInventoryEntry.fromChange(change, role: role));
    }
    if (logical.isNotEmpty || blobs.isNotEmpty) {
      throw ArgumentError(
          'The frozen inventory differs from the prepared native output.');
    }
    inventory.sort((a, b) => a.storageKey.compareTo(b.storageKey));
    return ResourcePackBulkCapability._(
        actorId: actorId,
        projectId: projectId,
        workspaceHandle: plan.request.workspaceHandle,
        planId: plan.planId,
        operationId: operationId,
        actionId: plan.request.actionId,
        actionVersion: plan.request.actionVersion,
        inventory: List.unmodifiable(inventory),
        logicalOutputLimit: logicalList.length,
        diffFingerprint: bulkDiffFingerprint(plan.changeSet.diff));
  }

  static ResourcePackBulkCapability certifyHistory(
      {required AuthoringPlan plan,
      required String actorId,
      required String projectId,
      required String operationId,
      required String originEntryId,
      required ResourcePackBulkCapability origin,
      required Iterable<ResourcePackBulkInventoryEntry> verifiedInventory,
      CatalogRevertMergeAttestation? catalogRevert,
      CatalogHistoryTransitionAttestation? catalogHistory}) {
    if (origin.projectId != projectId ||
        !const {'history.undo', 'history.redo', 'history.revert'}
            .contains(plan.request.actionId)) {
      throw ArgumentError('Invalid bulk history origin.');
    }
    if (catalogRevert != null && !catalogRevert.verified) {
      throw ArgumentError(
          'A catalog merge must be verified before certification.');
    }
    if (catalogHistory != null) {
      final heads = origin.inventory
          .where((item) => item.storageKey == 'catalog/HEAD.json');
      if (!catalogHistory.verified ||
          heads.length != 1 ||
          heads.single.beforeRevision !=
              catalogHistory.originalBeforeRevision ||
          heads.single.afterRevision != catalogHistory.originalAfterRevision) {
        throw ArgumentError(
            'The catalog conversion differs from its certified origin.');
      }
    }
    if (catalogRevert != null) {
      final heads = origin.inventory
          .where((item) => item.storageKey == 'catalog/HEAD.json');
      if (heads.length != 1 ||
          heads.single.beforeRevision !=
              catalogRevert.targetBeforeHeadRevision ||
          heads.single.afterRevision != catalogRevert.targetAfterHeadRevision) {
        throw ArgumentError(
            'The catalog merge differs from its certified origin.');
      }
    }
    final inventory = verifiedInventory.toList()
      ..sort((a, b) => a.storageKey.compareTo(b.storageKey));
    final capability = ResourcePackBulkCapability._(
        actorId: actorId,
        projectId: projectId,
        workspaceHandle: plan.request.workspaceHandle,
        planId: plan.planId,
        operationId: operationId,
        actionId: plan.request.actionId,
        actionVersion: plan.request.actionVersion,
        originEntryId: originEntryId,
        catalogRevert: catalogRevert,
        catalogHistory: catalogHistory,
        inventory: List.unmodifiable(inventory),
        logicalOutputLimit: origin.logicalOutputLimit,
        diffFingerprint: bulkDiffFingerprint(plan.changeSet.diff));
    capability.requirePlan(plan,
        actorId: actorId, projectId: projectId, operationId: operationId);
    return capability;
  }
}

String bulkDiffFingerprint(AuthoringDiff diff) =>
    computeAuthoringJsonFingerprint(diff.toJson(),
        logicalName: 'authoring-confirmation-diff.json');

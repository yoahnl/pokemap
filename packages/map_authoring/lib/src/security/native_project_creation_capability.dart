part of '../workspace/native_project_creation.dart';

final class NativeProjectCreationCapability {
  NativeProjectCreationCapability._(
      {required this.actorId,
      required this.projectId,
      required this.workspaceHandle,
      required this.planId,
      required this.operationId,
      required List<_NativeCreationInventoryEntry> inventory,
      required this.diffFingerprint,
      required this.inventoryFingerprint,
      required this.byteLength,
      required this.journalOnly})
      : _inventory = List.unmodifiable(inventory) {
    if (_inventory.isEmpty ||
        _inventory.length > nativeProjectCreationMaxResources ||
        byteLength < 0 ||
        byteLength > nativeProjectCreationHardMaxBytes ||
        _inventory.fold<int>(0, (sum, item) => sum + item.byteLength) !=
            byteLength ||
        _inventoryFingerprint(_inventory) != inventoryFingerprint) {
      throw const FormatException(
          'Invalid prepared native creation capability.');
    }
    final paths = <String>{};
    String? previous;
    for (final item in _inventory) {
      if (!paths.add(item.storageKey.toLowerCase()) ||
          (previous != null && previous.compareTo(item.storageKey) >= 0)) {
        throw const FormatException('Invalid native creation inventory order.');
      }
      previous = item.storageKey;
    }
    if (!paths.contains('project.json')) {
      throw const FormatException('Native creation requires its manifest.');
    }
  }
  factory NativeProjectCreationCapability.forPreparedPlan(
      {required NativePreparedProjectCreation prepared,
      required AuthoringPlan plan,
      required String actorId,
      required String projectId,
      required String operationId}) {
    prepared._requirePlan(plan);
    final result = NativeProjectCreationCapability._(
        actorId: actorId,
        projectId: projectId,
        workspaceHandle: plan.request.workspaceHandle,
        planId: plan.planId,
        operationId: operationId,
        inventory: prepared._inventory,
        diffFingerprint: computeAuthoringJsonFingerprint(
            plan.changeSet.diff.toJson(),
            logicalName: 'native-creation-diff.json'),
        inventoryFingerprint: prepared.inventoryFingerprint,
        byteLength: prepared.byteLength,
        journalOnly: false);
    result.requirePlan(plan,
        actorId: actorId, projectId: projectId, operationId: operationId);
    return result;
  }
  factory NativeProjectCreationCapability.fromJournalJson(
      Map<String, dynamic> json) {
    _keys(json, {
      'actorId',
      'projectId',
      'workspaceHandle',
      'planId',
      'operationId',
      'inventory',
      'diffFingerprint',
      'inventoryFingerprint',
      'byteLength'
    });
    return NativeProjectCreationCapability._(
        actorId: json['actorId'] as String,
        projectId: json['projectId'] as String,
        workspaceHandle: json['workspaceHandle'] as String,
        planId: json['planId'] as String,
        operationId: json['operationId'] as String,
        inventory: List.unmodifiable([
          for (final item in json['inventory'] as List)
            _NativeCreationInventoryEntry.fromJson(_object(item))
        ]),
        diffFingerprint: json['diffFingerprint'] as String,
        inventoryFingerprint: json['inventoryFingerprint'] as String,
        byteLength: json['byteLength'] as int,
        journalOnly: true);
  }
  final String actorId;
  final String projectId;
  final String workspaceHandle;
  final String planId;
  final String operationId;
  final List<_NativeCreationInventoryEntry> _inventory;
  final String diffFingerprint;
  final String inventoryFingerprint;
  final int byteLength;
  final bool journalOnly;
  void requirePlan(AuthoringPlan plan,
      {required String actorId,
      required String projectId,
      required String operationId}) {
    if (journalOnly) {
      throw StateError(
          'Recovered native creation capabilities cannot authorize new plans.');
    }
    requireBinding(
        actorId: actorId,
        projectId: projectId,
        planId: plan.planId,
        operationId: operationId,
        actionId: plan.request.actionId,
        actionVersion: plan.request.actionVersion,
        diff: plan.changeSet.diff,
        entries: [
          for (final change in plan.changeSet.changes)
            (
              storageKey: change.storageKey,
              beforeRevision: change.beforeRevision,
              afterRevision: change.afterRevision
            )
        ]);
    if (plan.request.workspaceHandle != workspaceHandle) {
      throw const FormatException('Native creation workspace changed.');
    }
  }

  void requireBinding(
      {required String actorId,
      required String projectId,
      required String planId,
      required String operationId,
      required String actionId,
      required int actionVersion,
      required AuthoringDiff diff,
      required Iterable<
              ({
                String storageKey,
                String? beforeRevision,
                String? afterRevision
              })>
          entries}) {
    if (this.actorId != actorId ||
        this.projectId != projectId ||
        this.planId != planId ||
        this.operationId != operationId ||
        actionId != nativeProjectCreationActionId ||
        actionVersion != 1 ||
        computeAuthoringJsonFingerprint(diff.toJson(),
                logicalName: 'native-creation-diff.json') !=
            diffFingerprint) {
      throw const FormatException(
          'Native creation capability context mismatch.');
    }
    final expected = {for (final item in _inventory) item.storageKey: item};
    for (final entry in entries) {
      final item = expected.remove(entry.storageKey);
      if (item == null ||
          entry.beforeRevision != null ||
          entry.afterRevision != item.afterRevision) {
        throw const FormatException(
            'Native creation capability inventory mismatch.');
      }
    }
    if (expected.isNotEmpty) {
      throw const FormatException(
          'Native creation capability inventory incomplete.');
    }
  }

  Map<String, Object?> toJson() => {
        'actorId': actorId,
        'projectId': projectId,
        'workspaceHandle': workspaceHandle,
        'planId': planId,
        'operationId': operationId,
        'inventory': [for (final item in _inventory) item.toJson()],
        'diffFingerprint': diffFingerprint,
        'inventoryFingerprint': inventoryFingerprint,
        'byteLength': byteLength
      };
}

final class _NativeCreationInventoryEntry {
  _NativeCreationInventoryEntry(
      {required this.storageKey,
      required this.afterRevision,
      required this.byteLength}) {
    final parts = validateProjectRelativePath(storageKey);
    if (parts.join('/') != storageKey ||
        parts.first == '.pokemap' ||
        byteLength < 0 ||
        !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(afterRevision)) {
      throw const FormatException('Invalid native creation inventory entry.');
    }
  }
  factory _NativeCreationInventoryEntry.fromJson(Map<String, dynamic> json) {
    _keys(json, {'storageKey', 'afterRevision', 'byteLength'});
    return _NativeCreationInventoryEntry(
        storageKey: json['storageKey'] as String,
        afterRevision: json['afterRevision'] as String,
        byteLength: json['byteLength'] as int);
  }
  final String storageKey;
  final String afterRevision;
  final int byteLength;
  Map<String, Object?> toJson() => {
        'storageKey': storageKey,
        'afterRevision': afterRevision,
        'byteLength': byteLength
      };
}

String _inventoryFingerprint(List<_NativeCreationInventoryEntry> inventory) =>
    computeAuthoringJsonFingerprint(
        [for (final item in inventory) item.toJson()],
        logicalName: 'native-project-creation-inventory.json');

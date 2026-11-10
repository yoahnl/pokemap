import '../../../platform/rendering/contracts/workspace_resource_diagnostic.dart';

class WorkspaceResourceDiagnosticProjection {
  factory WorkspaceResourceDiagnosticProjection(
    Iterable<WorkspaceResourceDiagnostic> source,
    Set<String> active, {
    bool activeOnly = false,
  }) {
    final unique = {for (final item in source) item.resourceId: item}.values;
    final diagnostics = unique
        .where((item) => !activeOnly || active.contains(item.resourceId))
        .toList()
      ..sort((a, b) => (active.contains(b.resourceId) ? 1 : 0)
          .compareTo(active.contains(a.resourceId) ? 1 : 0));
    final memory = diagnostics
        .where((item) => item.cause == WorkspaceResourceCause.memoryPressure)
        .toList();
    final owned = <String, List<WorkspaceResourceDiagnostic>>{};
    for (final item in diagnostics) {
      if (item.cause == WorkspaceResourceCause.memoryPressure) continue;
      owned.putIfAbsent(item.ownerKey, () => []).add(item);
    }
    final groups = [
      for (final items in owned.values)
        WorkspaceResourceDiagnosticGroup(items, active),
      if (memory.isNotEmpty) WorkspaceResourceDiagnosticGroup(memory, active),
    ]..sort((a, b) => (b.active ? 1 : 0).compareTo(a.active ? 1 : 0));
    return WorkspaceResourceDiagnosticProjection._(
      ownerCount: unique.map((item) => item.ownerKey).toSet().length,
      diagnostics: List.unmodifiable(diagnostics),
      groups: List.unmodifiable(groups),
    );
  }

  const WorkspaceResourceDiagnosticProjection._({
    required this.ownerCount,
    required this.diagnostics,
    required this.groups,
  });

  final int ownerCount;
  final List<WorkspaceResourceDiagnostic> diagnostics;
  final List<WorkspaceResourceDiagnosticGroup> groups;
  Iterable<String> get retryableIds => diagnostics
      .where((item) => item.canRetry)
      .map((item) => item.resourceId);
}

class WorkspaceResourceDiagnosticGroup {
  WorkspaceResourceDiagnosticGroup(
    Iterable<WorkspaceResourceDiagnostic> source,
    Set<String> activeIds,
  ) : items = List.unmodifiable(source),
      active = source.any((item) => activeIds.contains(item.resourceId));

  final List<WorkspaceResourceDiagnostic> items;
  final bool active;
  bool get memory => items.first.cause == WorkspaceResourceCause.memoryPressure;
  String get key => memory ? 'memory' : items.first.ownerKey;
  String get title => memory
      ? '${items.length} ressources · pression mémoire'
      : items.first.ownerName ?? items.first.name;
  List<String> get roles => memory
      ? const []
      : {for (final item in items) ?item.role}.toList();
  bool get verified => items.every((item) => item.verified);
  (String, String)? get owner {
    final item = items.first;
    return memory || item.ownerKind == null || item.ownerId == null
        ? null
        : (item.ownerKind!, item.ownerId!);
  }
  Iterable<String> get retryableIds => items
      .where((item) => item.canRetry)
      .map((item) => item.resourceId);
}

String workspaceResourceDiagnosticDetail(WorkspaceResourceDiagnostic item) =>
    '${item.name}\n${item.resourceId}\n${item.message}\n'
    '${item.detail ?? 'Aucun détail technique disponible.'}';

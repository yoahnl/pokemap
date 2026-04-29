import 'package:map_core/map_core.dart';

import 'surface_studio_drag_payload.dart';

enum SurfaceStudioDropValidation {
  valid,
  invalidNoColumn,
  invalidTooManyColumns,
  invalidRoleLocked,
}

/// Brouillon local du Surface Studio V2 : rôle Surface -> colonnes d'atlas.
///
/// Le rôle `isolated`, affiché comme "Plein (center)", est le seul rôle
/// multi-colonnes en V2. Les autres rôles restent mono-assignation.
final class SurfaceStudioRoleAssignmentDraft {
  const SurfaceStudioRoleAssignmentDraft.empty()
      : _assignments = const <SurfaceVariantRole, List<int>>{};

  const SurfaceStudioRoleAssignmentDraft._(this._assignments);

  final Map<SurfaceVariantRole, List<int>> _assignments;

  List<int> columnsForRole(SurfaceVariantRole role) =>
      _assignments[role] ?? const <int>[];

  bool isAssigned(SurfaceVariantRole role) => columnsForRole(role).isNotEmpty;

  int get assignedRoleCount => _assignments.length;

  int assignedCountForRoles(Iterable<SurfaceVariantRole> roles) {
    var count = 0;
    for (final role in roles) {
      if (isAssigned(role)) {
        count++;
      }
    }
    return count;
  }

  SurfaceStudioRoleAssignmentDraft assignColumns(
    SurfaceVariantRole role,
    List<int> columns,
  ) {
    final cleaned = _cleanColumns(columns);
    final next = <SurfaceVariantRole, List<int>>{
      for (final entry in _assignments.entries)
        entry.key: List<int>.unmodifiable(entry.value),
    };
    if (cleaned.isEmpty) {
      next.remove(role);
    } else if (role == SurfaceVariantRole.isolated) {
      final merged = <int>[...columnsForRole(role)];
      for (final column in cleaned) {
        if (!merged.contains(column)) {
          merged.add(column);
        }
      }
      next[role] = List<int>.unmodifiable(merged);
    } else {
      next[role] = List<int>.unmodifiable(<int>[cleaned.first]);
    }
    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
  }

  SurfaceStudioRoleAssignmentDraft clearRole(SurfaceVariantRole role) {
    if (!_assignments.containsKey(role)) {
      return this;
    }
    final next = <SurfaceVariantRole, List<int>>{
      for (final entry in _assignments.entries)
        if (entry.key != role) entry.key: List<int>.unmodifiable(entry.value),
    };
    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
  }

  SurfaceStudioRoleAssignmentDraft clearColumn(
    SurfaceVariantRole role,
    int column,
  ) {
    final current = columnsForRole(role);
    if (!current.contains(column)) {
      return this;
    }
    final remaining = current.where((value) => value != column).toList();
    if (remaining.isEmpty) {
      return clearRole(role);
    }
    final next = <SurfaceVariantRole, List<int>>{
      for (final entry in _assignments.entries)
        entry.key: entry.key == role
            ? List<int>.unmodifiable(remaining)
            : List<int>.unmodifiable(entry.value),
    };
    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioRoleAssignmentDraft &&
          _mapsEqual(other._assignments, _assignments);

  @override
  int get hashCode => Object.hashAll(
        _assignments.entries.map(
          (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
        ),
      );
}

SurfaceStudioDropValidation validateSurfaceStudioRoleDrop({
  required SurfaceVariantRole role,
  required SurfaceStudioColumnDragPayload payload,
  required SurfaceStudioRoleAssignmentDraft draft,
}) {
  if (payload.columns.isEmpty) {
    return SurfaceStudioDropValidation.invalidNoColumn;
  }
  if (role != SurfaceVariantRole.isolated && payload.columns.length > 1) {
    return SurfaceStudioDropValidation.invalidTooManyColumns;
  }
  return SurfaceStudioDropValidation.valid;
}

List<int> _cleanColumns(List<int> columns) {
  final cleaned = <int>[];
  for (final column in columns) {
    if (column <= 0 || cleaned.contains(column)) {
      continue;
    }
    cleaned.add(column);
  }
  cleaned.sort();
  return cleaned;
}

bool _mapsEqual(
  Map<SurfaceVariantRole, List<int>> a,
  Map<SurfaceVariantRole, List<int>> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null || !_listEquals(entry.value, other)) {
      return false;
    }
  }
  return true;
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

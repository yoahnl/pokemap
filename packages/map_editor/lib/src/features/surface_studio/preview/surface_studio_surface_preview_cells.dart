import 'package:map_core/map_core.dart';

import '../surface_studio_role_assignment_draft.dart';

final class SurfaceStudioPreviewCell {
  const SurfaceStudioPreviewCell({
    required this.x,
    required this.y,
    required this.role,
    required this.sourceColumn,
    required this.usedFallback,
  });

  final int x;
  final int y;
  final SurfaceVariantRole role;
  final int sourceColumn;
  final bool usedFallback;
}

List<SurfaceStudioPreviewCell> buildSurfaceStudioRectPreviewCells({
  required SurfaceStudioRoleAssignmentDraft assignmentDraft,
  required int previewSize,
  required int frameIndex,
}) {
  final isolatedColumns =
      assignmentDraft.columnsForRole(SurfaceVariantRole.isolated);
  if (isolatedColumns.isEmpty) {
    return const <SurfaceStudioPreviewCell>[];
  }
  final size = previewSize < 3 ? 3 : previewSize;
  final cells = <SurfaceStudioPreviewCell>[];
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final role = surfaceStudioPreviewRoleForCell(
        x: x,
        y: y,
        previewSize: size,
      );
      final directColumns = assignmentDraft.columnsForRole(role);
      final usedFallback = directColumns.isEmpty;
      final sourceColumn = usedFallback
          ? _alternatingColumn(
              isolatedColumns,
              x: x,
              y: y,
              frameIndex: frameIndex,
            )
          : _columnForRole(
              role: role,
              columns: directColumns,
              x: x,
              y: y,
              frameIndex: frameIndex,
            );
      cells.add(
        SurfaceStudioPreviewCell(
          x: x,
          y: y,
          role: role,
          sourceColumn: sourceColumn,
          usedFallback: usedFallback,
        ),
      );
    }
  }
  return List<SurfaceStudioPreviewCell>.unmodifiable(cells);
}

int? resolveSurfaceStudioPreviewColumnForRole({
  required SurfaceStudioRoleAssignmentDraft assignmentDraft,
  required SurfaceVariantRole role,
  required int x,
  required int y,
  required int frameIndex,
}) {
  final columns = assignmentDraft.columnsForRole(role);
  if (columns.isNotEmpty) {
    return _columnForRole(
      role: role,
      columns: columns,
      x: x,
      y: y,
      frameIndex: frameIndex,
    );
  }
  final isolatedColumns =
      assignmentDraft.columnsForRole(SurfaceVariantRole.isolated);
  if (isolatedColumns.isEmpty) {
    return null;
  }
  return _alternatingColumn(
    isolatedColumns,
    x: x,
    y: y,
    frameIndex: frameIndex,
  );
}

SurfaceVariantRole surfaceStudioPreviewRoleForCell({
  required int x,
  required int y,
  required int previewSize,
}) {
  final size = previewSize < 3 ? 3 : previewSize;
  final last = size - 1;
  final left = x == 0;
  final right = x == last;
  final top = y == 0;
  final bottom = y == last;
  if (top && left) {
    return SurfaceVariantRole.cornerNW;
  }
  if (top && right) {
    return SurfaceVariantRole.cornerNE;
  }
  if (bottom && left) {
    return SurfaceVariantRole.cornerSW;
  }
  if (bottom && right) {
    return SurfaceVariantRole.cornerSE;
  }
  if (top) {
    return SurfaceVariantRole.endNorth;
  }
  if (right) {
    return SurfaceVariantRole.endEast;
  }
  if (bottom) {
    return SurfaceVariantRole.endSouth;
  }
  if (left) {
    return SurfaceVariantRole.endWest;
  }
  return SurfaceVariantRole.isolated;
}

int _columnForRole({
  required SurfaceVariantRole role,
  required List<int> columns,
  required int x,
  required int y,
  required int frameIndex,
}) {
  if (role == SurfaceVariantRole.isolated) {
    return _alternatingColumn(
      columns,
      x: x,
      y: y,
      frameIndex: frameIndex,
    );
  }
  return columns.first;
}

int _alternatingColumn(
  List<int> columns, {
  required int x,
  required int y,
  required int frameIndex,
}) {
  final index = (x + y + frameIndex).remainder(columns.length);
  return columns[index];
}

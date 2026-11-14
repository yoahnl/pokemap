import '../models/geometry.dart';
import '../models/map_data.dart';
import 'spatial_border_resolution_context.dart';
import 'spatial_map_edit_intents.dart';

final class HeightStepContours {
  HeightStepContours(
    this.status,
    Iterable<List<GridPos>> strokes, {
    this.ambiguousVertices = const [],
    this.reason,
  }) : strokes = List.unmodifiable(
         strokes.map((stroke) => List<GridPos>.unmodifiable(stroke)),
       );
  final SpatialIntentResolutionState status;
  final List<List<GridPos>> strokes;
  final List<GridPos> ambiguousVertices;
  final String? reason;
}

HeightStepContours computeHeightStepEdges(
  MapData map, {
  required double lowerHeight,
  required double upperHeight,
  MapRect? region,
  Iterable<GridPos>? cells,
  bool exactHeights = false,
}) {
  final scene = map.spatialScene;
  if (scene == null ||
      !lowerHeight.isFinite ||
      !upperHeight.isFinite ||
      lowerHeight >= upperHeight) {
    throw const FormatException(
      'Height steps require a 3D map and ordered finite heights.',
    );
  }
  final area = (
    x: region?.pos.x ?? 0,
    y: region?.pos.y ?? 0,
    width: region?.size.width ?? scene.width,
    height: region?.size.height ?? scene.depth,
  );
  final right = area.x + area.width, bottom = area.y + area.height;
  if (area.x < 0 ||
      area.y < 0 ||
      area.width < 1 ||
      area.height < 1 ||
      right > scene.width ||
      bottom > scene.depth) {
    throw const FormatException(
      'The height step region must be inside the map.',
    );
  }
  for (var y = area.y; y < bottom; y++) {
    for (var x = area.x; x < right; x++) {
      if (scene.navigation.ramps.any((ramp) => ramp.contains(x + .5, y + .5))) {
        return HeightStepContours(
          SpatialIntentResolutionState.unsupported,
          [],
          reason: 'ramps_require_explicit_contour',
        );
      }
    }
  }
  final terrain = SpatialBorderResolutionContext.fromMap(map);
  double heightAt(int x, int y) => terrain.worldHeightAt(x + .5, y + .5);
  bool raised(int x, int y) => heightAt(x, y) >= upperHeight - 1e-6;
  final component = cells == null
      ? null
      : _raisedComponent(
          cells,
          raised,
          left: area.x,
          top: area.y,
          right: right,
          bottom: bottom,
        );
  if (component != null && component.isEmpty) {
    return HeightStepContours(
      SpatialIntentResolutionState.noSource,
      [],
      reason: 'cells_outside_step',
    );
  }
  bool upper(int x, int y) =>
      (component?.contains(GridPos(x: x, y: y)) ?? raised(x, y)) &&
      (!exactHeights || heightAt(x, y) <= upperHeight + 1e-6);
  bool lower(int x, int y) {
    final height = heightAt(x, y);
    return height <= lowerHeight + 1e-6 &&
        (!exactHeights || height >= lowerHeight - 1e-6);
  }

  final edges = <(GridPos, GridPos)>{};
  for (var y = area.y; y < bottom; y++) {
    for (var x = area.x; x < right; x++) {
      if (y > 0) {
        final a = GridPos(x: x, y: y), b = GridPos(x: x + 1, y: y);
        if (upper(x, y) && lower(x, y - 1)) edges.add((a, b));
        if (lower(x, y) && upper(x, y - 1)) edges.add((b, a));
      }
      if (x > 0) {
        final a = GridPos(x: x, y: y), b = GridPos(x: x, y: y + 1);
        if (upper(x, y) && lower(x - 1, y)) edges.add((b, a));
        if (lower(x, y) && upper(x - 1, y)) edges.add((a, b));
      }
      if (x == right - 1 && right < scene.width) {
        final a = GridPos(x: right, y: y), b = GridPos(x: right, y: y + 1);
        if (upper(right, y) && lower(right - 1, y)) edges.add((b, a));
        if (lower(right, y) && upper(right - 1, y)) edges.add((a, b));
      }
      if (y == bottom - 1 && bottom < scene.depth) {
        final a = GridPos(x: x, y: bottom), b = GridPos(x: x + 1, y: bottom);
        if (upper(x, bottom) && lower(x, bottom - 1)) edges.add((a, b));
        if (lower(x, bottom) && upper(x, bottom - 1)) edges.add((b, a));
      }
    }
  }
  if (edges.isEmpty) {
    return HeightStepContours(SpatialIntentResolutionState.noSource, []);
  }
  final outgoing = <GridPos, List<GridPos>>{}, incoming = <GridPos, int>{};
  for (final edge in edges) {
    outgoing.putIfAbsent(edge.$1, () => []).add(edge.$2);
    incoming.update(edge.$2, (value) => value + 1, ifAbsent: () => 1);
  }
  final ambiguous = {
    for (final entry in outgoing.entries)
      if (entry.value.length > 1) entry.key,
    for (final entry in incoming.entries)
      if (entry.value > 1) entry.key,
  }.toList()..sort(_compareCells);
  if (ambiguous.isNotEmpty) {
    return HeightStepContours(
      SpatialIntentResolutionState.ambiguous,
      [],
      ambiguousVertices: ambiguous,
      reason: 'branching_height_step',
    );
  }
  final remaining = Set<(GridPos, GridPos)>.from(edges),
      strokes = <List<GridPos>>[];
  final starts = outgoing.keys.toList()
    ..sort((a, b) {
      final openA = incoming.containsKey(a) ? 1 : 0,
          openB = incoming.containsKey(b) ? 1 : 0;
      return openA != openB ? openA.compareTo(openB) : _compareCells(a, b);
    });
  for (final start in starts) {
    var current = start;
    final stroke = <GridPos>[start];
    while (outgoing[current]?.isNotEmpty == true) {
      final next = outgoing[current]!.single;
      if (!remaining.remove((current, next))) break;
      stroke.add(next);
      current = next;
      if (current == start) break;
    }
    if (stroke.length > 1) strokes.add(stroke);
  }
  return HeightStepContours(SpatialIntentResolutionState.resolved, strokes);
}

List<({double lower, double upper})> terrainHeightStepsAround(
  MapData map,
  Iterable<GridPos> cells,
) {
  final scene = map.spatialScene!;
  double heightAt(int x, int y) => scene.worldHeightAt(x + .5, y + .5);
  final steps = <(double, double)>{};
  for (final cell in cells.toSet()) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= scene.width ||
        cell.y >= scene.depth) {
      continue;
    }
    final here = heightAt(cell.x, cell.y);
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final x = cell.x + dx, y = cell.y + dy;
      if (x < 0 || y < 0 || x >= scene.width || y >= scene.depth) continue;
      final there = heightAt(x, y);
      if ((here - there).abs() <= 1e-6) continue;
      steps.add(here < there ? (here, there) : (there, here));
    }
  }
  final sorted = steps.toList()
    ..sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
  return [for (final step in sorted) (lower: step.$1, upper: step.$2)];
}

Set<GridPos> _raisedComponent(
  Iterable<GridPos> cells,
  bool Function(int x, int y) raised, {
  required int left,
  required int top,
  required int right,
  required int bottom,
}) {
  bool inside(GridPos cell) =>
      cell.x >= left && cell.y >= top && cell.x < right && cell.y < bottom;
  final component = <GridPos>{};
  final pending = <GridPos>[
    for (final cell in cells)
      for (final (dx, dy) in const [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)])
        GridPos(x: cell.x + dx, y: cell.y + dy),
  ];
  while (pending.isNotEmpty) {
    final cell = pending.removeLast();
    if (!inside(cell) || component.contains(cell) || !raised(cell.x, cell.y)) {
      continue;
    }
    component.add(cell);
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      pending.add(GridPos(x: cell.x + dx, y: cell.y + dy));
    }
  }
  return component;
}

int _compareCells(GridPos a, GridPos b) =>
    a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x);

import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import 'smart_tile_layer_operations.dart';
import 'spatial_border_resolution_context.dart';

enum SpatialIntentResolutionState { resolved, ambiguous, noSource, unsupported }

final class MaterialNameResolution {
  MaterialNameResolution(Iterable<String> candidates)
    : candidates = List.unmodifiable(candidates.toSet().toList()..sort());
  final List<String> candidates;
  String? get materialId => candidates.length == 1 ? candidates.single : null;
  SpatialIntentResolutionState get status => candidates.isEmpty
      ? SpatialIntentResolutionState.noSource
      : candidates.length == 1
      ? SpatialIntentResolutionState.resolved
      : SpatialIntentResolutionState.ambiguous;
}

MaterialNameResolution resolveMaterialByName(
  ProjectManifest manifest,
  String name,
) {
  final normalized = _name(name);
  if (normalized.isEmpty)
    throw const FormatException('Choose a material name.');
  final exact = manifest.smartTileCatalog.materials
      .where((value) => value.id == name.trim())
      .toList();
  if (exact.isNotEmpty)
    return MaterialNameResolution(exact.map((value) => value.id));
  final presets = manifest.smartTileCatalog.presets.where(
    (preset) =>
        _name(preset.id) == normalized || _name(preset.name) == normalized,
  );
  final defaults = {for (final preset in presets) preset.defaultMaterialId};
  return MaterialNameResolution(
    manifest.smartTileCatalog.materials
        .where(
          (value) =>
              _name(value.name) == normalized ||
              _name(value.id) == normalized ||
              defaults.contains(value.id),
        )
        .map((value) => value.id),
  );
}

String _name(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

final class GroundFillStroke {
  GroundFillStroke(this.layerId, this.materialId, Iterable<GridPos> cells)
    : cells = List.unmodifiable(cells);
  final String layerId;
  final String materialId;
  final List<GridPos> cells;
}

final class GroundFillSuggestion {
  GroundFillSuggestion({
    required Iterable<GroundFillStroke> strokes,
    required Iterable<GridPos> ambiguousCells,
    required Iterable<GridPos> noSourceCells,
    required this.candidates,
  }) : strokes = List.unmodifiable(strokes),
       ambiguousCells = List.unmodifiable(ambiguousCells),
       noSourceCells = List.unmodifiable(noSourceCells);
  final List<GroundFillStroke> strokes;
  final List<GridPos> ambiguousCells;
  final List<GridPos> noSourceCells;
  final Map<GridPos, List<({String layerId, String materialId, int votes})>>
  candidates;
  SpatialIntentResolutionState get status => noSourceCells.isNotEmpty
      ? SpatialIntentResolutionState.noSource
      : ambiguousCells.isNotEmpty
      ? SpatialIntentResolutionState.ambiguous
      : SpatialIntentResolutionState.resolved;
}

GroundFillSuggestion suggestGroundFill(
  MapData map,
  Iterable<GridPos> cells, {
  String? layerId,
  String? materialId,
}) {
  final targets = cells.toSet().toList()..sort(_compareCells);
  if (targets.isEmpty || targets.length > 4096) {
    throw const FormatException(
      'Ground fill requires 1 to 4096 distinct cells.',
    );
  }
  final layers = map.layers
      .whereType<SmartTileLayer>()
      .where(
        (layer) =>
            layer.isVisible &&
            layer.opacity > 0 &&
            (layerId == null || layer.id == layerId),
      )
      .toList();
  if (layerId != null && layers.isEmpty)
    throw const FormatException('The selected ground layer is unavailable.');
  if (materialId != null && materialId.trim().isEmpty)
    throw const FormatException('Choose a material identity.');
  final groups = <(String, String), List<GridPos>>{};
  final ambiguous = <GridPos>[];
  final missing = <GridPos>[];
  final candidates =
      <GridPos, List<({String layerId, String materialId, int votes})>>{};
  for (final cell in targets) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= map.size.width ||
        cell.y >= map.size.height) {
      throw const FormatException('Ground fill cells must be inside the map.');
    }
    final votes = <(String, String), int>{};
    if (materialId != null) {
      for (final layer in layers) {
        votes[(layer.id, materialId)] = 1;
      }
    } else {
      for (final layer in layers) {
        for (final (dx, dy) in const [(0, -1), (-1, 0), (1, 0), (0, 1)]) {
          final x = cell.x + dx, y = cell.y + dy;
          if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height)
            continue;
          final material = smartTileMaterialIdAt(
            layer,
            mapSize: map.size,
            x: x,
            y: y,
          );
          if (material != null && material.isNotEmpty) {
            votes.update(
              (layer.id, material),
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }
    }
    final ranked =
        [
          for (final entry in votes.entries)
            (
              layerId: entry.key.$1,
              materialId: entry.key.$2,
              votes: entry.value,
            ),
        ]..sort(
          (a, b) => b.votes.compareTo(a.votes) != 0
              ? b.votes.compareTo(a.votes)
              : '${a.layerId}/${a.materialId}'.compareTo(
                  '${b.layerId}/${b.materialId}',
                ),
        );
    candidates[cell] = List.unmodifiable(ranked);
    if (ranked.isEmpty) {
      missing.add(cell);
      continue;
    }
    if (ranked.length > 1 && ranked[0].votes == ranked[1].votes) {
      ambiguous.add(cell);
      continue;
    }
    final first = ranked.first;
    groups.putIfAbsent((first.layerId, first.materialId), () => []).add(cell);
  }
  final keys = groups.keys.toList()
    ..sort((a, b) => '${a.$1}/${a.$2}'.compareTo('${b.$1}/${b.$2}'));
  return GroundFillSuggestion(
    strokes: [
      for (final key in keys) GroundFillStroke(key.$1, key.$2, groups[key]!),
    ],
    ambiguousCells: ambiguous,
    noSourceCells: missing,
    candidates: Map.unmodifiable(candidates),
  );
}

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
  final area = (x:region?.pos.x ?? 0,y:region?.pos.y ?? 0,
      width:region?.size.width ?? scene.width,height:region?.size.height ?? scene.depth);
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
  bool upper(int x, int y) =>
      terrain.worldHeightAt(x + .5, y + .5) >= upperHeight - 1e-6;
  bool lower(int x, int y) =>
      terrain.worldHeightAt(x + .5, y + .5) <= lowerHeight + 1e-6;
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
    }
  }
  if (edges.isEmpty)
    return HeightStepContours(SpatialIntentResolutionState.noSource, []);
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
  if (ambiguous.isNotEmpty)
    return HeightStepContours(
      SpatialIntentResolutionState.ambiguous,
      [],
      ambiguousVertices: ambiguous,
      reason: 'branching_height_step',
    );
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

int _compareCells(GridPos a, GridPos b) =>
    a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x);

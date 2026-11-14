import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import 'smart_tile_layer_operations.dart';

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
  if (normalized.isEmpty) {
    throw const FormatException('Choose a material name.');
  }
  final exact = manifest.smartTileCatalog.materials
      .where((value) => value.id == name.trim())
      .toList();
  if (exact.isNotEmpty) {
    return MaterialNameResolution(exact.map((value) => value.id));
  }
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
  if (layerId != null && layers.isEmpty) {
    throw const FormatException('The selected ground layer is unavailable.');
  }
  if (materialId != null && materialId.trim().isEmpty) {
    throw const FormatException('Choose a material identity.');
  }
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
          if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
            continue;
          }
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

int _compareCells(GridPos a, GridPos b) =>
    a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x);

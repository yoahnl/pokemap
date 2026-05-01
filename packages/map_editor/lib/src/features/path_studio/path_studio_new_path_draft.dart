import 'package:map_core/map_core.dart';

enum PathStudioNewPathDraftIssueCode {
  nameRequired,
  tilesetNotConfigured,
  cellsNotConfigured,
}

/// Tuile V0 assignée à une cellule du centre.
///
/// Le Path Studio ne gère pas encore les animations ni les frames multiples.
/// Cette valeur locale représente donc exactement une frame statique : un
/// tileset projet et une coordonnée de tuile dans cet atlas.
final class PathStudioNewPathDraftTile {
  const PathStudioNewPathDraftTile({
    required this.tilesetId,
    required this.sourceX,
    required this.sourceY,
  })  : assert(sourceX >= 0),
        assert(sourceY >= 0);

  final String tilesetId;
  final int sourceX;
  final int sourceY;

  String get coordinateLabel => '$sourceX,$sourceY';

  TilesetVisualFrame toFrame() {
    return TilesetVisualFrame(
      tilesetId: tilesetId,
      source: TilesetSourceRect(x: sourceX, y: sourceY),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraftTile &&
            tilesetId == other.tilesetId &&
            sourceX == other.sourceX &&
            sourceY == other.sourceY;
  }

  @override
  int get hashCode => Object.hash(tilesetId, sourceX, sourceY);
}

final class PathStudioNewPathDraftCell {
  const PathStudioNewPathDraftCell({
    required this.localX,
    required this.localY,
    required this.label,
    this.tile,
  });

  final int localX;
  final int localY;
  final String label;
  final PathStudioNewPathDraftTile? tile;

  bool get isConfigured => tile != null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraftCell &&
            localX == other.localX &&
            localY == other.localY &&
            label == other.label &&
            tile == other.tile;
  }

  @override
  int get hashCode => Object.hash(localX, localY, label, tile);
}

final class PathStudioNewPathDraft {
  PathStudioNewPathDraft({
    required this.id,
    required this.name,
    this.tilesetId,
    required this.centerWidth,
    required this.centerHeight,
    required this.selectedCellX,
    required this.selectedCellY,
    required this.selectedVariant,
    required this.selectedTarget,
    required this.surfaceKind,
    required this.isDirty,
    Map<String, PathStudioNewPathDraftTile> assignedTiles = const {},
    Map<TerrainPathVariant, PathStudioNewPathDraftTile> variantTiles = const {},
  })  : assert(centerWidth > 0),
        assert(centerHeight > 0),
        assert(selectedCellX >= 0 && selectedCellX < centerWidth),
        assert(selectedCellY >= 0 && selectedCellY < centerHeight),
        assert(
          _requiredVariants.contains(selectedVariant),
        ),
        assignedTiles = Map<String, PathStudioNewPathDraftTile>.unmodifiable(
          assignedTiles,
        ),
        variantTiles =
            Map<TerrainPathVariant, PathStudioNewPathDraftTile>.unmodifiable(
          variantTiles,
        );

  final String id;
  final String name;
  final String? tilesetId;
  final int centerWidth;
  final int centerHeight;
  final int selectedCellX;
  final int selectedCellY;
  final TerrainPathVariant selectedVariant;
  final PathStudioNewPathDraftSelectionTarget selectedTarget;
  final PathSurfaceKind surfaceKind;
  final bool isDirty;

  /// Assignations locales des cellules du centre, indexées par `x,y`.
  ///
  /// Le map est immuable pour éviter qu'un widget ou test modifie le brouillon
  /// en place. Les helpers de ce fichier retournent toujours une nouvelle
  /// instance de [PathStudioNewPathDraft].
  final Map<String, PathStudioNewPathDraftTile> assignedTiles;
  final Map<TerrainPathVariant, PathStudioNewPathDraftTile> variantTiles;

  static final List<TerrainPathVariant> requiredVariants =
      List<TerrainPathVariant>.unmodifiable(_requiredVariants);

  String get centerPatternLabel => '$centerWidth×$centerHeight';

  int get centerCellCount => centerWidth * centerHeight;

  int get configuredCellCount =>
      cells.where((cell) => cell.isConfigured).length;

  int get requiredVariantCount => requiredVariants.length;

  int get configuredVariantCount =>
      requiredVariants.where((variant) => variantTiles[variant] != null).length;

  bool get allCenterCellsConfigured => configuredCellCount == centerCellCount;

  bool get allRequiredVariantsConfigured =>
      configuredVariantCount == requiredVariantCount;

  List<PathStudioNewPathDraftCell> get cells {
    final result = <PathStudioNewPathDraftCell>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < centerHeight; y += 1) {
      for (var x = 0; x < centerWidth; x += 1) {
        result.add(
          PathStudioNewPathDraftCell(
            localX: x,
            localY: y,
            label: String.fromCharCode(labelCode),
            tile: assignedTiles[_cellKey(x, y)],
          ),
        );
        labelCode += 1;
      }
    }
    return List<PathStudioNewPathDraftCell>.unmodifiable(result);
  }

  PathStudioNewPathDraftCell get selectedCell {
    return cells.firstWhere(
      (cell) => cell.localX == selectedCellX && cell.localY == selectedCellY,
    );
  }

  PathStudioNewPathDraftTile? get selectedVariantTile =>
      variantTiles[selectedVariant];

  List<PathStudioNewPathDraftIssueCode> get issues {
    final result = <PathStudioNewPathDraftIssueCode>[];
    if (name.trim().isEmpty) {
      result.add(PathStudioNewPathDraftIssueCode.nameRequired);
    }
    if (tilesetId == null || tilesetId!.isEmpty) {
      result.add(PathStudioNewPathDraftIssueCode.tilesetNotConfigured);
    }
    if (!allCenterCellsConfigured) {
      result.add(PathStudioNewPathDraftIssueCode.cellsNotConfigured);
    }
    return List<PathStudioNewPathDraftIssueCode>.unmodifiable(result);
  }

  PathStudioNewPathDraft copyWith({
    String? id,
    String? name,
    Object? tilesetId = _sentinel,
    int? centerWidth,
    int? centerHeight,
    int? selectedCellX,
    int? selectedCellY,
    TerrainPathVariant? selectedVariant,
    PathStudioNewPathDraftSelectionTarget? selectedTarget,
    PathSurfaceKind? surfaceKind,
    bool? isDirty,
    Map<String, PathStudioNewPathDraftTile>? assignedTiles,
    Map<TerrainPathVariant, PathStudioNewPathDraftTile>? variantTiles,
  }) {
    return PathStudioNewPathDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      tilesetId: identical(tilesetId, _sentinel)
          ? this.tilesetId
          : tilesetId as String?,
      centerWidth: centerWidth ?? this.centerWidth,
      centerHeight: centerHeight ?? this.centerHeight,
      selectedCellX: selectedCellX ?? this.selectedCellX,
      selectedCellY: selectedCellY ?? this.selectedCellY,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedTarget: selectedTarget ?? this.selectedTarget,
      surfaceKind: surfaceKind ?? this.surfaceKind,
      isDirty: isDirty ?? this.isDirty,
      assignedTiles: assignedTiles ?? this.assignedTiles,
      variantTiles: variantTiles ?? this.variantTiles,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraft &&
            id == other.id &&
            name == other.name &&
            tilesetId == other.tilesetId &&
            centerWidth == other.centerWidth &&
            centerHeight == other.centerHeight &&
            selectedCellX == other.selectedCellX &&
            selectedCellY == other.selectedCellY &&
            selectedVariant == other.selectedVariant &&
            selectedTarget == other.selectedTarget &&
            surfaceKind == other.surfaceKind &&
            isDirty == other.isDirty &&
            _assignedTileMapsEqual(assignedTiles, other.assignedTiles) &&
            _variantTileMapsEqual(variantTiles, other.variantTiles);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        tilesetId,
        centerWidth,
        centerHeight,
        selectedCellX,
        selectedCellY,
        selectedVariant,
        selectedTarget,
        surfaceKind,
        isDirty,
        _assignedTileMapHash(assignedTiles),
        _variantTileMapHash(variantTiles),
      );
}

const _sentinel = Object();

PathStudioNewPathDraft createInitialPathStudioNewPathDraft() {
  return PathStudioNewPathDraft(
    id: 'draft-new-path',
    name: 'Nouveau chemin',
    centerWidth: 1,
    centerHeight: 1,
    selectedCellX: 0,
    selectedCellY: 0,
    selectedVariant: _requiredVariants.first,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.centerCell,
    surfaceKind: PathSurfaceKind.path,
    isDirty: true,
  );
}

PathStudioNewPathDraft resizePathStudioNewPathDraftCenter({
  required PathStudioNewPathDraft draft,
  required int width,
  required int height,
}) {
  if (width <= 0 || height <= 0) {
    throw ArgumentError.value('$width×$height', 'size', 'must be positive');
  }
  return draft.copyWith(
    centerWidth: width,
    centerHeight: height,
    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
    isDirty: true,
    assignedTiles: _trimAssignedTilesForSize(
      draft.assignedTiles,
      width: width,
      height: height,
    ),
  );
}

PathStudioNewPathDraft renamePathStudioNewPathDraft(
  PathStudioNewPathDraft draft,
  String name,
) {
  return draft.copyWith(name: name, isDirty: true);
}

PathStudioNewPathDraft selectPathStudioNewPathDraftSurfaceKind({
  required PathStudioNewPathDraft draft,
  required PathSurfaceKind surfaceKind,
}) {
  return draft.copyWith(surfaceKind: surfaceKind, isDirty: true);
}

PathStudioNewPathDraft selectPathStudioNewPathDraftTileset(
  PathStudioNewPathDraft draft,
  String tilesetId,
) {
  return draft.copyWith(
    tilesetId: tilesetId.isEmpty ? null : tilesetId,
    assignedTiles: const {},
    variantTiles: const {},
    isDirty: true,
  );
}

PathStudioNewPathDraft assignPathStudioNewPathDraftCellTile({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
  required int sourceX,
  required int sourceY,
}) {
  final tilesetId = draft.tilesetId;
  if (tilesetId == null || tilesetId.isEmpty) {
    throw StateError('A tileset must be selected before assigning a tile.');
  }
  if (sourceX < 0) {
    throw ArgumentError.value(sourceX, 'sourceX', 'must be non-negative');
  }
  if (sourceY < 0) {
    throw ArgumentError.value(sourceY, 'sourceY', 'must be non-negative');
  }
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);

  final nextTiles = Map<String, PathStudioNewPathDraftTile>.from(
    draft.assignedTiles,
  );
  nextTiles[_cellKey(localX, localY)] = PathStudioNewPathDraftTile(
    tilesetId: tilesetId,
    sourceX: sourceX,
    sourceY: sourceY,
  );
  return draft.copyWith(assignedTiles: nextTiles, isDirty: true);
}

PathStudioNewPathDraft clearPathStudioNewPathDraftCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);

  final nextTiles = Map<String, PathStudioNewPathDraftTile>.from(
    draft.assignedTiles,
  )..remove(_cellKey(localX, localY));
  return draft.copyWith(assignedTiles: nextTiles, isDirty: true);
}

PathStudioNewPathDraft selectPathStudioNewPathDraftCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
  return draft.copyWith(
    selectedCellX: localX,
    selectedCellY: localY,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.centerCell,
  );
}

PathStudioNewPathDraft selectPathStudioNewPathDraftVariant({
  required PathStudioNewPathDraft draft,
  required TerrainPathVariant variant,
}) {
  if (!_requiredVariants.contains(variant)) {
    throw ArgumentError.value(
      variant,
      'variant',
      'must belong to required variants',
    );
  }
  return draft.copyWith(
    selectedVariant: variant,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.variant,
  );
}

PathStudioNewPathDraft assignPathStudioNewPathDraftVariantTile({
  required PathStudioNewPathDraft draft,
  required TerrainPathVariant variant,
  required int sourceX,
  required int sourceY,
}) {
  final tilesetId = draft.tilesetId;
  if (tilesetId == null || tilesetId.isEmpty) {
    throw StateError('A tileset must be selected before assigning a tile.');
  }
  if (!_requiredVariants.contains(variant)) {
    throw ArgumentError.value(
      variant,
      'variant',
      'must belong to required variants',
    );
  }
  if (sourceX < 0) {
    throw ArgumentError.value(sourceX, 'sourceX', 'must be non-negative');
  }
  if (sourceY < 0) {
    throw ArgumentError.value(sourceY, 'sourceY', 'must be non-negative');
  }
  final nextTiles = Map<TerrainPathVariant, PathStudioNewPathDraftTile>.from(
    draft.variantTiles,
  );
  nextTiles[variant] = PathStudioNewPathDraftTile(
    tilesetId: tilesetId,
    sourceX: sourceX,
    sourceY: sourceY,
  );
  return draft.copyWith(
    variantTiles: nextTiles,
    selectedVariant: variant,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.variant,
    isDirty: true,
  );
}

PathStudioNewPathDraft clearPathStudioNewPathDraftVariant({
  required PathStudioNewPathDraft draft,
  required TerrainPathVariant variant,
}) {
  if (!_requiredVariants.contains(variant)) {
    throw ArgumentError.value(
      variant,
      'variant',
      'must belong to required variants',
    );
  }
  final nextTiles = Map<TerrainPathVariant, PathStudioNewPathDraftTile>.from(
    draft.variantTiles,
  )..remove(variant);
  return draft.copyWith(
    variantTiles: nextTiles,
    selectedVariant: variant,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.variant,
    isDirty: true,
  );
}

String _cellKey(int localX, int localY) => '$localX,$localY';

void _validateCellCoordinates({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  if (localX < 0 || localX >= draft.centerWidth) {
    throw RangeError.range(localX, 0, draft.centerWidth - 1, 'localX');
  }
  if (localY < 0 || localY >= draft.centerHeight) {
    throw RangeError.range(localY, 0, draft.centerHeight - 1, 'localY');
  }
}

Map<String, PathStudioNewPathDraftTile> _trimAssignedTilesForSize(
  Map<String, PathStudioNewPathDraftTile> assignedTiles, {
  required int width,
  required int height,
}) {
  final kept = <String, PathStudioNewPathDraftTile>{};
  for (final entry in assignedTiles.entries) {
    final parts = entry.key.split(',');
    if (parts.length != 2) {
      continue;
    }
    final localX = int.tryParse(parts[0]);
    final localY = int.tryParse(parts[1]);
    if (localX == null || localY == null) {
      continue;
    }
    if (localX >= 0 && localX < width && localY >= 0 && localY < height) {
      kept[entry.key] = entry.value;
    }
  }
  return kept;
}

bool _assignedTileMapsEqual(
  Map<String, PathStudioNewPathDraftTile> left,
  Map<String, PathStudioNewPathDraftTile> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _assignedTileMapHash(Map<String, PathStudioNewPathDraftTile> tiles) {
  final entries = tiles.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

bool _variantTileMapsEqual(
  Map<TerrainPathVariant, PathStudioNewPathDraftTile> left,
  Map<TerrainPathVariant, PathStudioNewPathDraftTile> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _variantTileMapHash(
    Map<TerrainPathVariant, PathStudioNewPathDraftTile> tiles) {
  final entries = tiles.entries.toList()
    ..sort((left, right) => left.key.index.compareTo(right.key.index));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

enum PathStudioNewPathDraftSelectionTarget {
  centerCell,
  variant,
}

final List<TerrainPathVariant> _requiredVariants = List.unmodifiable(
  TerrainPathVariant.values
      .where((variant) => variant != TerrainPathVariant.cross),
);

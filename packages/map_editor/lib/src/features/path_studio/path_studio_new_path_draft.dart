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

  TilesetVisualFrame toFrame({
    int? durationMs,
  }) {
    return TilesetVisualFrame(
      tilesetId: tilesetId,
      source: TilesetSourceRect(x: sourceX, y: sourceY),
      durationMs: durationMs,
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

final class PathStudioNewPathDraftCenterFrame {
  const PathStudioNewPathDraftCenterFrame({
    required this.tile,
    required this.durationMs,
  }) : assert(durationMs > 0);

  final PathStudioNewPathDraftTile tile;
  final int durationMs;

  TilesetVisualFrame toFrame() {
    return tile.toFrame(durationMs: durationMs);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraftCenterFrame &&
            tile == other.tile &&
            durationMs == other.durationMs;
  }

  @override
  int get hashCode => Object.hash(tile, durationMs);
}

final class PathStudioNewPathDraftCell {
  const PathStudioNewPathDraftCell({
    required this.localX,
    required this.localY,
    required this.label,
    this.frames = const [],
    this.selectedFrameIndex = 0,
  });

  final int localX;
  final int localY;
  final String label;
  final List<PathStudioNewPathDraftCenterFrame> frames;
  final int selectedFrameIndex;

  PathStudioNewPathDraftTile? get tile => selectedFrame?.tile;

  PathStudioNewPathDraftCenterFrame? get selectedFrame {
    if (frames.isEmpty) {
      return null;
    }
    return frames[selectedFrameIndex.clamp(0, frames.length - 1)];
  }

  bool get isConfigured => frames.isNotEmpty;

  bool get isAnimated => frames.length > 1;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraftCell &&
            localX == other.localX &&
            localY == other.localY &&
            label == other.label &&
            selectedFrameIndex == other.selectedFrameIndex &&
            _centerFrameListsEqual(frames, other.frames);
  }

  @override
  int get hashCode => Object.hash(
        localX,
        localY,
        label,
        selectedFrameIndex,
        Object.hashAll(frames),
      );
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
    Map<String, List<PathStudioNewPathDraftCenterFrame>> centerCellFrames =
        const {},
    Map<TerrainPathVariant, PathStudioNewPathDraftTile> variantTiles = const {},
    this.selectedCenterFrameIndex = 0,
  })  : assert(centerWidth > 0),
        assert(centerHeight > 0),
        assert(selectedCellX >= 0 && selectedCellX < centerWidth),
        assert(selectedCellY >= 0 && selectedCellY < centerHeight),
        assert(selectedCenterFrameIndex >= 0),
        assert(
          _requiredVariants.contains(selectedVariant),
        ),
        centerCellFrames =
            Map<String, List<PathStudioNewPathDraftCenterFrame>>.unmodifiable(
          centerCellFrames.map(
            (key, value) => MapEntry(
              key,
              List<PathStudioNewPathDraftCenterFrame>.unmodifiable(value),
            ),
          ),
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
  final int selectedCenterFrameIndex;

  /// Assignations locales des cellules du centre, indexées par `x,y`.
  ///
  /// Le map est immuable pour éviter qu'un widget ou test modifie le brouillon
  /// en place. Les helpers de ce fichier retournent toujours une nouvelle
  /// instance de [PathStudioNewPathDraft].
  final Map<String, List<PathStudioNewPathDraftCenterFrame>> centerCellFrames;
  final Map<TerrainPathVariant, PathStudioNewPathDraftTile> variantTiles;

  static final List<TerrainPathVariant> requiredVariants =
      List<TerrainPathVariant>.unmodifiable(_requiredVariants);

  String get centerPatternLabel => '$centerWidth×$centerHeight';

  int get centerCellCount => centerWidth * centerHeight;

  int get configuredCellCount =>
      cells.where((cell) => cell.isConfigured).length;

  int get totalCenterFrameCount =>
      cells.fold<int>(0, (total, cell) => total + cell.frames.length);

  int get animatedCenterCellCount =>
      cells.where((cell) => cell.frames.length > 1).length;

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
            frames: centerCellFrames[_cellKey(x, y)] ?? const [],
            selectedFrameIndex: selectedCellX == x && selectedCellY == y
                ? selectedCenterFrameIndex
                : 0,
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
    Map<String, List<PathStudioNewPathDraftCenterFrame>>? centerCellFrames,
    Map<TerrainPathVariant, PathStudioNewPathDraftTile>? variantTiles,
    int? selectedCenterFrameIndex,
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
      centerCellFrames: centerCellFrames ?? this.centerCellFrames,
      variantTiles: variantTiles ?? this.variantTiles,
      selectedCenterFrameIndex:
          selectedCenterFrameIndex ?? this.selectedCenterFrameIndex,
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
            selectedCenterFrameIndex == other.selectedCenterFrameIndex &&
            _centerCellFrameMapsEqual(centerCellFrames, other.centerCellFrames) &&
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
        selectedCenterFrameIndex,
        _centerCellFrameMapHash(centerCellFrames),
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
    selectedCenterFrameIndex: 0,
    isDirty: true,
    centerCellFrames: _trimCenterCellFramesForSize(
      draft.centerCellFrames,
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
    centerCellFrames: const {},
    variantTiles: const {},
    selectedCenterFrameIndex: 0,
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

  final cellKey = _cellKey(localX, localY);
  final nextCellFrames =
      Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.centerCellFrames,
  );
  final currentFrames =
      List<PathStudioNewPathDraftCenterFrame>.from(nextCellFrames[cellKey] ?? const []);
  final selectedIndex = currentFrames.isEmpty
      ? 0
      : draft.selectedCenterFrameIndex.clamp(0, currentFrames.length - 1);
  final nextFrame = PathStudioNewPathDraftCenterFrame(
    tile: PathStudioNewPathDraftTile(
      tilesetId: tilesetId,
      sourceX: sourceX,
      sourceY: sourceY,
    ),
    durationMs: currentFrames.isEmpty
        ? defaultPlacedElementAnimationFrameDurationMs
        : currentFrames[selectedIndex].durationMs,
  );
  if (currentFrames.isEmpty) {
    currentFrames.add(nextFrame);
  } else {
    currentFrames[selectedIndex] = nextFrame;
  }
  nextCellFrames[cellKey] = currentFrames;
  return draft.copyWith(
    centerCellFrames: nextCellFrames,
    selectedCenterFrameIndex: selectedIndex,
    isDirty: true,
  );
}

PathStudioNewPathDraft appendPathStudioNewPathDraftCenterFrame({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
  final cellKey = _cellKey(localX, localY);
  final nextCellFrames =
      Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.centerCellFrames,
  );
  final currentFrames =
      List<PathStudioNewPathDraftCenterFrame>.from(nextCellFrames[cellKey] ?? const []);
  if (currentFrames.isEmpty) {
    return draft;
  }
  final selectedIndex =
      draft.selectedCenterFrameIndex.clamp(0, currentFrames.length - 1);
  final sourceFrame = currentFrames[selectedIndex];
  currentFrames.add(
    PathStudioNewPathDraftCenterFrame(
      tile: PathStudioNewPathDraftTile(
        tilesetId: sourceFrame.tile.tilesetId,
        sourceX: sourceFrame.tile.sourceX,
        sourceY: sourceFrame.tile.sourceY,
      ),
      durationMs: sourceFrame.durationMs,
    ),
  );
  nextCellFrames[cellKey] = currentFrames;
  return draft.copyWith(
    centerCellFrames: nextCellFrames,
    selectedCenterFrameIndex: currentFrames.length - 1,
    isDirty: true,
  );
}

PathStudioNewPathDraft removePathStudioNewPathDraftCenterFrame({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
  required int frameIndex,
}) {
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
  final cellKey = _cellKey(localX, localY);
  final nextCellFrames =
      Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.centerCellFrames,
  );
  final currentFrames =
      List<PathStudioNewPathDraftCenterFrame>.from(nextCellFrames[cellKey] ?? const []);
  if (frameIndex < 0 || frameIndex >= currentFrames.length) {
    throw RangeError.range(frameIndex, 0, currentFrames.length - 1, 'frameIndex');
  }
  currentFrames.removeAt(frameIndex);
  if (currentFrames.isEmpty) {
    nextCellFrames.remove(cellKey);
  } else {
    nextCellFrames[cellKey] = currentFrames;
  }
  final nextSelectedIndex = currentFrames.isEmpty
      ? 0
      : draft.selectedCenterFrameIndex.clamp(0, currentFrames.length - 1);
  return draft.copyWith(
    centerCellFrames: nextCellFrames,
    selectedCenterFrameIndex: nextSelectedIndex,
    isDirty: true,
  );
}

PathStudioNewPathDraft selectPathStudioNewPathDraftCenterFrame({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
  required int frameIndex,
}) {
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
  final frames = draft.centerCellFrames[_cellKey(localX, localY)] ?? const [];
  if (frameIndex < 0 || frameIndex >= frames.length) {
    throw RangeError.range(frameIndex, 0, frames.length - 1, 'frameIndex');
  }
  return draft.copyWith(
    selectedCellX: localX,
    selectedCellY: localY,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.centerCell,
    selectedCenterFrameIndex: frameIndex,
  );
}

PathStudioNewPathDraft updatePathStudioNewPathDraftCenterFrameDuration({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
  required int frameIndex,
  required int durationMs,
}) {
  if (durationMs <= 0) {
    throw ArgumentError.value(durationMs, 'durationMs', 'must be positive');
  }
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
  final cellKey = _cellKey(localX, localY);
  final nextCellFrames =
      Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.centerCellFrames,
  );
  final currentFrames =
      List<PathStudioNewPathDraftCenterFrame>.from(nextCellFrames[cellKey] ?? const []);
  if (frameIndex < 0 || frameIndex >= currentFrames.length) {
    throw RangeError.range(frameIndex, 0, currentFrames.length - 1, 'frameIndex');
  }
  final frame = currentFrames[frameIndex];
  currentFrames[frameIndex] = PathStudioNewPathDraftCenterFrame(
    tile: PathStudioNewPathDraftTile(
      tilesetId: frame.tile.tilesetId,
      sourceX: frame.tile.sourceX,
      sourceY: frame.tile.sourceY,
    ),
    durationMs: durationMs,
  );
  nextCellFrames[cellKey] = currentFrames;
  return draft.copyWith(centerCellFrames: nextCellFrames, isDirty: true);
}

PathStudioNewPathDraft clearPathStudioNewPathDraftCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);

  final nextCellFrames =
      Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.centerCellFrames,
  )..remove(_cellKey(localX, localY));
  return draft.copyWith(
    centerCellFrames: nextCellFrames,
    selectedCenterFrameIndex: 0,
    isDirty: true,
  );
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
    selectedCenterFrameIndex: 0,
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

Map<String, List<PathStudioNewPathDraftCenterFrame>> _trimCenterCellFramesForSize(
  Map<String, List<PathStudioNewPathDraftCenterFrame>> centerCellFrames, {
  required int width,
  required int height,
}) {
  final kept = <String, List<PathStudioNewPathDraftCenterFrame>>{};
  for (final entry in centerCellFrames.entries) {
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
      kept[entry.key] = List<PathStudioNewPathDraftCenterFrame>.unmodifiable(
        entry.value,
      );
    }
  }
  return kept;
}

bool _centerCellFrameMapsEqual(
  Map<String, List<PathStudioNewPathDraftCenterFrame>> left,
  Map<String, List<PathStudioNewPathDraftCenterFrame>> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    final otherFrames = right[entry.key];
    if (otherFrames == null || !_centerFrameListsEqual(entry.value, otherFrames)) {
      return false;
    }
  }
  return true;
}

int _centerCellFrameMapHash(
  Map<String, List<PathStudioNewPathDraftCenterFrame>> cells,
) {
  final entries = cells.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, Object.hashAll(entry.value))),
  );
}

bool _centerFrameListsEqual(
  List<PathStudioNewPathDraftCenterFrame> left,
  List<PathStudioNewPathDraftCenterFrame> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
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

import 'package:map_core/map_core.dart';

enum PathStudioNewPathDraftIssueCode {
  nameRequired,
  tilesetNotConfigured,
  cellsNotConfigured,
}

enum PathStudioPathDraftMode {
  create,
  edit,
}

final class PathStudioPathDraftSource {
  const PathStudioPathDraftSource({
    required this.originalBasePathPresetId,
    required this.originalPathPatternPresetId,
  });

  final String originalBasePathPresetId;
  final String originalPathPatternPresetId;
}

/// Tuile V0 assignée à une cellule du centre.
///
/// Chaque cellule dispose d’une timeline locale (une ou plusieurs frames). Cette
/// valeur encapsule le tileset projet et la coordonnée de tuile dans l’atlas.
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
    required this.basePathPresetId,
    required this.pathPatternPresetId,
    required this.name,
    this.tilesetId,
    required this.centerWidth,
    required this.centerHeight,
    required this.selectedCellX,
    required this.selectedCellY,
    required this.selectedVariant,
    required this.selectedTarget,
    required this.surfaceKind,
    required this.mode,
    this.source,
    required this.isDirty,
    this.preservedVariantMappings = const [],
    Map<String, List<PathStudioNewPathDraftCenterFrame>> centerCellFrames =
        const {},
    Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>> variantCellFrames = const {},
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
        variantCellFrames =
            Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>.unmodifiable(
          variantCellFrames.map(
            (key, value) => MapEntry(
              key,
              List<PathStudioNewPathDraftCenterFrame>.unmodifiable(value),
            ),
          ),
        );

  final String basePathPresetId;
  final String pathPatternPresetId;
  final String name;
  final String? tilesetId;
  final int centerWidth;
  final int centerHeight;
  final int selectedCellX;
  final int selectedCellY;
  final TerrainPathVariant selectedVariant;
  final PathStudioNewPathDraftSelectionTarget selectedTarget;
  final PathSurfaceKind surfaceKind;
  final PathStudioPathDraftMode mode;
  final PathStudioPathDraftSource? source;
  final bool isDirty;
  final int selectedCenterFrameIndex;
  final List<PathPresetVariantMapping> preservedVariantMappings;

  /// Assignations locales des cellules du centre, indexées par `x,y`.
  ///
  /// Le map est immuable pour éviter qu'un widget ou test modifie le brouillon
  /// en place. Les helpers de ce fichier retournent toujours une nouvelle
  /// instance de [PathStudioNewPathDraft].
  final Map<String, List<PathStudioNewPathDraftCenterFrame>> centerCellFrames;
  final Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>> variantCellFrames;

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
      requiredVariants.where((variant) => variantCellFrames[variant]?.isNotEmpty ?? false).length;

  String get id => basePathPresetId;

  bool get isEditMode => mode == PathStudioPathDraftMode.edit;

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

  List<PathStudioNewPathDraftCenterFrame> get selectedTargetFrames {
    if (selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell) {
      return centerCellFrames[_cellKey(selectedCellX, selectedCellY)] ?? const [];
    } else {
      return variantCellFrames[selectedVariant] ?? const [];
    }
  }

  PathStudioNewPathDraftCenterFrame? get selectedTargetFrame {
    final frames = selectedTargetFrames;
    if (frames.isEmpty) return null;
    return frames[selectedCenterFrameIndex.clamp(0, frames.length - 1)];
  }

  PathStudioNewPathDraftTile? get selectedVariantTile =>
      variantCellFrames[selectedVariant]?.firstOrNull?.tile;

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
    String? basePathPresetId,
    String? pathPatternPresetId,
    String? name,
    Object? tilesetId = _sentinel,
    int? centerWidth,
    int? centerHeight,
    int? selectedCellX,
    int? selectedCellY,
    TerrainPathVariant? selectedVariant,
    PathStudioNewPathDraftSelectionTarget? selectedTarget,
    PathSurfaceKind? surfaceKind,
    PathStudioPathDraftMode? mode,
    Object? source = _sentinel,
    bool? isDirty,
    List<PathPresetVariantMapping>? preservedVariantMappings,
    Map<String, List<PathStudioNewPathDraftCenterFrame>>? centerCellFrames,
    Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>? variantCellFrames,
    int? selectedCenterFrameIndex,
  }) {
    return PathStudioNewPathDraft(
      basePathPresetId: basePathPresetId ?? this.basePathPresetId,
      pathPatternPresetId: pathPatternPresetId ?? this.pathPatternPresetId,
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
      mode: mode ?? this.mode,
      source: identical(source, _sentinel)
          ? this.source
          : source as PathStudioPathDraftSource?,
      isDirty: isDirty ?? this.isDirty,
      preservedVariantMappings:
          preservedVariantMappings ?? this.preservedVariantMappings,
      centerCellFrames: centerCellFrames ?? this.centerCellFrames,
      variantCellFrames: variantCellFrames ?? this.variantCellFrames,
      selectedCenterFrameIndex:
          selectedCenterFrameIndex ?? this.selectedCenterFrameIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraft &&
            basePathPresetId == other.basePathPresetId &&
            pathPatternPresetId == other.pathPatternPresetId &&
            name == other.name &&
            tilesetId == other.tilesetId &&
            centerWidth == other.centerWidth &&
            centerHeight == other.centerHeight &&
            selectedCellX == other.selectedCellX &&
            selectedCellY == other.selectedCellY &&
            selectedVariant == other.selectedVariant &&
            selectedTarget == other.selectedTarget &&
            surfaceKind == other.surfaceKind &&
            mode == other.mode &&
            source?.originalBasePathPresetId ==
                other.source?.originalBasePathPresetId &&
            source?.originalPathPatternPresetId ==
                other.source?.originalPathPatternPresetId &&
            isDirty == other.isDirty &&
            selectedCenterFrameIndex == other.selectedCenterFrameIndex &&
            _pathPresetVariantMappingsEqual(
              preservedVariantMappings,
              other.preservedVariantMappings,
            ) &&
            _centerCellFrameMapsEqual(
                centerCellFrames, other.centerCellFrames) &&
            _variantCellFramesMapsEqual(variantCellFrames, other.variantCellFrames);
  }

  @override
  int get hashCode => Object.hash(
        basePathPresetId,
        pathPatternPresetId,
        name,
        tilesetId,
        centerWidth,
        centerHeight,
        selectedCellX,
        selectedCellY,
        selectedVariant,
        selectedTarget,
        surfaceKind,
        mode,
        source?.originalBasePathPresetId,
        source?.originalPathPatternPresetId,
        isDirty,
        selectedCenterFrameIndex,
        Object.hashAll(
          preservedVariantMappings.map(
            (mapping) => Object.hash(
              mapping.variant,
              Object.hashAll(mapping.frames),
            ),
          ),
        ),
        _centerCellFrameMapHash(centerCellFrames),
        _variantCellFramesMapHash(variantCellFrames),
      );
}

const _sentinel = Object();

PathStudioNewPathDraft createInitialPathStudioNewPathDraft() {
  return PathStudioNewPathDraft(
    basePathPresetId: 'draft-new-path',
    pathPatternPresetId: 'draft-new-path-pattern',
    name: 'Nouveau chemin',
    centerWidth: 1,
    centerHeight: 1,
    selectedCellX: 0,
    selectedCellY: 0,
    selectedVariant: _requiredVariants.first,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.centerCell,
    surfaceKind: PathSurfaceKind.path,
    mode: PathStudioPathDraftMode.create,
    // Lot PathPattern-40 : pas « dirty » tant que l’utilisateur n’a pas modifié.
    isDirty: false,
  );
}

PathStudioNewPathDraft createPathStudioEditDraftFromExistingPathPattern({
  required ProjectPathPatternPreset pathPatternPreset,
  required ProjectPathPreset basePathPreset,
}) {
  final centerCellFrames = <String, List<PathStudioNewPathDraftCenterFrame>>{};
  for (final cell in pathPatternPreset.centerPattern.cells) {
    centerCellFrames[_cellKey(cell.localX, cell.localY)] = [
      for (final frame in cell.frames)
        PathStudioNewPathDraftCenterFrame(
          tile: PathStudioNewPathDraftTile(
            tilesetId: frame.tilesetId.trim().isEmpty
                ? basePathPreset.tilesetId
                : frame.tilesetId,
            sourceX: frame.source.x,
            sourceY: frame.source.y,
          ),
          durationMs:
              frame.durationMs ?? defaultPlacedElementAnimationFrameDurationMs,
        ),
    ];
  }

  final variantCellFrames = <TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>{};
  final preservedVariantMappings = <PathPresetVariantMapping>[];
  for (final mapping in basePathPreset.variants) {
    if (_requiredVariants.contains(mapping.variant) &&
        mapping.frames.isNotEmpty) {
      variantCellFrames[mapping.variant] = [
        for (final frame in mapping.frames)
          PathStudioNewPathDraftCenterFrame(
            tile: PathStudioNewPathDraftTile(
              tilesetId: frame.tilesetId.trim().isEmpty
                  ? basePathPreset.tilesetId
                  : frame.tilesetId,
              sourceX: frame.source.x,
              sourceY: frame.source.y,
            ),
            durationMs: frame.durationMs ?? defaultPlacedElementAnimationFrameDurationMs,
          ),
      ];
      continue;
    }
    preservedVariantMappings.add(mapping);
  }

  return PathStudioNewPathDraft(
    basePathPresetId: basePathPreset.id,
    pathPatternPresetId: pathPatternPreset.id,
    name: pathPatternPreset.name,
    tilesetId: basePathPreset.tilesetId,
    centerWidth: pathPatternPreset.centerPattern.size.width,
    centerHeight: pathPatternPreset.centerPattern.size.height,
    selectedCellX: 0,
    selectedCellY: 0,
    selectedVariant: _requiredVariants.first,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.centerCell,
    surfaceKind: basePathPreset.surfaceKind,
    mode: PathStudioPathDraftMode.edit,
    source: PathStudioPathDraftSource(
      originalBasePathPresetId: basePathPreset.id,
      originalPathPatternPresetId: pathPatternPreset.id,
    ),
    isDirty: false,
    preservedVariantMappings: List<PathPresetVariantMapping>.unmodifiable(
      preservedVariantMappings,
    ),
    centerCellFrames: centerCellFrames,
    variantCellFrames: variantCellFrames,
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
    variantCellFrames: const {},
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
  final currentFrames = List<PathStudioNewPathDraftCenterFrame>.from(
      nextCellFrames[cellKey] ?? const []);
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
  if (draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell) {
    _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
    final cellKey = _cellKey(localX, localY);
    final nextCellFrames =
        Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
      draft.centerCellFrames,
    );
    final currentFrames = List<PathStudioNewPathDraftCenterFrame>.from(
        nextCellFrames[cellKey] ?? const []);
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
  } else {
    final variant = draft.selectedVariant;
    final nextVariantCellFrames = Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>.from(
      draft.variantCellFrames,
    );
    final currentFrames = List<PathStudioNewPathDraftCenterFrame>.from(
        nextVariantCellFrames[variant] ?? const []);
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
    nextVariantCellFrames[variant] = currentFrames;
    return draft.copyWith(
      variantCellFrames: nextVariantCellFrames,
      selectedCenterFrameIndex: currentFrames.length - 1,
      isDirty: true,
    );
  }
}

PathStudioNewPathDraft removePathStudioNewPathDraftCenterFrame({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
  required int frameIndex,
}) {
  if (draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell) {
    _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
    final cellKey = _cellKey(localX, localY);
    final nextCellFrames =
        Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
      draft.centerCellFrames,
    );
    final currentFrames = List<PathStudioNewPathDraftCenterFrame>.from(
        nextCellFrames[cellKey] ?? const []);
    if (frameIndex < 0 || frameIndex >= currentFrames.length) {
      throw RangeError.range(
          frameIndex, 0, currentFrames.length - 1, 'frameIndex');
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
  } else {
    final variant = draft.selectedVariant;
    final nextVariantCellFrames = Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>.from(
      draft.variantCellFrames,
    );
    final currentFrames = List<PathStudioNewPathDraftCenterFrame>.from(
        nextVariantCellFrames[variant] ?? const []);
    if (frameIndex < 0 || frameIndex >= currentFrames.length) {
      throw RangeError.range(
          frameIndex, 0, currentFrames.length - 1, 'frameIndex');
    }
    currentFrames.removeAt(frameIndex);
    if (currentFrames.isEmpty) {
      nextVariantCellFrames.remove(variant);
    } else {
      nextVariantCellFrames[variant] = currentFrames;
    }
    final nextSelectedIndex = currentFrames.isEmpty
        ? 0
        : draft.selectedCenterFrameIndex.clamp(0, currentFrames.length - 1);
    return draft.copyWith(
      variantCellFrames: nextVariantCellFrames,
      selectedCenterFrameIndex: nextSelectedIndex,
      isDirty: true,
    );
  }
}

PathStudioNewPathDraft selectPathStudioNewPathDraftCenterFrame({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
  required int frameIndex,
}) {
  if (draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell) {
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
  } else {
    final frames = draft.variantCellFrames[draft.selectedVariant] ?? const [];
    if (frameIndex < 0 || frameIndex >= frames.length) {
      throw RangeError.range(frameIndex, 0, frames.length - 1, 'frameIndex');
    }
    return draft.copyWith(
      selectedTarget: PathStudioNewPathDraftSelectionTarget.variant,
      selectedCenterFrameIndex: frameIndex,
    );
  }
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
  if (draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell) {
    _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
    final cellKey = _cellKey(localX, localY);
    final nextCellFrames =
        Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
      draft.centerCellFrames,
    );
    final currentFrames = List<PathStudioNewPathDraftCenterFrame>.from(
        nextCellFrames[cellKey] ?? const []);
    if (frameIndex < 0 || frameIndex >= currentFrames.length) {
      throw RangeError.range(
          frameIndex, 0, currentFrames.length - 1, 'frameIndex');
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
  } else {
    final variant = draft.selectedVariant;
    final nextVariantCellFrames = Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>.from(
      draft.variantCellFrames,
    );
    final currentFrames = List<PathStudioNewPathDraftCenterFrame>.from(
        nextVariantCellFrames[variant] ?? const []);
    if (frameIndex < 0 || frameIndex >= currentFrames.length) {
      throw RangeError.range(
          frameIndex, 0, currentFrames.length - 1, 'frameIndex');
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
    nextVariantCellFrames[variant] = currentFrames;
    return draft.copyWith(variantCellFrames: nextVariantCellFrames, isDirty: true);
  }
}

PathStudioNewPathDraft clearPathStudioNewPathDraftCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  if (draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell) {
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
  } else {
    final nextVariantCellFrames = Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>.from(
      draft.variantCellFrames,
    )..remove(draft.selectedVariant);
    return draft.copyWith(
      variantCellFrames: nextVariantCellFrames,
      selectedCenterFrameIndex: 0,
      isDirty: true,
    );
  }
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
    selectedCenterFrameIndex: 0,
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
  final nextVariantCellFrames = Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.variantCellFrames,
  );
  final currentFrames = List<PathStudioNewPathDraftCenterFrame>.from(
      nextVariantCellFrames[variant] ?? const []);
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
  nextVariantCellFrames[variant] = currentFrames;
  return draft.copyWith(
    variantCellFrames: nextVariantCellFrames,
    selectedVariant: variant,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.variant,
    selectedCenterFrameIndex: selectedIndex,
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
  final nextVariantCellFrames = Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.variantCellFrames,
  )..remove(variant);
  return draft.copyWith(
    variantCellFrames: nextVariantCellFrames,
    selectedVariant: variant,
    selectedTarget: PathStudioNewPathDraftSelectionTarget.variant,
    selectedCenterFrameIndex: 0,
    isDirty: true,
  );
}

/// Cible de l’assistant de séquence d’animation (lot PathPattern-39 V0).
enum PathStudioCenterAnimationSequenceTarget {
  selectedCell,
  allCenterCells,
  allCells,
}

sealed class PathStudioCenterAnimationSequenceResult {
  const PathStudioCenterAnimationSequenceResult();
}

final class PathStudioCenterAnimationSequenceSuccess
    extends PathStudioCenterAnimationSequenceResult {
  const PathStudioCenterAnimationSequenceSuccess({
    required this.draft,
    required this.message,
  });

  final PathStudioNewPathDraft draft;
  final String message;
}

final class PathStudioCenterAnimationSequenceFailure
    extends PathStudioCenterAnimationSequenceResult {
  const PathStudioCenterAnimationSequenceFailure(this.message);

  final String message;
}

/// Construit un brouillon où les cellules ciblées ont leurs frames remplacées
/// par une séquence géométrique à partir de la **première** frame existante.
///
/// Ne modifie pas [draft] : retour succès avec une nouvelle instance, ou échec
/// avec un message utilisateur localisé FR.
PathStudioCenterAnimationSequenceResult generatePathStudioCenterAnimationSequence({
  required PathStudioNewPathDraft draft,
  required PathStudioCenterAnimationSequenceTarget target,
  required int frameCount,
  required int stepX,
  required int stepY,
  required int durationMs,
}) {
  if (frameCount < 2 || frameCount > 64) {
    return const PathStudioCenterAnimationSequenceFailure(
      'Impossible de générer l’animation : le nombre de frames doit être '
      'compris entre 2 et 64.',
    );
  }
  if (durationMs <= 0) {
    return const PathStudioCenterAnimationSequenceFailure(
      'Impossible de générer l’animation : la durée par frame doit être positive.',
    );
  }
  if (stepX == 0 && stepY == 0) {
    return const PathStudioCenterAnimationSequenceFailure(
      'Impossible de générer l’animation : pas X et pas Y ne peuvent pas tous '
      'les deux être 0.',
    );
  }

  final targetCenterCells = <String>[];
  final targetVariants = <TerrainPathVariant>[];

  if (target == PathStudioCenterAnimationSequenceTarget.selectedCell) {
    if (draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell) {
      targetCenterCells.add(_cellKey(draft.selectedCellX, draft.selectedCellY));
    } else {
      targetVariants.add(draft.selectedVariant);
    }
  } else if (target == PathStudioCenterAnimationSequenceTarget.allCenterCells) {
    for (var y = 0; y < draft.centerHeight; y += 1) {
      for (var x = 0; x < draft.centerWidth; x += 1) {
        targetCenterCells.add(_cellKey(x, y));
      }
    }
  } else if (target == PathStudioCenterAnimationSequenceTarget.allCells) {
    for (var y = 0; y < draft.centerHeight; y += 1) {
      for (var x = 0; x < draft.centerWidth; x += 1) {
        targetCenterCells.add(_cellKey(x, y));
      }
    }
    for (final variant in PathStudioNewPathDraft.requiredVariants) {
      if (draft.variantCellFrames[variant]?.isNotEmpty ?? false) {
        targetVariants.add(variant);
      }
    }
  }

  for (final key in targetCenterCells) {
    final existing = draft.centerCellFrames[key];
    if (existing == null || existing.isEmpty) {
      return PathStudioCenterAnimationSequenceFailure(
        target == PathStudioCenterAnimationSequenceTarget.selectedCell
            ? 'Impossible de générer l’animation : la cellule active n’a pas de frame de départ.'
            : 'Impossible de générer l’animation : une cellule du centre n’a pas de frame de départ.',
      );
    }
    final start = existing.first.tile;
    for (var i = 0; i < frameCount; i += 1) {
      final gx = start.sourceX + stepX * i;
      final gy = start.sourceY + stepY * i;
      if (gx < 0 || gy < 0) {
        return const PathStudioCenterAnimationSequenceFailure(
          'Impossible de générer l’animation : une coordonnée générée serait négative.',
        );
      }
    }
  }

  for (final variant in targetVariants) {
    final existing = draft.variantCellFrames[variant];
    if (existing == null || existing.isEmpty) {
      return PathStudioCenterAnimationSequenceFailure(
        target == PathStudioCenterAnimationSequenceTarget.selectedCell
            ? 'Impossible de générer l’animation : la cellule active n’a pas de frame de départ.'
            : 'Impossible de générer l’animation : le variant ${variant.name} n’a pas de frame de départ.',
      );
    }
    final start = existing.first.tile;
    for (var i = 0; i < frameCount; i += 1) {
      final gx = start.sourceX + stepX * i;
      final gy = start.sourceY + stepY * i;
      if (gx < 0 || gy < 0) {
        return const PathStudioCenterAnimationSequenceFailure(
          'Impossible de générer l’animation : une coordonnée générée serait négative.',
        );
      }
    }
  }

  final nextCenterMap = Map<String, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.centerCellFrames,
  );
  for (final key in targetCenterCells) {
    final start = draft.centerCellFrames[key]!.first.tile;
    nextCenterMap[key] = [
      for (var i = 0; i < frameCount; i += 1)
        PathStudioNewPathDraftCenterFrame(
          tile: PathStudioNewPathDraftTile(
            tilesetId: start.tilesetId,
            sourceX: start.sourceX + stepX * i,
            sourceY: start.sourceY + stepY * i,
          ),
          durationMs: durationMs,
        ),
    ];
  }

  final nextVariantMap = Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>>.from(
    draft.variantCellFrames,
  );
  for (final variant in targetVariants) {
    final start = draft.variantCellFrames[variant]!.first.tile;
    nextVariantMap[variant] = [
      for (var i = 0; i < frameCount; i += 1)
        PathStudioNewPathDraftCenterFrame(
          tile: PathStudioNewPathDraftTile(
            tilesetId: start.tilesetId,
            sourceX: start.sourceX + stepX * i,
            sourceY: start.sourceY + stepY * i,
          ),
          durationMs: durationMs,
        ),
    ];
  }

  final String feedback;
  if (target == PathStudioCenterAnimationSequenceTarget.selectedCell) {
    if (draft.selectedTarget == PathStudioNewPathDraftSelectionTarget.centerCell) {
      feedback = 'Animation générée pour la cellule ${draft.selectedCell.label}.';
    } else {
      feedback = 'Animation générée pour le variant ${draft.selectedVariant.name}.';
    }
  } else if (target == PathStudioCenterAnimationSequenceTarget.allCenterCells) {
    feedback = 'Animation générée pour les ${draft.centerCellCount} cellules du centre.';
  } else {
    final totalCount = targetCenterCells.length + targetVariants.length;
    feedback = 'Animation générée pour les $totalCount cellules (centre + variants).';
  }

  return PathStudioCenterAnimationSequenceSuccess(
    draft: draft.copyWith(
      centerCellFrames: nextCenterMap,
      variantCellFrames: nextVariantMap,
      selectedCenterFrameIndex: 0,
      isDirty: true,
    ),
    message: feedback,
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

Map<String, List<PathStudioNewPathDraftCenterFrame>>
    _trimCenterCellFramesForSize(
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
    if (otherFrames == null ||
        !_centerFrameListsEqual(entry.value, otherFrames)) {
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

bool _variantCellFramesMapsEqual(
  Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>> left,
  Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    final otherFrames = right[entry.key];
    if (otherFrames == null ||
        !_centerFrameListsEqual(entry.value, otherFrames)) {
      return false;
    }
  }
  return true;
}

bool _pathPresetVariantMappingsEqual(
  List<PathPresetVariantMapping> left,
  List<PathPresetVariantMapping> right,
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

int _variantCellFramesMapHash(
  Map<TerrainPathVariant, List<PathStudioNewPathDraftCenterFrame>> map,
) {
  final entries = map.entries.toList()
    ..sort((left, right) => left.key.index.compareTo(right.key.index));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, Object.hashAll(entry.value))),
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

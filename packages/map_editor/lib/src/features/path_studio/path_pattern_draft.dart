import 'package:map_core/map_core.dart';

/// Issues locales propres au brouillon Path Studio.
///
/// Elles ne sont pas des erreurs de manifest : le brouillon n'est pas encore
/// persistant. Le but est seulement de guider l'utilisateur pendant l'édition
/// locale V0.
enum PathPatternDraftIssueCode {
  nameRequired,
}

/// Brouillon local et non sauvegardé d'un `ProjectPathPatternPreset`.
///
/// Ce modèle vit côté `map_editor` parce qu'il décrit un état d'édition UI,
/// pas un contrat projet. Il ne mute jamais le `ProjectManifest`.
final class PathPatternDraft {
  PathPatternDraft({
    required this.id,
    required this.name,
    required this.basePathPresetId,
    required this.centerPattern,
    this.transparentColor,
    this.categoryId,
    required this.sortOrder,
    required this.selectedCellX,
    required this.selectedCellY,
    required this.isDirty,
  });

  final String id;
  final String name;
  final String basePathPresetId;
  final PathCenterPattern centerPattern;
  final TilesetTransparentColor? transparentColor;
  final String? categoryId;
  final int sortOrder;
  final int selectedCellX;
  final int selectedCellY;
  final bool isDirty;

  String get centerPatternLabel =>
      '${centerPattern.size.width}×${centerPattern.size.height}';

  int get centerCellCount => centerPattern.cells.length;

  int get centerFrameCount => centerPattern.cells.fold(
        0,
        (total, cell) => total + cell.frames.length,
      );

  int get animatedCellCount =>
      centerPattern.cells.where((cell) => cell.frames.length > 1).length;

  PathCenterPatternCell get selectedCell =>
      centerPattern.cellAt(selectedCellX, selectedCellY);

  List<PathPatternDraftIssueCode> get issues {
    final result = <PathPatternDraftIssueCode>[];
    if (name.trim().isEmpty) {
      result.add(PathPatternDraftIssueCode.nameRequired);
    }
    return List<PathPatternDraftIssueCode>.unmodifiable(result);
  }

  PathPatternDraft copyWith({
    String? id,
    String? name,
    String? basePathPresetId,
    PathCenterPattern? centerPattern,
    TilesetTransparentColor? transparentColor,
    String? categoryId,
    int? sortOrder,
    int? selectedCellX,
    int? selectedCellY,
    bool? isDirty,
  }) {
    return PathPatternDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      basePathPresetId: basePathPresetId ?? this.basePathPresetId,
      centerPattern: centerPattern ?? this.centerPattern,
      transparentColor: transparentColor ?? this.transparentColor,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      selectedCellX: selectedCellX ?? this.selectedCellX,
      selectedCellY: selectedCellY ?? this.selectedCellY,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternDraft &&
            id == other.id &&
            name == other.name &&
            basePathPresetId == other.basePathPresetId &&
            centerPattern == other.centerPattern &&
            transparentColor == other.transparentColor &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder &&
            selectedCellX == other.selectedCellX &&
            selectedCellY == other.selectedCellY &&
            isDirty == other.isDirty;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        basePathPresetId,
        centerPattern,
        transparentColor,
        categoryId,
        sortOrder,
        selectedCellX,
        selectedCellY,
        isDirty,
      );
}

PathPatternDraft? createInitialPathPatternDraftFromManifest({
  required ProjectManifest manifest,
}) {
  if (manifest.pathPresets.isEmpty) {
    return null;
  }
  return createInitialPathPatternDraft(
    basePathPreset: manifest.pathPresets.first,
    sortOrder: manifest.pathPatternPresets.length,
  );
}

PathPatternDraft createInitialPathPatternDraft({
  required ProjectPathPreset basePathPreset,
  int sortOrder = 0,
}) {
  return PathPatternDraft(
    id: 'draft-path-pattern',
    name: 'Nouveau motif de chemin',
    basePathPresetId: basePathPreset.id,
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: PathCenterPatternSize(width: 1, height: 1),
    ),
    categoryId: null,
    sortOrder: sortOrder,
    selectedCellX: 0,
    selectedCellY: 0,
    isDirty: true,
  );
}

PathCenterPattern rebuildDraftCenterPattern({
  required ProjectPathPreset basePathPreset,
  required PathCenterPatternSize size,
}) {
  final centerView = createLegacyProjectPathPresetCenterPatternView(
    preset: basePathPreset,
    centerVariant: TerrainPathVariant.cross,
  );
  final frames = centerView.centerPattern.cellAt(0, 0).frames;
  final cells = <PathCenterPatternCell>[];
  for (var y = 0; y < size.height; y += 1) {
    for (var x = 0; x < size.width; x += 1) {
      cells.add(
        PathCenterPatternCell(
          localX: x,
          localY: y,
          frames: frames,
        ),
      );
    }
  }
  return PathCenterPattern(size: size, cells: cells);
}

PathPatternDraft resizePathPatternDraftCenter({
  required PathPatternDraft draft,
  required ProjectPathPreset basePathPreset,
  required int width,
  required int height,
}) {
  final size = PathCenterPatternSize(width: width, height: height);
  return draft.copyWith(
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: size,
    ),
    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
    isDirty: true,
  );
}

PathPatternDraft changePathPatternDraftBase({
  required PathPatternDraft draft,
  required ProjectPathPreset basePathPreset,
}) {
  return draft.copyWith(
    basePathPresetId: basePathPreset.id,
    centerPattern: rebuildDraftCenterPattern(
      basePathPreset: basePathPreset,
      size: draft.centerPattern.size,
    ),
    isDirty: true,
  );
}

PathPatternDraft renamePathPatternDraft(
  PathPatternDraft draft,
  String name,
) {
  return draft.copyWith(name: name, isDirty: true);
}

PathPatternDraft selectPathPatternDraftCell({
  required PathPatternDraft draft,
  required int localX,
  required int localY,
}) {
  // `cellAt` intentionally performs the bounds validation for this local
  // editor state. A failing caller should surface during tests rather than
  // silently selecting a different cell.
  draft.centerPattern.cellAt(localX, localY);
  return draft.copyWith(
    selectedCellX: localX,
    selectedCellY: localY,
  );
}

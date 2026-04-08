import 'dart:ui' show Offset;

import 'package:map_core/map_core.dart';

import 'element_collision_base_cells_from_padding_service.dart';
import 'element_collision_cells_overlay_service.dart';
import 'element_collision_shape_rasterizer_service.dart';

/// Editor-facing facade for element collision authoring.
///
/// Responsibilities:
/// - derive the automatic base from padding for simple/generated cases
/// - treat the author shape as the true base for complex/manual cases
/// - preserve explicit local add/remove retouches
/// - rebuild the final runtime truth (`profile.cells`)
///
/// Runtime/gameplay must never need to understand base cells or overrides.
class ElementCollisionAuthoringService {
  const ElementCollisionAuthoringService({
    this.baseCellsFromPaddingService =
        const ElementCollisionBaseCellsFromPaddingService(),
    this.cellsOverlayService = const ElementCollisionCellsOverlayService(),
    this.shapeRasterizerService =
        const ElementCollisionShapeRasterizerService(),
  });

  final ElementCollisionBaseCellsFromPaddingService baseCellsFromPaddingService;
  final ElementCollisionCellsOverlayService cellsOverlayService;
  final ElementCollisionShapeRasterizerService shapeRasterizerService;

  ElementCollisionAuthoringSnapshot describe({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    ElementCollisionProfile? profile,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final padding = profile?.padding ?? fallbackPadding;
    final paddingBaseCells = baseCellsFromPaddingService.derive(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: padding,
    );
    final sourceMode =
        profile?.source ?? ElementCollisionProfileSource.generated;
    final authoredShapeCells = _normalizeWithinSource(
      profile?.shapeCells ?? const <GridPos>[],
      source: source,
    );
    final manualAddedCells = _normalizeWithinSource(
      profile?.manualAddedCells ?? const <GridPos>[],
      source: source,
    );
    final manualRemovedCells = _normalizeWithinSource(
      profile?.manualRemovedCells ?? const <GridPos>[],
      source: source,
    );
    final resolved = _resolveBaseCells(
      sourceMode: sourceMode,
      paddingBaseCells: paddingBaseCells,
      authoredShapeCells: authoredShapeCells,
      currentFinalCells: _normalizeWithinSource(
        profile?.cells ?? const <GridPos>[],
        source: source,
      ),
      manualAddedCells: manualAddedCells,
      manualRemovedCells: manualRemovedCells,
    );
    final finalCells = cellsOverlayService.apply(
      baseCells: resolved.baseCells,
      manualAddedCells: resolved.manualAddedCells,
      manualRemovedCells: resolved.manualRemovedCells,
    );
    return ElementCollisionAuthoringSnapshot(
      source: resolved.source,
      padding: padding,
      shapeCells: resolved.shapeCells,
      baseCells: resolved.baseCells,
      manualAddedCells: resolved.manualAddedCells,
      manualRemovedCells: resolved.manualRemovedCells,
      finalCells: finalCells,
    );
  }

  ElementCollisionProfile rebuild({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    ElementCollisionProfileSource sourceMode =
        ElementCollisionProfileSource.generated,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
    List<GridPos> shapeCells = const <GridPos>[],
    List<GridPos> manualAddedCells = const <GridPos>[],
    List<GridPos> manualRemovedCells = const <GridPos>[],
  }) {
    final normalizedShapeCells = _normalizeWithinSource(
      shapeCells,
      source: source,
    );
    final manualAdded = _normalizeWithinSource(
      manualAddedCells,
      source: source,
    );
    final manualRemoved = _normalizeWithinSource(
      manualRemovedCells,
      source: source,
    );
    final baseCells = sourceMode == ElementCollisionProfileSource.manual
        ? normalizedShapeCells
        : baseCellsFromPaddingService.derive(
            source: source,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            padding: padding,
          );
    final finalCells = cellsOverlayService.apply(
      baseCells: baseCells,
      manualAddedCells: manualAdded,
      manualRemovedCells: manualRemoved,
    );
    return ElementCollisionProfile(
      source: sourceMode,
      padding: padding,
      shapeCells: normalizedShapeCells,
      cells: finalCells,
      manualAddedCells: manualAdded,
      manualRemovedCells: manualRemoved,
    );
  }

  ElementCollisionProfile recalculateFromPadding({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required WarpTriggerPadding padding,
    ElementCollisionProfile? current,
    bool preserveOverrides = true,
  }) {
    final snapshot = describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: current,
      fallbackPadding: padding,
    );
    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceMode: snapshot.source,
      padding: padding,
      shapeCells: snapshot.shapeCells,
      manualAddedCells:
          preserveOverrides ? snapshot.manualAddedCells : const [],
      manualRemovedCells:
          preserveOverrides ? snapshot.manualRemovedCells : const [],
    );
  }

  /// Explicitly switches the profile back to a generated/padding-driven base.
  ///
  /// This is intentionally separate from [recalculateFromPadding]. Recomputing
  /// the stored padding should not silently steal control back from a manual
  /// author shape. The editor can call this only when the user explicitly says
  /// "use padding as the main base again".
  ElementCollisionProfile usePaddingAsPrimaryBase({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required WarpTriggerPadding padding,
  }) {
    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceMode: ElementCollisionProfileSource.generated,
      padding: padding,
      shapeCells: const [],
      manualAddedCells: const [],
      manualRemovedCells: const [],
    );
  }

  ElementCollisionProfile applyAddModeTap({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required GridPos cell,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    return applyCells(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      cells: <GridPos>[cell],
      operation: ElementCollisionAuthoringOperation.add,
      current: current,
      fallbackPadding: fallbackPadding,
    );
  }

  ElementCollisionProfile applyRemoveModeTap({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required GridPos cell,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    return applyCells(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      cells: <GridPos>[cell],
      operation: ElementCollisionAuthoringOperation.remove,
      current: current,
      fallbackPadding: fallbackPadding,
    );
  }

  /// Applies an explicit list of authored cells in a stable/idempotent way.
  ///
  /// This is the main building block used by the dedicated collision editor:
  /// - brush drags resolve to a list of cells
  /// - polygons resolve to a list of cells
  /// - this method folds those cells into author overrides
  ///
  /// Importantly, repeated application of the same stroke must *not* toggle
  /// cells on and off. The editor is shape-oriented, so the operation means
  /// "make these cells present" or "make these cells absent".
  ElementCollisionProfile applyCells({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required Iterable<GridPos> cells,
    required ElementCollisionAuthoringOperation operation,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final snapshot = describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: current,
      fallbackPadding: fallbackPadding,
    );
    final nextAdded = <String, GridPos>{
      for (final value in snapshot.manualAddedCells) _key(value): value,
    };
    final nextRemoved = <String, GridPos>{
      for (final value in snapshot.manualRemovedCells) _key(value): value,
    };

    for (final cell in _normalizeWithinSource(cells.toList(growable: false),
        source: source)) {
      final key = _key(cell);
      switch (operation) {
        case ElementCollisionAuthoringOperation.add:
          nextAdded[key] = cell;
          nextRemoved.remove(key);
        case ElementCollisionAuthoringOperation.remove:
          nextRemoved[key] = cell;
          nextAdded.remove(key);
      }
    }

    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceMode: snapshot.source,
      padding: snapshot.padding,
      shapeCells: snapshot.shapeCells,
      manualAddedCells: nextAdded.values.toList(growable: false),
      manualRemovedCells: nextRemoved.values.toList(growable: false),
    );
  }

  /// Replaces the authoring base with a shape-authored polygon.
  ///
  /// This is the key fix for the reported bug: when the user draws the main
  /// collision silhouette of a building, that polygon must become the logical
  /// base shape. It must not be added on top of a full padding-derived
  /// rectangle.
  ElementCollisionProfile setPrimaryShape({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required Iterable<GridPos> cells,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final snapshot = describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: current,
      fallbackPadding: fallbackPadding,
    );
    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceMode: ElementCollisionProfileSource.manual,
      padding: snapshot.padding,
      shapeCells: cells.toList(growable: false),
      // The new polygon becomes the main authored base. We intentionally clear
      // older overrides so the saved runtime cells match the newly authored
      // silhouette instead of carrying stale add/remove noise from the former
      // base model.
      manualAddedCells: const [],
      manualRemovedCells: const [],
    );
  }

  ElementCollisionProfile applyBrushStroke({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required List<Offset> points,
    required ElementCollisionAuthoringOperation operation,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final cells = shapeRasterizerService.rasterizeBrushStroke(
      points: points,
      gridWidth: source.width,
      gridHeight: source.height,
    );
    return applyCells(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      cells: cells,
      operation: operation,
      current: current,
      fallbackPadding: fallbackPadding,
    );
  }

  ElementCollisionProfile applyPolygon({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required List<Offset> vertices,
    required ElementCollisionAuthoringOperation operation,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final cells = shapeRasterizerService.rasterizePolygon(
      vertices: vertices,
      gridWidth: source.width,
      gridHeight: source.height,
    );
    if (operation == ElementCollisionAuthoringOperation.add) {
      return setPrimaryShape(
        source: source,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        cells: cells,
        current: current,
        fallbackPadding: fallbackPadding,
      );
    }
    return applyCells(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      cells: cells,
      operation: operation,
      current: current,
      fallbackPadding: fallbackPadding,
    );
  }

  ElementCollisionProfile resetOverrides({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final snapshot = describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: current,
      fallbackPadding: fallbackPadding,
    );
    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceMode: snapshot.source,
      padding: snapshot.padding,
      shapeCells: snapshot.shapeCells,
    );
  }

  ElementCollisionProfile clearAllCollision({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final snapshot = describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: current,
      fallbackPadding: fallbackPadding,
    );
    if (snapshot.source == ElementCollisionProfileSource.manual) {
      return rebuild(
        source: source,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        sourceMode: ElementCollisionProfileSource.manual,
        padding: snapshot.padding,
        shapeCells: const [],
      );
    }
    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceMode: ElementCollisionProfileSource.generated,
      padding: snapshot.padding,
      manualRemovedCells: _allCellsForSource(source),
    );
  }

  List<GridPos> _allCellsForSource(TilesetSourceRect source) {
    final cells = <GridPos>[];
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        cells.add(GridPos(x: x, y: y));
      }
    }
    return cells;
  }

  List<GridPos> _normalizeWithinSource(
    List<GridPos> cells, {
    required TilesetSourceRect source,
  }) {
    final bounded = <GridPos>[];
    for (final cell in cells) {
      if (cell.x < 0 || cell.y < 0) {
        continue;
      }
      if (cell.x >= source.width || cell.y >= source.height) {
        continue;
      }
      bounded.add(GridPos(x: cell.x, y: cell.y));
    }
    return cellsOverlayService.normalize(bounded);
  }

  String _key(GridPos cell) => '${cell.x}:${cell.y}';

  _ResolvedCollisionBase _resolveBaseCells({
    required ElementCollisionProfileSource sourceMode,
    required List<GridPos> paddingBaseCells,
    required List<GridPos> authoredShapeCells,
    required List<GridPos> currentFinalCells,
    required List<GridPos> manualAddedCells,
    required List<GridPos> manualRemovedCells,
  }) {
    if (sourceMode == ElementCollisionProfileSource.manual) {
      if (authoredShapeCells.isNotEmpty) {
        return _ResolvedCollisionBase(
          source: ElementCollisionProfileSource.manual,
          shapeCells: authoredShapeCells,
          baseCells: authoredShapeCells,
          manualAddedCells: manualAddedCells,
          manualRemovedCells: manualRemovedCells,
        );
      }

      // Legacy migration: the broken implementation stored a full padding base
      // in `cells`, then put the polygon cells into `manualAddedCells`. When
      // we detect exactly that pattern, we reinterpret the polygon as the real
      // authored base.
      if (manualAddedCells.isNotEmpty &&
          manualRemovedCells.isEmpty &&
          _sameCells(currentFinalCells, paddingBaseCells)) {
        return _ResolvedCollisionBase(
          source: ElementCollisionProfileSource.manual,
          shapeCells: manualAddedCells,
          baseCells: manualAddedCells,
          manualAddedCells: const [],
          manualRemovedCells: const [],
        );
      }

      // Legacy migration: some manual profiles may have been saved directly as
      // final cells without explicit `shapeCells`. If there are no overrides
      // and the final cells differ from the padding base, the safest
      // interpretation is that the final cells themselves are the intended
      // authored shape.
      if (manualAddedCells.isEmpty &&
          manualRemovedCells.isEmpty &&
          currentFinalCells.isNotEmpty &&
          !_sameCells(currentFinalCells, paddingBaseCells)) {
        return _ResolvedCollisionBase(
          source: ElementCollisionProfileSource.manual,
          shapeCells: currentFinalCells,
          baseCells: currentFinalCells,
          manualAddedCells: const [],
          manualRemovedCells: const [],
        );
      }
    }

    return _ResolvedCollisionBase(
      source: ElementCollisionProfileSource.generated,
      shapeCells: const [],
      baseCells: paddingBaseCells,
      manualAddedCells: manualAddedCells,
      manualRemovedCells: manualRemovedCells,
    );
  }

  bool _sameCells(List<GridPos> a, List<GridPos> b) {
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
}

enum ElementCollisionAuthoringOperation {
  add,
  remove,
}

class ElementCollisionAuthoringSnapshot {
  const ElementCollisionAuthoringSnapshot({
    required this.source,
    required this.padding,
    required this.shapeCells,
    required this.baseCells,
    required this.manualAddedCells,
    required this.manualRemovedCells,
    required this.finalCells,
  });

  final ElementCollisionProfileSource source;
  final WarpTriggerPadding padding;
  final List<GridPos> shapeCells;
  final List<GridPos> baseCells;
  final List<GridPos> manualAddedCells;
  final List<GridPos> manualRemovedCells;
  final List<GridPos> finalCells;

  bool get usesManualPrimaryShape =>
      source == ElementCollisionProfileSource.manual;
}

class _ResolvedCollisionBase {
  const _ResolvedCollisionBase({
    required this.source,
    required this.shapeCells,
    required this.baseCells,
    required this.manualAddedCells,
    required this.manualRemovedCells,
  });

  final ElementCollisionProfileSource source;
  final List<GridPos> shapeCells;
  final List<GridPos> baseCells;
  final List<GridPos> manualAddedCells;
  final List<GridPos> manualRemovedCells;
}

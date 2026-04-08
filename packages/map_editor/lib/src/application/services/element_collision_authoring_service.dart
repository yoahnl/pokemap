import 'package:map_core/map_core.dart';

import 'element_collision_base_cells_from_padding_service.dart';
import 'element_collision_cells_overlay_service.dart';

/// Editor-facing facade for element collision authoring.
///
/// Responsibilities:
/// - derive the base shape from padding
/// - preserve explicit author intent (manual add/remove)
/// - rebuild the final runtime truth (`profile.cells`)
///
/// Runtime/gameplay must never need to understand base cells or overrides.
class ElementCollisionAuthoringService {
  const ElementCollisionAuthoringService({
    this.baseCellsFromPaddingService =
        const ElementCollisionBaseCellsFromPaddingService(),
    this.cellsOverlayService = const ElementCollisionCellsOverlayService(),
  });

  final ElementCollisionBaseCellsFromPaddingService baseCellsFromPaddingService;
  final ElementCollisionCellsOverlayService cellsOverlayService;

  ElementCollisionAuthoringSnapshot describe({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    ElementCollisionProfile? profile,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final padding = profile?.padding ?? fallbackPadding;
    final baseCells = baseCellsFromPaddingService.derive(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: padding,
    );
    final manualAddedCells = _normalizeWithinSource(
      profile?.manualAddedCells ?? const <GridPos>[],
      source: source,
    );
    final manualRemovedCells = _normalizeWithinSource(
      profile?.manualRemovedCells ?? const <GridPos>[],
      source: source,
    );
    final finalCells = cellsOverlayService.apply(
      baseCells: baseCells,
      manualAddedCells: manualAddedCells,
      manualRemovedCells: manualRemovedCells,
    );
    return ElementCollisionAuthoringSnapshot(
      padding: padding,
      baseCells: baseCells,
      manualAddedCells: manualAddedCells,
      manualRemovedCells: manualRemovedCells,
      finalCells: finalCells,
    );
  }

  ElementCollisionProfile rebuild({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
    List<GridPos> manualAddedCells = const <GridPos>[],
    List<GridPos> manualRemovedCells = const <GridPos>[],
  }) {
    final manualAdded = _normalizeWithinSource(
      manualAddedCells,
      source: source,
    );
    final manualRemoved = _normalizeWithinSource(
      manualRemovedCells,
      source: source,
    );
    final baseCells = baseCellsFromPaddingService.derive(
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
    final hasManualOverrides =
        manualAdded.isNotEmpty || manualRemoved.isNotEmpty;
    return ElementCollisionProfile(
      source: hasManualOverrides
          ? ElementCollisionProfileSource.manual
          : ElementCollisionProfileSource.generated,
      padding: padding,
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
    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: padding,
      manualAddedCells:
          preserveOverrides ? current?.manualAddedCells ?? const [] : const [],
      manualRemovedCells: preserveOverrides
          ? current?.manualRemovedCells ?? const []
          : const [],
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
    final snapshot = describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: current,
      fallbackPadding: fallbackPadding,
    );
    final addKey = _key(cell);
    final nextAdded = <String, GridPos>{
      for (final value in snapshot.manualAddedCells) _key(value): value,
    };
    final nextRemoved = <String, GridPos>{
      for (final value in snapshot.manualRemovedCells) _key(value): value,
    };

    if (nextAdded.containsKey(addKey)) {
      nextAdded.remove(addKey);
    } else {
      nextAdded[addKey] = GridPos(x: cell.x, y: cell.y);
      nextRemoved.remove(addKey);
    }

    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: snapshot.padding,
      manualAddedCells: nextAdded.values.toList(growable: false),
      manualRemovedCells: nextRemoved.values.toList(growable: false),
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
    final snapshot = describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: current,
      fallbackPadding: fallbackPadding,
    );
    final removeKey = _key(cell);
    final nextAdded = <String, GridPos>{
      for (final value in snapshot.manualAddedCells) _key(value): value,
    };
    final nextRemoved = <String, GridPos>{
      for (final value in snapshot.manualRemovedCells) _key(value): value,
    };

    if (nextRemoved.containsKey(removeKey)) {
      nextRemoved.remove(removeKey);
    } else {
      nextRemoved[removeKey] = GridPos(x: cell.x, y: cell.y);
      nextAdded.remove(removeKey);
    }

    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: snapshot.padding,
      manualAddedCells: nextAdded.values.toList(growable: false),
      manualRemovedCells: nextRemoved.values.toList(growable: false),
    );
  }

  ElementCollisionProfile resetOverrides({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final padding = current?.padding ?? fallbackPadding;
    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: padding,
    );
  }

  ElementCollisionProfile clearAllCollision({
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    ElementCollisionProfile? current,
    WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
  }) {
    final padding = current?.padding ?? fallbackPadding;
    return rebuild(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: padding,
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
}

class ElementCollisionAuthoringSnapshot {
  const ElementCollisionAuthoringSnapshot({
    required this.padding,
    required this.baseCells,
    required this.manualAddedCells,
    required this.manualRemovedCells,
    required this.finalCells,
  });

  final WarpTriggerPadding padding;
  final List<GridPos> baseCells;
  final List<GridPos> manualAddedCells;
  final List<GridPos> manualRemovedCells;
  final List<GridPos> finalCells;
}

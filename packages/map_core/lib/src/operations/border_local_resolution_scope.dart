import '../exceptions/map_exceptions.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';

/// Canonical pre/post-override evidence required by later local edits.
final class BorderLocalResolutionState {
  BorderLocalResolutionState._({
    required this.request,
    required this.result,
    required List<BorderResolvedGroundCell> baseGround,
    required List<BorderResolvedPlacement> basePlacements,
  })  : _baseGround = List<BorderResolvedGroundCell>.unmodifiable(baseGround),
        _basePlacements =
            List<BorderResolvedPlacement>.unmodifiable(basePlacements) {
    if (result.materialization == null) {
      throw const ValidationException(
        'Border local baseline requires an applicable canonical result',
      );
    }
  }

  final BorderResolutionRequest request;
  final BorderResolutionResult result;
  final List<BorderResolvedGroundCell> _baseGround;
  final List<BorderResolvedPlacement> _basePlacements;

  BorderMaterialization get materialization => result.materialization!;

  List<BorderResolvedGroundCell> get baseGround => _baseGround;

  List<BorderResolvedPlacement> get basePlacements => _basePlacements;

  Map<String, BorderResolvedPlacement> get resolvedPlacementsBySlot =>
      <String, BorderResolvedPlacement>{
        for (final placement in materialization.placements)
          placement.slotKey: placement,
      };

  Set<String> get suppressedPlacementSlotKeys {
    final visible = <String>{
      for (final placement in materialization.placements) placement.slotKey,
    };
    return <String>{
      for (final placement in _basePlacements)
        if (!visible.contains(placement.slotKey)) placement.slotKey,
    };
  }
}

/// Mutable sink used only while producing one full local-edit baseline.
final class BorderLocalResolutionCapture {
  List<BorderResolvedGroundCell>? _baseGround;
  List<BorderResolvedPlacement>? _basePlacements;

  void recordBase({
    required Iterable<BorderResolvedGroundCell> ground,
    required Iterable<BorderResolvedPlacement> placements,
  }) {
    if (_baseGround != null || _basePlacements != null) {
      throw StateError('Border local base trace was already recorded');
    }
    _baseGround = ground.toList(growable: false);
    _basePlacements = placements.toList(growable: false);
  }

  BorderLocalResolutionState finish({
    required BorderResolutionRequest request,
    required BorderResolutionResult result,
  }) {
    final ground = _baseGround;
    final placements = _basePlacements;
    if (ground == null || placements == null) {
      throw const ValidationException(
        'Border local baseline could not capture pre-override output',
      );
    }
    return BorderLocalResolutionState._(
      request: request,
      result: result,
      baseGround: ground,
      basePlacements: placements,
    );
  }
}

/// Internal regeneration boundary shared by the three V1 template solvers.
///
/// The scope never resolves a Border itself. It only partitions persisted
/// output and records the source cells whose generation branch was entered.
final class BorderLocalResolutionScope {
  BorderLocalResolutionScope({
    required this.previousState,
    required Iterable<BorderPixelRect> affectedBoundsPx,
  }) : _affectedBoundsPx = List<BorderPixelRect>.unmodifiable(
          affectedBoundsPx,
        ) {
    final resolvedBySlot = previousState.resolvedPlacementsBySlot;
    for (final base in previousState.basePlacements) {
      final resolved = resolvedBySlot[base.slotKey];
      if (intersectsBounds(base.opaqueWorldBoundsPx) ||
          (resolved != null &&
              intersectsBounds(resolved.opaqueWorldBoundsPx))) {
        _forcedSourceCells.add(base.anchorCell);
      }
    }
  }

  final BorderLocalResolutionState previousState;
  final List<BorderPixelRect> _affectedBoundsPx;
  final Set<GridPos> _recomputedSourceCells = <GridPos>{};
  final Set<GridPos> _forcedSourceCells = <GridPos>{};

  List<BorderPixelRect> get affectedBoundsPx => _affectedBoundsPx;

  BorderMaterialization get previousMaterialization =>
      previousState.materialization;

  List<BorderResolvedGroundCell> get previousBaseGround =>
      previousState.baseGround;

  List<BorderResolvedPlacement> get previousBasePlacements =>
      previousState.basePlacements;

  Map<String, BorderResolvedPlacement> get previousResolvedPlacementsBySlot =>
      previousState.resolvedPlacementsBySlot;

  Set<String> get previousSuppressedPlacementSlotKeys =>
      previousState.suppressedPlacementSlotKeys;

  List<GridPos> get recomputedSourceCells {
    final values = _recomputedSourceCells.toList(growable: false)
      ..sort((first, second) {
        final row = first.y.compareTo(second.y);
        return row != 0 ? row : first.x.compareTo(second.x);
      });
    return List<GridPos>.unmodifiable(values);
  }

  bool intersectsBounds(BorderPixelRect bounds) =>
      _affectedBoundsPx.any((dirty) => _rectanglesIntersect(dirty, bounds));

  bool recomputesCell(GridPos cell, GridSize tileSizePx) =>
      _forcedSourceCells.contains(cell) ||
      intersectsBounds(_cellBounds(cell, tileSizePx));

  bool retainsBasePlacement(
    BorderResolvedPlacement placement,
    GridSize tileSizePx,
  ) {
    final resolved = previousResolvedPlacementsBySlot[placement.slotKey];
    return !intersectsBounds(placement.opaqueWorldBoundsPx) &&
        (resolved == null || !intersectsBounds(resolved.opaqueWorldBoundsPx)) &&
        !recomputesCell(placement.anchorCell, tileSizePx);
  }

  bool retainsGround(
    BorderResolvedGroundCell cell,
    GridSize tileSizePx,
  ) =>
      !intersectsBounds(
        _cellBounds(GridPos(x: cell.x, y: cell.y), tileSizePx),
      );

  void recordRecomputedCell(GridPos cell) {
    _recomputedSourceCells.add(GridPos(x: cell.x, y: cell.y));
  }
}

BorderPixelRect _cellBounds(GridPos cell, GridSize tileSizePx) =>
    BorderPixelRect(
      x: (BigInt.from(cell.x) * BigInt.from(tileSizePx.width)).toInt(),
      y: (BigInt.from(cell.y) * BigInt.from(tileSizePx.height)).toInt(),
      width: tileSizePx.width,
      height: tileSizePx.height,
    );

bool _rectanglesIntersect(BorderPixelRect first, BorderPixelRect second) =>
    first.x < second.right &&
    first.right > second.x &&
    first.y < second.bottom &&
    first.bottom > second.y;

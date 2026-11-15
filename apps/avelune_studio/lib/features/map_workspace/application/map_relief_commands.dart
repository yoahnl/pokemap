import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';
import 'map_relief_stroke.dart';
import 'map_relief_tool.dart';

export 'map_relief_stroke.dart';
export 'map_relief_tool.dart';

final class MapReliefCommands {
  const MapReliefCommands(this.document, this.project);

  final EditableMapDocument document;
  final ProjectManifest project;

  MapReliefOutcome apply(MapReliefStroke stroke, MapReliefToolState state) {
    final outcome = _apply(stroke, state);
    state.outcome = outcome;
    return outcome;
  }

  MapReliefOutcome _apply(MapReliefStroke stroke, MapReliefToolState state) {
    if (document.saving || !identical(stroke.source, document.current)) {
      return const MapReliefOutcome(problem: MapReliefProblem.busy);
    }
    final profile = mapReliefProfile(
      project,
      document.current,
      state.profileId,
    );
    if (profile == null) {
      return MapReliefOutcome(
        problem: state.profileId == null
            ? MapReliefProblem.noProfile
            : MapReliefProblem.profileUnavailable,
      );
    }
    final TerrainReliefPaint painted;
    try {
      painted = paintTerrainRelief(
        manifest: project,
        map: document.current,
        cells: stroke.cells,
        level: stroke.level,
        blueprintId: profile.id,
        twoLevelBlueprintId: profile.twoLevelId,
      );
    } on ValidationException catch (failure) {
      final problem = mapReliefProblem(failure);
      return MapReliefOutcome(
        problem:
            problem == MapReliefProblem.narrowCorner &&
                _wideRectangle(stroke.cells) &&
                _meetsOtherSteps(stroke)
            ? MapReliefProblem.cornerNearStep
            : problem,
        diagnostics: mapReliefDiagnostics(failure),
        profileName: profile.name,
      );
    }
    if (painted.map == document.current) return const MapReliefOutcome();
    document.commit(painted.map);
    return MapReliefOutcome(
      warnings: {
        if (painted.unreachable) MapReliefWarning.unreachable,
        if (_nearExteriorBorder(stroke.cells))
          MapReliefWarning.exteriorDecoration,
      },
    );
  }

  bool _wideRectangle(Set<GridPos> cells) {
    if (cells.isEmpty) return false;
    final xs = cells.map((cell) => cell.x), ys = cells.map((cell) => cell.y);
    final width = xs.reduce(math.max) - xs.reduce(math.min) + 1;
    final depth = ys.reduce(math.max) - ys.reduce(math.min) + 1;
    return width >= 3 && depth >= 3 && cells.length == width * depth;
  }

  bool _meetsOtherSteps(MapReliefStroke stroke) {
    final scene = document.current.spatialScene!;
    final steps = <int>{};
    for (final cell in stroke.contour) {
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final x = cell.x + dx, y = cell.y + dy;
        if (x < 0 ||
            y < 0 ||
            x >= scene.width ||
            y >= scene.depth ||
            stroke.cells.contains(GridPos(x: x, y: y))) {
          continue;
        }
        final level = (scene.worldHeightAt(x + .5, y + .5) / scene.levelHeight)
            .round();
        if (level != stroke.level) steps.add(level);
      }
    }
    return steps.length > 1;
  }

  bool _nearExteriorBorder(Set<GridPos> cells) {
    final borders = document.exteriorDecoration?.current?.borders;
    if (borders == null || borders.isEmpty || cells.isEmpty) return false;
    final left = cells.map((c) => c.x).reduce((a, b) => a < b ? a : b) - 1;
    final right = cells.map((c) => c.x).reduce((a, b) => a > b ? a : b) + 2;
    final top = cells.map((c) => c.y).reduce((a, b) => a < b ? a : b) - 1;
    final bottom = cells.map((c) => c.y).reduce((a, b) => a > b ? a : b) + 2;
    return borders.any(
      (border) =>
          border.originX < right &&
          border.originX + border.width > left &&
          border.originZ < bottom &&
          border.originZ + border.depth > top,
    );
  }
}

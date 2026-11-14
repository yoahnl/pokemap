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
      return MapReliefOutcome(problem: mapReliefProblem(failure));
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

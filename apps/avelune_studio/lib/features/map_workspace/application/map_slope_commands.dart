import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';
import 'map_slope_tool.dart';

export 'map_slope_tool.dart';

final class MapSlopeCommands {
  const MapSlopeCommands(this.document, this.project);

  final EditableMapDocument document;
  final ProjectManifest project;

  MapSlopeOutcome paintSlope(
    MapData source,
    GridPos from,
    GridPos to,
    MapSlopeToolState state,
  ) => state.outcome = _apply(
    source,
    () => paintTerrainSlope(
      manifest: project,
      map: document.current,
      from: from,
      to: to,
    ),
  );

  MapSlopeOutcome placeStair(GridPos cell, MapSlopeToolState state) {
    final modelId = state.stairModelId;
    if (modelId == null) {
      return state.outcome = const MapSlopeOutcome(
        problem: MapSlopeProblem.noStairModel,
      );
    }
    return state.outcome = _apply(
      document.current,
      () => placeTerrainStair(
        manifest: project,
        map: document.current,
        cell: cell,
        modelId: modelId,
      ).slope,
    );
  }

  MapSlopeOutcome _apply(MapData source, TerrainSlopePaint Function() edit) {
    if (document.saving || !identical(source, document.current)) {
      return const MapSlopeOutcome(problem: MapSlopeProblem.busy);
    }
    final TerrainSlopePaint result;
    try {
      result = edit();
    } on ValidationException catch (failure) {
      return MapSlopeOutcome(problem: mapSlopeProblem(failure));
    }
    final before = document.current;
    document.commit(result.map);
    return MapSlopeOutcome(
      cutCliffs: result.traces.length,
      mound: _withoutPlateau(before, result.plan),
    );
  }
}

bool _withoutPlateau(MapData map, TerrainSlopePlan plan) {
  final scene = map.spatialScene!;
  return plan.highSide
      .where(
        (cell) =>
            cell.x >= 0 &&
            cell.y >= 0 &&
            cell.x < scene.width &&
            cell.y < scene.depth,
      )
      .every(
        (cell) =>
            (scene.worldHeightAt(cell.x + .5, cell.y + .5) - plan.upperHeight)
                .abs() >
            1e-6,
      );
}

TerrainSlopePlan? mapSlopePreview(MapData map, GridPos from, GridPos to) {
  try {
    return planTerrainSlope(map, from, to);
  } on ValidationException {
    return null;
  }
}

TerrainSlopePlan? mapStairPreview(
  ProjectManifest project,
  MapData map,
  GridPos cell,
  String? modelId,
) {
  if (modelId == null) return null;
  try {
    return planTerrainStair(
      map,
      cell,
      terrainStairModel(project, map, modelId),
    );
  } on ValidationException {
    return null;
  }
}

import 'package:map_core/map_core_domain.dart';

enum MapSlopeProblem {
  busy,
  outside,
  directionAmbiguous,
  downhill,
  groundNotFlat,
  noCliff,
  handPlacedCliff,
  edgeAmbiguous,
  heightMismatch,
  noRoom,
  noStairModel,
  stairModelUnavailable,
  rampConflict,
  surfaceLimit,
  cliffRefused,
  unknown,
}

final class MapSlopeOutcome {
  const MapSlopeOutcome({
    this.problem,
    this.cutCliffs = 0,
    this.mound = false,
  });
  final MapSlopeProblem? problem;
  final int cutCliffs;
  final bool mound;
}

final class MapSlopeToolState {
  String? stairModelId;
  MapSlopeOutcome? outcome;
  bool loading = false;
  Object? loadFailure;
  (ProjectManifest, String)? _candidatesKey;
  List<TerrainStairModel> _candidates = const [];

  List<TerrainStairModel> stairModels(ProjectManifest project, MapData map) {
    final key = _candidatesKey;
    if (key == null || !identical(key.$1, project) || key.$2 != map.id) {
      _candidatesKey = (project, map.id);
      _candidates = terrainStairCandidates(project, map);
    }
    return _candidates;
  }
}

MapSlopeProblem mapSlopeProblem(Object failure) => switch (failure) {
  ValidationException(:final code) => switch (code) {
    'spatial.slope.cells_invalid' ||
    'spatial.stair.cells_invalid' => MapSlopeProblem.outside,
    'spatial.slope.direction_ambiguous' => MapSlopeProblem.directionAmbiguous,
    'spatial.slope.downhill' => MapSlopeProblem.downhill,
    'spatial.slope.ground_not_flat' => MapSlopeProblem.groundNotFlat,
    'spatial.stair.no_cliff' => MapSlopeProblem.noCliff,
    'spatial.stair.edge_ambiguous' => MapSlopeProblem.edgeAmbiguous,
    'spatial.stair.height_mismatch' => MapSlopeProblem.heightMismatch,
    'spatial.stair.no_room' => MapSlopeProblem.noRoom,
    'spatial.stair.model_unavailable' => MapSlopeProblem.stairModelUnavailable,
    'spatial.terrain.paint.ramp_conflict' => MapSlopeProblem.rampConflict,
    'spatial.terrain.paint.surface_limit' => MapSlopeProblem.surfaceLimit,
    'spatial.relief.trace_refused' ||
    'spatial.relief.step_ambiguous' ||
    'spatial.relief.profile_incompatible' => MapSlopeProblem.cliffRefused,
    _ => MapSlopeProblem.unknown,
  },
  _ => MapSlopeProblem.unknown,
};

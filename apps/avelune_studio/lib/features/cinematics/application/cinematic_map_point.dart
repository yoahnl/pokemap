import 'cinematic_workspace_controller.dart';

enum CinematicMapMode { select, pan, destination, placement, path }

const cinematicMapPointOutsideError = 'Choisissez une case dans la carte.';

typedef CinematicMapPointOutcome = ({CinematicMapMode mode, String? error});

extension CinematicWorkspaceMapPoint on CinematicWorkspaceController {
  CinematicMapPointOutcome? applyMapPoint({
    required CinematicMapMode mode,
    required String? stepId,
    required String? actorId,
    required double x,
    required double y,
    required int width,
    required int height,
  }) {
    if (mode == CinematicMapMode.select || mode == CinematicMapMode.pan) {
      return null;
    }
    if (x < 0 || y < 0 || x >= width || y >= height) {
      return (mode: mode, error: cinematicMapPointOutsideError);
    }
    if (mode == CinematicMapMode.destination && stepId != null) {
      final placed = setDestination(stepId, x, y, width: width, height: height);
      return (mode: placed ? CinematicMapMode.select : mode, error: null);
    }
    if (mode == CinematicMapMode.placement && actorId != null) {
      final placed = placeActorAt(actorId, x, y, width: width, height: height);
      return (mode: placed ? CinematicMapMode.select : mode, error: null);
    }
    if (mode == CinematicMapMode.path && stepId != null) {
      appendWaypoint(stepId, x, y, width: width, height: height);
    }
    return (mode: mode, error: null);
  }
}

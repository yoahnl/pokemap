import 'package:map_core/map_core_domain.dart';

bool cinematicPlacementChoiceIsStaged(String kind) =>
    kind == CinematicActorInitialPlacementKind.fromMovementTarget.name ||
    kind == CinematicActorInitialPlacementKind.stagePoint.name;

CinematicActorInitialPlacement cinematicPlacementForKind(
  String actorId,
  String kind,
  CinematicActorInitialPlacement? current,
) {
  final placementKind = CinematicActorInitialPlacementKind.values.byName(kind);
  return CinematicActorInitialPlacement(
    actorId: actorId,
    kind: placementKind,
    targetId:
        placementKind == CinematicActorInitialPlacementKind.fromMovementTarget
        ? current?.targetId
        : null,
    stagePointId: placementKind == CinematicActorInitialPlacementKind.stagePoint
        ? current?.stagePointId
        : null,
  );
}

CinematicActorBinding cinematicBindingForRole(
  String actorId,
  String kind,
  CinematicActorBinding? current,
) {
  final bindingKind = CinematicActorBindingKind.values.byName(kind);
  return CinematicActorBinding(
    actorId: actorId,
    kind: bindingKind,
    mapEntityId: bindingKind == CinematicActorBindingKind.mapEntity
        ? current?.mapEntityId
        : null,
  );
}

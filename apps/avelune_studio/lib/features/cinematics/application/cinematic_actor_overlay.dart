import 'package:map_core/map_core_domain.dart';

EntityFacing cinematicActorFacing(CinematicActorPreviewDirection direction) =>
    EntityFacing.values.where((f) => f.name == direction.name).firstOrNull ??
    EntityFacing.south;

CharacterCustomAnimationClip? cinematicActorCustomClip(
  ProjectCharacterEntry? character,
  CharacterCustomAnimationRuntimeCommand? command,
  EntityFacing facing,
) => character?.customAnimations
    .where(
      (a) =>
          a.definitionId == command?.definitionId &&
          (a.direction == null ||
              a.direction == (command?.direction ?? facing)),
    )
    .firstOrNull;

double cinematicActorLiftedRow(double y, double liftCells) => y - liftCells;

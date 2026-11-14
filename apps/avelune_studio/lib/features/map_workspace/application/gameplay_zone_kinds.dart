import 'package:map_core/map_core_domain.dart';

String defaultZoneName(GameplayZoneKind kind) => switch (kind) {
  GameplayZoneKind.encounter => 'Zone de rencontres',
  GameplayZoneKind.movement => 'Zone de déplacement',
  GameplayZoneKind.movementEffect => 'Zone à effet',
  GameplayZoneKind.fieldAction => 'Action de terrain',
  GameplayZoneKind.hazard => 'Zone dangereuse',
  GameplayZoneKind.special => 'Zone spéciale',
  GameplayZoneKind.custom => 'Zone héritée',
};

const studioGameplayZoneKinds = [
  GameplayZoneKind.encounter,
  GameplayZoneKind.movement,
  GameplayZoneKind.movementEffect,
  GameplayZoneKind.fieldAction,
  GameplayZoneKind.hazard,
  GameplayZoneKind.special,
];

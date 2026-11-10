import 'package:map_core/map_core_domain.dart';

String fieldAbilitySupport(
  ProjectFieldAbilityEntry ability,
  ProjectDimension dimension,
) => ability.activationOnly
    ? 'Activation seule'
    : dimension == ProjectDimension.twoD || ability.id == 'surf'
    ? 'Mécanique disponible'
    : 'Non certifiée en 3D';

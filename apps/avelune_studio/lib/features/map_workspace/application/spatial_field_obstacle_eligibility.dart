import 'package:map_core/map_core_domain.dart';

String? spatialFieldObstacleRefusal(
  SpatialModelInstance instance,
  ProjectModel3dEntry? model,
  MapEntity? bound,
) {
  if (model == null) {
    return 'La ressource de ce décor est introuvable : il ne peut pas devenir un obstacle.';
  }
  if (!instance.blocksMovement) {
    return 'Activez la collision du décor : un obstacle Coupe, Force ou Éclate-Roc bloque le passage.';
  }
  if (instance.animationIndex != null ||
      instance.clip != null ||
      model.inspection.animations.isNotEmpty) {
    return 'Les obstacles Coupe, Force et Éclate-Roc n’acceptent que des décors sans animation.';
  }
  if (model.rampProfile != null) {
    return 'Une rampe sert à la traversée du joueur : elle ne peut pas devenir un obstacle.';
  }
  if (instance.entityId != null && bound?.kind != MapEntityKind.custom) {
    return 'Ce décor porte déjà un autre élément du jeu : retirez ce lien pour en faire un obstacle.';
  }
  return null;
}

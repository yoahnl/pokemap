import 'package:map_core/map_core.dart';

import 'direction.dart';

sealed class GameplayIntent {
  const GameplayIntent();
}

/// Intention de déplacement : delta **pixels** le long d’un axe cardinal
/// ([pixelsPerStep]), pas une case cible.
final class MoveIntent extends GameplayIntent {
  const MoveIntent(
    this.direction, {
    this.pixelsPerStep = PlayerCollisionConventionsV1.defaultMoveStepPixels,
  });

  final Direction direction;

  /// Nombre de pixels essayés sur l’axe du mouvement (séparé H/V dans le résolveur).
  final int pixelsPerStep;
}

final class InteractIntent extends GameplayIntent {
  const InteractIntent();
}

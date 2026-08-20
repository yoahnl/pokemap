import 'package:map_core/map_core.dart';

import 'field_action.dart';

/// Spécialisation Surf du contrat d'action terrain.
///
/// BETA-SYS-002 a extrait le contrat commun dans `field_action.dart`. Ce fichier
/// reste l'entrée nommée pour Surf, seule capacité signée pour la bêta, et
/// délègue : il n'y a donc qu'UN endroit où le verdict se décide, ce qui est ce
/// qui rend la parité preview/runtime structurelle plutôt que vérifiée.
typedef SurfAttemptEvaluation = FieldActionEvaluation;

/// Évalue si le joueur peut utiliser Surf sur une cellule cible.
FieldActionEvaluation evaluateSurfAttempt({
  required GameState gameState,
  required bool isTargetWater,
}) {
  return evaluateFieldAction(
    ability: FieldAbility.surf,
    gameState: gameState,
    isTargetWater: isTargetWater,
  );
}

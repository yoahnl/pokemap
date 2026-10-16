import 'package:map_gameplay/map_gameplay.dart';

const String waterRequiresSurfFeedbackMessage =
    'On ne peut pas aller sur l’eau sans un Pokémon ayant Surf.';

String? runtimeMovementBlockedMessage(
  GameplayMovementBlockReason reason,
) {
  switch (reason) {
    case GameplayMovementBlockReason.waterRequiresSurf:
      return waterRequiresSurfFeedbackMessage;
    case GameplayMovementBlockReason.underwaterRequiresDive:
      return 'Ce terrain sous-marin nécessite Plongée.';
    case GameplayMovementBlockReason.diveRequiresUnderwater:
      return 'La plongée est réservée au terrain sous-marin.';
    case GameplayMovementBlockReason.invalidMovementTerrain:
      return 'Ce terrain comporte des modes de déplacement incompatibles.';
    case GameplayMovementBlockReason.solid:
    case GameplayMovementBlockReason.outOfBounds:
      return null;
  }
}

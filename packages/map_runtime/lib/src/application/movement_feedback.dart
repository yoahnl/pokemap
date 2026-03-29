import 'package:map_gameplay/map_gameplay.dart';

const String waterRequiresSurfFeedbackMessage =
    'On ne peut pas aller sur l’eau sans un Pokémon ayant Surf.';

String? runtimeMovementBlockedMessage(
  GameplayMovementBlockReason reason,
) {
  switch (reason) {
    case GameplayMovementBlockReason.waterRequiresSurf:
      return waterRequiresSurfFeedbackMessage;
    case GameplayMovementBlockReason.solid:
    case GameplayMovementBlockReason.outOfBounds:
      return null;
  }
}

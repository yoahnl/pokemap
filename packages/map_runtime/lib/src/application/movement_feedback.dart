import 'package:map_gameplay/map_gameplay.dart';

import '../player/runtime_player_feedback.dart';

const String waterRequiresSurfFeedbackMessage =
    'On ne peut pas aller sur l’eau sans un Pokémon ayant Surf.';

String? runtimeMovementBlockedMessage(
  GameplayMovementBlockReason reason, {
  String uiLocale = 'fr',
  RuntimePlayerFeedbackLocalizer? localizer,
}) {
  final RuntimeOverworldFeedback? feedback = switch (reason) {
    .waterRequiresSurf => .waterRequiresSurf,
    .underwaterRequiresDive => .underwaterRequiresDive,
    .diveRequiresUnderwater => .diveRequiresUnderwater,
    .invalidMovementTerrain => .incompatibleMovementTerrain,
    .solid || .outOfBounds => null,
  };
  return feedback?.resolve(localizer, uiLocale);
}

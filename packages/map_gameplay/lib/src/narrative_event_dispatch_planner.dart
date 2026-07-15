import 'package:map_core/map_core.dart';

final class NarrativeEventDispatchPlanner {
  NarrativeEventDispatchDecision plan({
    required NarrativeEventDispatchAuthorityReady authority,
    required GameState gameState,
    Set<String> inFlightNarrativeEventIds = const <String>{},
  }) {
    return authority.plan(
      gameState: gameState,
      inFlightNarrativeEventIds:
          Set<String>.unmodifiable(inFlightNarrativeEventIds),
    );
  }
}

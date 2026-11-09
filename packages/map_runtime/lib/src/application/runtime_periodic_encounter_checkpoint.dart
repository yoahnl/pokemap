import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

PeriodicEncounterOutcome? periodicEncounterOutcome(BattleOutcome outcome) =>
    switch (outcome.type) {
      BattleOutcomeType.victory => PeriodicEncounterOutcome.victory,
      BattleOutcomeType.captured => PeriodicEncounterOutcome.captured,
      BattleOutcomeType.runaway => PeriodicEncounterOutcome.fled,
      BattleOutcomeType.defeat => null,
    };

Future<GameState> checkpointRuntimePeriodicEncounter({
  required NarrativeEventStateCheckpointOwner owner,
  required PeriodicEncounterOccurrence occurrence,
  required GameState finalState,
  required BattleOutcome outcome,
  required GameState Function() readFinalSceneState,
  required Future<void> Function(GameState) persist,
}) async {
  final durable = completePeriodicEncounter(
    finalState,
    occurrence: occurrence,
    outcome: periodicEncounterOutcome(outcome),
  );
  await owner.checkpoint(
    expectedBase: owner.committedState,
    durableState: durable,
    persist: persist,
    rebase: (candidate) {
      final expected = readFinalSceneState();
      if (candidate.copyWith(
            narrativeEventProgress: expected.narrativeEventProgress,
          ) !=
          expected) {
        throw StateError('The Scene returned a stale periodic battle result.');
      }
      return candidate;
    },
  );
  return durable;
}

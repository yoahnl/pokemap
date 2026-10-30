import 'package:map_core/map_core.dart';

import 'narrative_event_state_transactions.dart';

bool samePeriodicRewardCheckpointFields(GameState first, GameState second) =>
    first.saveId == second.saveId &&
    first.bag == second.bag &&
    first.gameplayCalendarState == second.gameplayCalendarState &&
    first.periodicRewardState == second.periodicRewardState;

GameState _project(GameState base, GameState delta) => base.copyWith(
    bag: delta.bag,
    gameplayCalendarState: delta.gameplayCalendarState,
    periodicRewardState: delta.periodicRewardState);

Future<GameState> checkpointPeriodicReward({
  required NarrativeEventStateCheckpointOwner owner,
  required GameState currentDraft,
  required GameState nextDraft,
  required Future<void> Function(GameState) persist,
}) async {
  final base = owner.committedState;
  if (!samePeriodicRewardCheckpointFields(base, currentDraft) ||
      nextDraft.saveId != base.saveId) {
    throw StateError(
        'Pending Scene inventory or reward changes must finish before this checkpoint.');
  }
  nextDraft.periodicRewardState
      .validateCalendar(nextDraft.gameplayCalendarState);
  final durable = _project(base, nextDraft);
  await owner.checkpoint(
    expectedBase: base,
    durableState: durable,
    persist: persist,
    rebase: (candidate) {
      if (samePeriodicRewardCheckpointFields(candidate, base)) {
        return _project(candidate, durable);
      }
      if (samePeriodicRewardCheckpointFields(candidate, durable) ||
          samePeriodicRewardCheckpointFields(
              candidate, owner.latestCheckpointState)) {
        return candidate;
      }
      throw StateError(
          'The Scene returned uncheckpointed inventory or periodic reward state.');
    },
  );
  return _project(currentDraft, durable);
}

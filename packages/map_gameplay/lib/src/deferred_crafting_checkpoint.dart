import 'package:map_core/map_core.dart';
import 'narrative_event_state_transactions.dart';

bool sameDeferredCraftingCheckpointFields(GameState first, GameState second) =>
    first.saveId == second.saveId &&
    first.bag == second.bag &&
    first.gameplayCalendarState == second.gameplayCalendarState &&
    first.deferredCraftingState == second.deferredCraftingState;

GameState _project(GameState base, GameState delta) => base.copyWith(
    bag: delta.bag,
    gameplayCalendarState: delta.gameplayCalendarState,
    deferredCraftingState: delta.deferredCraftingState);

Future<GameState> checkpointDeferredCrafting(
    {required NarrativeEventStateCheckpointOwner owner,
    required GameState currentDraft,
    required GameState nextDraft,
    required Future<void> Function(GameState) persist}) async {
  final base = owner.committedState;
  if (!sameDeferredCraftingCheckpointFields(base, currentDraft) ||
      nextDraft.saveId != base.saveId) {
    throw StateError(
        'Pending Scene inventory or crafting changes must finish before this checkpoint.');
  }
  final durable = _project(base, nextDraft);
  await owner.checkpoint(
      expectedBase: base,
      durableState: durable,
      persist: persist,
      rebase: (candidate) {
        if (sameDeferredCraftingCheckpointFields(candidate, base)) {
          return _project(candidate, durable);
        }
        if (candidate.saveId != durable.saveId ||
            candidate.gameplayCalendarState.dayRevision <
                durable.gameplayCalendarState.dayRevision ||
            durable.deferredCraftingState.servicesById.entries.any((entry) {
              final actual =
                  candidate.deferredCraftingState.serviceFor(entry.key);
              return actual.revision < entry.value.revision ||
                  actual.revision == entry.value.revision &&
                      actual != entry.value;
            }) ||
            candidate.gameplayCalendarState != durable.gameplayCalendarState &&
                !candidate.deferredCraftingState.servicesById.entries.any(
                    (entry) =>
                        entry.value.revision >
                        durable.deferredCraftingState
                            .serviceFor(entry.key)
                            .revision)) {
          throw StateError('The Scene returned stale durable crafting state.');
        }
        return candidate;
      });
  return _project(currentDraft, durable);
}

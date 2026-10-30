import 'package:map_core/map_core.dart';
import 'narrative_event_state_transactions.dart';

bool sameImagePuzzleCheckpointFields(GameState first, GameState second) =>
    first.saveId == second.saveId &&
    first.imagePuzzleState == second.imagePuzzleState;

Future<GameState> checkpointImagePuzzle({
  required NarrativeEventStateCheckpointOwner owner,
  required GameState currentDraft,
  required GameState nextDraft,
  required Future<void> Function(GameState) persist,
}) async {
  final base = owner.committedState;
  if (!sameImagePuzzleCheckpointFields(base, currentDraft) ||
      nextDraft.saveId != base.saveId) {
    throw StateError(
        'Pending Scene puzzle changes must finish before this checkpoint.');
  }
  final durable = base.copyWith(imagePuzzleState: nextDraft.imagePuzzleState);
  await owner.checkpoint(
      expectedBase: base,
      durableState: durable,
      persist: persist,
      rebase: (candidate) {
        if (sameImagePuzzleCheckpointFields(candidate, base)) {
          return candidate.copyWith(imagePuzzleState: durable.imagePuzzleState);
        }
        if (sameImagePuzzleCheckpointFields(candidate, durable) ||
            sameImagePuzzleCheckpointFields(
                candidate, owner.latestCheckpointState)) {
          return candidate;
        }
        throw StateError('The Scene returned uncommitted image puzzle state.');
      });
  return currentDraft.copyWith(imagePuzzleState: durable.imagePuzzleState);
}
